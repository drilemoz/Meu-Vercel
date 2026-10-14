import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:meu_vercel/core/api.dart';
import 'package:meu_vercel/core/models.dart';
import 'package:meu_vercel/core/notifications.dart';
import 'package:meu_vercel/core/storage.dart';

class MemoryStore implements KeyValueStore {
  final values = <String, String>{};
  @override String? read(String key) => values[key];
  @override Future<void> write(String key, String value) async { values[key] = value; }
  @override Future<void> remove(String key) async { values.remove(key); }
  @override Set<String> get keys => values.keys.toSet();
}
class MemoryTokens implements TokenStore {
  String? value;
  int writes = 0;
  @override Future<String?> read() async => value;
  @override Future<void> write(String token) async { value = token; writes++; }
  @override Future<void> clear() async { value = null; }
}
class NoAlerts implements DeployAlerts {
  @override Future<bool> requestPermission() async => false;
  @override Future<void> transitions(List<Deployment> previous, List<Deployment> current, Preferences prefs) async {}
}
class FakeAdapter implements HttpClientAdapter {
  FakeAdapter(this.handler);
  final Future<ResponseBody> Function(RequestOptions) handler;
  final List<RequestOptions> requests = [];
  @override Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) {
    requests.add(options); return handler(options);
  }
  @override void close({bool force = false}) {}
}
ResponseBody response(Object? data, {int status = 200, Map<String, List<String>>? headers}) => ResponseBody.fromString(
  jsonEncode(data), status, headers: {'content-type': ['application/json'], ...?headers});
VercelApi fakeApi(FakeAdapter adapter, {DateTime Function()? clock}) {
  final dio = Dio()..httpClientAdapter = adapter;
  return VercelApi('TEST_ONLY_TOKEN_PLACEHOLDER', dio: dio, clock: clock);
}
final fixtureProject = Project.fromJson({'id': 'prj_fixture', 'name': 'projeto-teste', 'framework': 'nextjs', 'updatedAt': 1000});
final fixtureDeployment = Deployment.fromJson({'uid': 'dpl_fixture', 'name': 'projeto-teste', 'state': 'READY', 'created': 1000, 'url': 'fixture.vercel.app'});
Snapshot fixtureSnapshot() => Snapshot(account: const Account(id: 'user_fixture', name: 'Conta de teste'),
  teams: const [Team('team_fixture', 'Equipe de teste')], projects: [fixtureProject], deployments: [fixtureDeployment],
  syncedAt: DateTime.utc(2026, 10, 14));
