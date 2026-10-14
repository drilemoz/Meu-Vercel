import 'package:flutter/services.dart';
import 'errors.dart';
import 'static_deploy.dart';

/// Android Storage Access Framework: the user explicitly grants a tree for this
/// session; native code enumerates and streams *only* files from that selection.
class AndroidSiteFolder {
  static const _channel = MethodChannel('app.meuvercel.android/site_folder');

  static Future<List<SiteFile>?> pick() async {
    try {
      final listed = await _channel.invokeListMethod<dynamic>('pickFolder');
      if (listed == null) return null;
      if (listed.isEmpty || listed.length > StaticSite.maxFiles) {
        throw const ApiFailure(FailureKind.invalid, 'Pasta vazia ou com mais de 120 arquivos.');
      }
      final entries = <({String path, String uri})>[];
      final used = <String>{};
      var indicatedTotal = 0;
      for (final entry in listed) {
        if (entry is! Map) {
          throw const ApiFailure(FailureKind.invalid, 'Lista de arquivos inválida.');
        }
        final path = entry['path'];
        final uri = entry['uri'];
        final size = entry['size'];
        if (path is! String || uri is! String || size is! int || size < -1) {
          throw const ApiFailure(FailureKind.invalid, 'Pasta contém dados de arquivo inválidos.');
        }
        StaticSite.checkPath(path);
        if (!used.add(path.toLowerCase())) {
          throw const ApiFailure(FailureKind.invalid, 'Pasta contém nomes duplicados.');
        }
        if (size >= 0 && size > StaticSite.maxSiteBytes - indicatedTotal) {
          throw const ApiFailure(FailureKind.invalid, 'Conteúdo da pasta ultrapassa 20 MiB.');
        }
        if (size >= 0) indicatedTotal += size;
        entries.add((path: path, uri: uri));
      }
      if (!used.contains('index.html')) {
        throw const ApiFailure(FailureKind.invalid, 'A pasta deve ter index.html na raiz.');
      }
      final sources = <SiteSource>[];
      var readTotal = 0;
      for (final entry in entries) {
        final bytes = await _channel.invokeMethod<Uint8List>('readFile', entry.uri);
        if (bytes == null) {
          throw const ApiFailure(FailureKind.invalid, 'Não foi possível ler arquivo da pasta.');
        }
        if (bytes.length > StaticSite.maxSiteBytes - readTotal) {
          throw const ApiFailure(FailureKind.invalid, 'Conteúdo lido ultrapassa 20 MiB.');
        }
        readTotal += bytes.length;
        sources.add((path: entry.path, bytes: bytes));
      }
      return StaticSite.prepare(sources);
    } on PlatformException {
      throw const ApiFailure(FailureKind.invalid,
        'Não foi possível acessar a pasta selecionada. Tente outra pasta no Android.');
    } on MissingPluginException {
      throw const ApiFailure(FailureKind.invalid, 'Seleção de pasta disponível apenas no aplicativo Android.');
    }
  }
}
