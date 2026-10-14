import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meu_vercel/core/backup.dart';
import 'package:meu_vercel/core/storage.dart';

void main() {
  final codec = BackupCodec();
  test('backup restaura preferências e favoritos sem sessão', () {
    const prefs = Preferences(theme: 'amoled', autoSync: false, favorites: {'user_fixture:personal': ['prj_fixture']});
    final data = codec.encode(prefs, now: DateTime.utc(2026)); final restored = codec.decode(data);
    expect(restored.theme, 'amoled'); expect(restored.autoSync, false);
    expect(restored.favorites['user_fixture:personal'], ['prj_fixture']);
    expect(data.contains('vercel_token'), false); expect(data.contains('deployments'), false);
  });
  test('integridade detecta alteração do payload', () {
    final envelope = jsonDecode(codec.encode(const Preferences())) as Map<String, dynamic>;
    envelope['payload']['preferences']['theme'] = 'amoled';
    expect(() => codec.decode(jsonEncode(envelope)), throwsFormatException);
  });
  test('campos secretos são rejeitados mesmo com checksum válido', () {
    final envelope = jsonDecode(codec.encode(const Preferences())) as Map<String, dynamic>;
    envelope['payload']['preferences']['token'] = '<PLACEHOLDER_NOT_ALLOWED>';
    envelope['sha256'] = sha256.convert(utf8.encode(jsonEncode(canonical(envelope['payload'])))).toString();
    expect(() => codec.decode(jsonEncode(envelope)), throwsFormatException);
  });
  test('formato futuro é recusado sem substituir dados', () {
    final envelope = jsonDecode(codec.encode(const Preferences())) as Map<String, dynamic>;
    envelope['payload']['version'] = 999;
    expect(() => codec.decode(jsonEncode(envelope)), throwsFormatException);
  });
  test('formato v1 anterior sem preferências opcionais recebe defaults', () {
    final envelope = jsonDecode(codec.encode(const Preferences())) as Map<String, dynamic>;
    envelope['payload']['preferences'] = {'theme': 'light', 'favorites': {}};
    envelope['sha256'] = sha256.convert(utf8.encode(jsonEncode(canonical(envelope['payload'])))).toString();
    final restored = codec.decode(jsonEncode(envelope)); expect(restored.autoSync, true); expect(restored.notifyFailure, false);
  });
  test('JSON inválido e arquivo excessivo são recusados', () {
    expect(() => codec.decode('{'), throwsFormatException);
    expect(() => codec.decode('x' * (1024 * 1024 + 1)), throwsFormatException);
  });
}
