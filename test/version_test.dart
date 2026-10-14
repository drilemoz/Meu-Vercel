import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:meu_vercel/core/version.dart';

void main() {
  test('versão Flutter, Android e documentação seguem os metadados', () {
    final meta = jsonDecode(File('version.json').readAsStringSync()) as Map<String, dynamic>;
    expect(meta['versionName'], appVersion); expect(meta['versionCode'], appVersionCode); expect(meta['applicationId'], applicationId);
    expect(File('pubspec.yaml').readAsStringSync(), contains('version: $appVersion+$appVersionCode'));
    expect(File('android/version.properties').readAsStringSync(), contains('versionCode=$appVersionCode'));
    expect(File('android/version.properties').readAsStringSync(), contains('versionName=$appVersion'));
    for (final path in ['README.md', 'CHANGELOG.md', 'RELEASE_NOTES.md', 'docs/VERSIONING.md']) {
      expect(File(path).readAsStringSync(), contains(appVersion), reason: path);
    }
    expect(releaseHighlights, isNotEmpty);
  });
}
