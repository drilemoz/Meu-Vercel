import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'errors.dart';

typedef SiteFile = ({String path, Uint8List bytes, String sha});

/// Restrict extraction to small, static archives. All paths stay virtual:
/// untrusted ZIP entries are never extracted into the Android filesystem.
class StaticZip {
  static const maxZipBytes = 12 * 1024 * 1024;
  static const maxSiteBytes = 20 * 1024 * 1024;
  static const maxFiles = 120;

  static List<SiteFile> prepare(Uint8List zipBytes) {
    if (zipBytes.isEmpty || zipBytes.length > maxZipBytes) {
      throw const ApiFailure(FailureKind.invalid, 'ZIP vazio ou maior que 12 MiB.');
    }
    try {
      final archive = ZipDecoder().decodeBytes(zipBytes, verify: false);
      final entries = archive.where((entry) => entry.isFile).toList();
      if (entries.isEmpty || entries.length > maxFiles) {
        throw const ApiFailure(FailureKind.invalid, 'O ZIP precisa conter de 1 a 120 arquivos.');
      }
      var total = 0;
      final seen = <String>{};
      final paths = <String>[];
      for (final entry in entries) {
        final path = entry.name;
        final lowered = path.toLowerCase();
        final parts = path.split('/');
        if (path.isEmpty || path.startsWith('/') || path.contains('\u0000') ||
            path.contains('\\') || path.contains(':') || parts.any((p) => p.isEmpty || p == '.' || p == '..') ||
            parts.any((p) => ['.git', '.svn', '__macosx'].contains(p.toLowerCase())) ||
            parts.any((p) => p.toLowerCase() == '.env' || p.toLowerCase().startsWith('.env.')) ||
            RegExp(r'\.(jks|keystore|p12|pem|key)$', caseSensitive: false).hasMatch(path) ||
            !seen.add(lowered)) {
          throw const ApiFailure(FailureKind.invalid, 'ZIP contém caminhos duplicados, inválidos ou arquivos sensíveis.');
        }
        // Unix file type 0xA000 indicates a symbolic link.
        if (entry.isSymbolicLink || (entry.unixPermissions & 0xF000) == 0xA000) {
          throw const ApiFailure(FailureKind.invalid, 'Links simbólicos não são permitidos.');
        }
        if (entry.size < 0 || entry.size > maxSiteBytes || total + entry.size > maxSiteBytes) {
          throw const ApiFailure(FailureKind.invalid, 'Conteúdo do ZIP ultrapassa 20 MiB.');
        }
        total += entry.size;
        paths.add(path);
      }
      // Allow a single top-level wrapper directory, e.g. site/index.html.
      var prefix = '';
      if (!paths.contains('index.html')) {
        final folders = paths.map((p) => p.split('/').first).toSet();
        if (folders.length == 1 && paths.contains('${folders.single}/index.html')) {
          prefix = '${folders.single}/';
        } else {
          throw const ApiFailure(FailureKind.invalid, 'O ZIP precisa conter index.html na raiz do site.');
        }
      }
      final files = <SiteFile>[];
      for (final entry in entries) {
        final bytes = entry.readBytes();
        if (bytes == null || bytes.length != entry.size) {
          throw const ApiFailure(FailureKind.invalid, 'Arquivo corrompido no ZIP.');
        }
        final path = entry.name.substring(prefix.length);
        files.add((path: path, bytes: bytes, sha: sha1.convert(bytes).toString()));
      }
      return files;
    } on ApiFailure {
      rethrow;
    } catch (_) {
      throw const ApiFailure(FailureKind.invalid, 'ZIP inválido, criptografado ou corrompido.');
    }
  }
}
