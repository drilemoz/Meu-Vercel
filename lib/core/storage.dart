import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models.dart';

abstract interface class KeyValueStore {
  String? read(String key);
  Future<void> write(String key, String value);
  Future<void> remove(String key);
  Set<String> get keys;
}
class PreferencesStore implements KeyValueStore {
  PreferencesStore(this.preferences);
  final SharedPreferences preferences;
  @override String? read(String key) => preferences.getString(key);
  @override Future<void> write(String key, String value) async {
    if (!await preferences.setString(key, value)) throw const FormatException('Não foi possível salvar os dados locais.');
  }
  @override Future<void> remove(String key) async { await preferences.remove(key); }
  @override Set<String> get keys => preferences.getKeys();
}
abstract interface class TokenStore {
  Future<String?> read();
  Future<void> write(String token);
  Future<void> clear();
}
class SecureTokenStore implements TokenStore {
  final _storage = const FlutterSecureStorage(aOptions: AndroidOptions(encryptedSharedPreferences: true));
  @override Future<String?> read() => _storage.read(key: 'vercel_token');
  @override Future<void> write(String token) => _storage.write(key: 'vercel_token', value: token);
  @override Future<void> clear() => _storage.delete(key: 'vercel_token');
}
class Preferences {
  const Preferences({this.theme = 'light', this.autoSync = true,
    this.notifyFailure = false, this.notifySuccess = false, this.favorites = const {}});
  final String theme;
  final bool autoSync;
  final bool notifyFailure;
  final bool notifySuccess;
  final Map<String, List<String>> favorites;
  Json toJson() => {'theme': theme, 'autoSync': autoSync, 'notifyFailure': notifyFailure,
    'notifySuccess': notifySuccess, 'favorites': favorites};
  static Preferences parse(Json j) {
    const allowed = {'theme', 'autoSync', 'notifyFailure', 'notifySuccess', 'favorites'};
    if (j.keys.any((k) => !allowed.contains(k))) throw const FormatException('Backup contém campos não permitidos.');
    final theme = j['theme'] ?? 'light';
    if (!['system', 'light', 'amoled'].contains(theme)) throw const FormatException('Tema inválido.');
    for (final key in ['autoSync', 'notifyFailure', 'notifySuccess']) {
      if (j[key] != null && j[key] is! bool) throw const FormatException('Preferência inválida.');
    }
    final favorites = <String, List<String>>{};
    final raw = j['favorites'] ?? <String, dynamic>{};
    if (raw is! Map || raw.length > 500) throw const FormatException('Favoritos inválidos.');
    for (final entry in raw.entries) {
      if (entry.key is! String || (entry.key as String).length > 200 || entry.value is! List) {
        throw const FormatException('Favoritos inválidos.');
      }
      final list = entry.value as List;
      if (list.length > 10000 || list.any((v) => v is! String || v.isEmpty || v.length > 200)) {
        throw const FormatException('Favoritos inválidos.');
      }
      favorites[entry.key as String] = list.cast<String>().toSet().toList();
    }
    return Preferences(theme: theme as String, autoSync: j['autoSync'] as bool? ?? true,
      notifyFailure: j['notifyFailure'] as bool? ?? false, notifySuccess: j['notifySuccess'] as bool? ?? false,
      favorites: favorites);
  }
  Preferences copyWith({String? theme, bool? autoSync, bool? notifyFailure,
    bool? notifySuccess, Map<String, List<String>>? favorites}) => Preferences(theme: theme ?? this.theme,
      autoSync: autoSync ?? this.autoSync, notifyFailure: notifyFailure ?? this.notifyFailure,
      notifySuccess: notifySuccess ?? this.notifySuccess, favorites: favorites ?? this.favorites);
}
class Snapshot {
  const Snapshot({required this.account, required this.teams, required this.projects,
    required this.deployments, required this.syncedAt, this.projectCursor, this.deployCursor});
  final Account account;
  final List<Team> teams;
  final List<Project> projects;
  final List<Deployment> deployments;
  final DateTime syncedAt;
  final String? projectCursor;
  final String? deployCursor;
  Json toJson() => {'schema': 1, 'account': account.toJson(), 'teams': teams.map((t) => t.toJson()).toList(),
    'projects': projects.map((p) => p.toJson()).toList(), 'deployments': deployments.map((d) => d.toJson()).toList(),
    'syncedAt': syncedAt.toIso8601String(), 'projectCursor': projectCursor, 'deployCursor': deployCursor};
  static Snapshot parse(Json j) {
    if (j['schema'] != 1 || date(j['syncedAt']) == null) throw const FormatException('Cache incompatível.');
    return Snapshot(account: Account.fromJson(object(j['account'])), teams: objects(j['teams']).map(Team.fromJson).toList(),
      projects: objects(j['projects']).map(Project.fromJson).toList(),
      deployments: objects(j['deployments']).map(Deployment.fromJson).toList(), syncedAt: date(j['syncedAt'])!,
      projectCursor: optionalString(j['projectCursor']), deployCursor: optionalString(j['deployCursor']));
  }
}
class LocalData {
  LocalData(this.store);
  final KeyValueStore store;
  Preferences preferences() {
    try { return Preferences.parse(object(jsonDecode(store.read('preferences.v1') ?? '{}'))); }
    catch (_) { return const Preferences(); }
  }
  Future<void> savePreferences(Preferences prefs) => store.write('preferences.v1', jsonEncode(prefs.toJson()));
  String scope(String account, String? team) => '$account:${team ?? 'personal'}';
  Future<void> saveCache(String scope, Snapshot data) async {
    // Only the typed, explicitly projected snapshot is persisted. No raw API data.
    final encoded = jsonEncode(data.toJson());
    if (utf8.encode(encoded).length <= 4 * 1024 * 1024) await store.write('cache.v1.$scope', encoded);
  }
  Snapshot? cache(String scope) {
    try { return Snapshot.parse(object(jsonDecode(store.read('cache.v1.$scope') ?? 'null'))); }
    catch (_) { return null; }
  }
  Future<void> clearSessionCache() async {
    for (final key in store.keys.where((k) => k.startsWith('cache.') || k == 'session.v1').toList()) {
      await store.remove(key);
    }
  }
  Json? session() {
    try { return object(jsonDecode(store.read('session.v1') ?? 'null')); } catch (_) { return null; }
  }
  Future<void> saveSession(String account, String? team) => store.write('session.v1', jsonEncode({'account': account, 'team': team}));
}
