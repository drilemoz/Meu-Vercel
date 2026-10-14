import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meu_vercel/core/android_site_folder.dart';
import 'package:meu_vercel/core/errors.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('app.meuvercel.android/site_folder');
  final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  test('pasta SAF preserva caminhos e aceita metadados sem tamanho', () async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'pickFolder') return [
        {'path': 'index.html', 'uri': 'content://site/1', 'size': -1},
        {'path': 'css/main.css', 'uri': 'content://site/2', 'size': 6},
      ];
      if (call.method == 'readFile') {
        return Uint8List.fromList(utf8.encode('teste!'));
      }
      return null;
    });
    final files = await AndroidSiteFolder.pick();
    expect(files?.map((f) => f.path).toList(), ['index.html', 'css/main.css']);
    expect(files?.first.sha.length, 40);
  });

  test('pasta SAF recusada antes de leitura se contém segredo', () async {
    var reads = 0;
    messenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'pickFolder') return [
        {'path': 'index.html', 'uri': 'content://site/1', 'size': 5},
        {'path': '.env', 'uri': 'content://site/2', 'size': 5},
      ];
      if (call.method == 'readFile') reads++;
      return null;
    });
    await expectLater(AndroidSiteFolder.pick(), throwsA(isA<ApiFailure>()));
    expect(reads, 0);
  });

  test('cancelar seletor de pastas não inicia upload', () async {
    messenger.setMockMethodCallHandler(channel, (_) async => null);
    expect(await AndroidSiteFolder.pick(), isNull);
  });
}
