import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'errors.dart';

typedef SiteFile = ({String path, Uint8List bytes, String sha});
typedef SiteSource = ({String path, Uint8List bytes});

/// Shared safety rules for ZIP, multiple files and Android SAF directory trees.
/// The content remains in memory and is never extracted into public storage.
class StaticSite {
  static const maxSiteBytes = 20 * 1024 * 1024;
  static const maxFiles = 120;

  static void checkPath(String path) {
    final parts = path.split('/');
    final lowered = path.toLowerCase();
    if (path.isEmpty || path.length > 512 || path.startsWith('/') ||
        path.contains('\\') || path.contains(':') || path.contains('\u0000') ||
        parts.any((p) => p.isEmpty || p == '.' || p == '..') ||
        parts.any((p) => p.length > 180 || p.endsWith(' ') || p.endsWith('.')) ||
        parts.any((p) => ['.git', '.svn', '.hg', '.ssh', '.aws', '.vercel', '__macosx'].contains(p.toLowerCase())) ||
        parts.any((p) => p.toLowerCase() == '.env' || p.toLowerCase().startsWith('.env.')) ||
        RegExp(r'\.(jks|keystore|p12|pfx|pem|key)$', caseSensitive: false).hasMatch(path) ||
        ['.npmrc', '.netrc', 'credentials.json', 'service-account.json',
          'id_rsa', 'id_ed25519'].contains(parts.last.toLowerCase()) ||
        lowered.startsWith('android/')) {
      throw const ApiFailure(FailureKind.invalid,
        'Há arquivos sensíveis ou caminhos inválidos na seleção. Remova-os antes de publicar.');
    }
  }

  static List<SiteFile> prepare(Iterable<SiteSource> sources) {
    final results = <SiteFile>[];
    final used = <String>{};
    var total = 0;
    for (final source in sources) {
      final path = source.path;
      checkPath(path);
      if (!used.add(path.toLowerCase())) {
        throw const ApiFailure(FailureKind.invalid, 'Arquivos duplicados na seleção.');
      }
      if (results.length >= maxFiles) {
        throw const ApiFailure(FailureKind.invalid, 'Selecione no máximo 120 arquivos.');
      }
      final bytes = source.bytes;
      if (bytes.length > maxSiteBytes - total) {
        throw const ApiFailure(FailureKind.invalid, 'O site ultrapassa 20 MiB.');
      }
      total += bytes.length;
      results.add((path: path, bytes: bytes, sha: sha1.convert(bytes).toString()));
    }
    if (!used.contains('index.html') || !results.any((f) => f.path == 'index.html')) {
      throw const ApiFailure(FailureKind.invalid, 'É necessário index.html na raiz do site.');
    }
    return results;
  }

  /// Check again immediately before sending anything over the network.
  static void validate(List<SiteFile> files) {
    final expected = prepare(files.map((f) => (path: f.path, bytes: f.bytes)));
    for (var i = 0; i < files.length; i++) {
      if (files[i].sha != expected[i].sha) {
        throw const ApiFailure(FailureKind.invalid, 'Checksum de arquivo inválido.');
      }
    }
  }
}

/// All paths stay virtual: untrusted ZIP entries never touch Android storage.
class StaticZip {
  static const maxZipBytes = 12 * 1024 * 1024;
  static const maxSiteBytes = StaticSite.maxSiteBytes;
  static const maxFiles = StaticSite.maxFiles;

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
      final paths = <String>[];
      var total = 0;
      final seen = <String>{};
      for (final entry in entries) {
        StaticSite.checkPath(entry.name);
        if (!seen.add(entry.name.toLowerCase())) {
          throw const ApiFailure(FailureKind.invalid, 'ZIP contém caminhos duplicados.');
        }
        if (entry.isSymbolicLink || (entry.unixPermissions & 0xF000) == 0xA000) {
          throw const ApiFailure(FailureKind.invalid, 'Links simbólicos não são permitidos.');
        }
        if (entry.size < 0 || entry.size > maxSiteBytes - total) {
          throw const ApiFailure(FailureKind.invalid, 'Conteúdo ZIP ultrapassa 20 MiB.');
        }
        total += entry.size;
        paths.add(entry.name);
      }
      var prefix = '';
      if (!paths.contains('index.html')) {
        final folders = paths.map((p) => p.split('/').first).toSet();
        if (folders.length == 1 && paths.contains('${folders.single}/index.html')) {
          prefix = '${folders.single}/';
        } else {
          throw const ApiFailure(FailureKind.invalid, 'ZIP precisa conter index.html na raiz.');
        }
      }
      final sources = <SiteSource>[];
      for (final entry in entries) {
        final bytes = entry.readBytes();
        if (bytes == null || bytes.length != entry.size) {
          throw const ApiFailure(FailureKind.invalid, 'Arquivo corrompido no ZIP.');
        }
        sources.add((path: entry.name.substring(prefix.length), bytes: bytes));
      }
      return StaticSite.prepare(sources);
    } on ApiFailure {
      rethrow;
    } catch (_) {
      throw const ApiFailure(FailureKind.invalid, 'ZIP inválido, criptografado ou corrompido.');
    }
  }
}
