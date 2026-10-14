import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'models.dart';
import 'storage.dart';

/// Canonical encoding makes the digest independent of JSON key order.
Object? canonical(Object? value) {
  if (value is Map) {
    final keys = value.keys.cast<String>().toList()..sort();
    return {for (final key in keys) key: canonical(value[key])};
  }
  if (value is List) return value.map(canonical).toList();
  return value;
}
class BackupCodec {
  static const formatVersion = 1;
  String encode(Preferences prefs, {DateTime? now}) {
    final payload = {'format': 'meu-vercel-backup', 'version': formatVersion,
      'createdAt': (now ?? DateTime.now()).toUtc().toIso8601String(), 'preferences': prefs.toJson()};
    return jsonEncode({'payload': payload, 'sha256': _digest(payload)});
  }
  Preferences decode(String source) {
    if (utf8.encode(source).length > 1024 * 1024) throw const FormatException('Backup excede o limite de 1 MB.');
    try {
      final envelope = object(jsonDecode(source));
      if (envelope.keys.toSet().difference({'payload', 'sha256'}).isNotEmpty) throw const FormatException('Envelope inválido.');
      final payload = object(envelope['payload']);
      if (payload.keys.toSet().difference({'format', 'version', 'createdAt', 'preferences'}).isNotEmpty) {
        throw const FormatException('Campos não permitidos no backup.');
      }
      if (payload['format'] != 'meu-vercel-backup' || payload['version'] != formatVersion) {
        throw const FormatException('Versão de backup não suportada.');
      }
      if (date(payload['createdAt']) == null || envelope['sha256'] != _digest(payload)) {
        throw const FormatException('Backup corrompido: integridade inválida.');
      }
      return Preferences.parse(object(payload['preferences']));
    } on FormatException { rethrow; }
    catch (_) { throw const FormatException('Arquivo de backup inválido.'); }
  }
  String _digest(Json payload) => sha256.convert(utf8.encode(jsonEncode(canonical(payload)))).toString();
}
