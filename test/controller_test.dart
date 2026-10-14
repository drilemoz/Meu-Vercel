import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meu_vercel/core/controller.dart';
import 'package:meu_vercel/core/errors.dart';
import 'package:meu_vercel/core/storage.dart';
import 'support.dart';

void main() {
  test('token inválido não é salvo no armazenamento seguro', () async {
    final tokens = MemoryTokens(); final adapter = FakeAdapter((_) async => response({}, status: 401));
    final app = AppController(local: LocalData(MemoryStore()), tokens: tokens, alerts: NoAlerts(), apiFactory: (_) => fakeApi(adapter));
    addTearDown(app.dispose);
    await expectLater(app.login('TEST_ONLY_TOKEN_PLACEHOLDER'), throwsA(isA<ApiFailure>()));
    expect(tokens.writes, 0); expect(app.signedIn, false);
  });
  test('autenticação validada salva token, carrega conta e sincroniza', () async {
    final tokens = MemoryTokens();
    final adapter = FakeAdapter((options) async {
      if (options.path == '/v2/user') return response({'user': {'id': 'user_fixture', 'name': 'Conta'}});
      if (options.path == '/v2/teams') return response({'teams': [], 'pagination': {'next': null}});
      if (options.path == '/v9/projects') return response({'projects': [], 'pagination': {'next': null}});
      return response({'deployments': [], 'pagination': {'next': null}});
    });
    final app = AppController(local: LocalData(MemoryStore()), tokens: tokens, alerts: NoAlerts(), apiFactory: (_) => fakeApi(adapter));
    addTearDown(app.dispose); await app.login('TEST_ONLY_TOKEN_PLACEHOLDER');
    expect(tokens.writes, 1); expect(app.account!.id, 'user_fixture'); expect(app.stale, false); expect(app.syncedAt, isNotNull);
  });
  test('abertura offline mantém cache e indica informações antigas', () async {
    final local = LocalData(MemoryStore()); await local.saveSession('user_fixture', null);
    await local.saveCache('user_fixture:personal', fixtureSnapshot());
    final tokens = MemoryTokens()..value = 'TEST_ONLY_TOKEN_PLACEHOLDER';
    final adapter = FakeAdapter((options) async => throw DioException(requestOptions: options, type: DioExceptionType.connectionError));
    final app = AppController(local: local, tokens: tokens, alerts: NoAlerts(), apiFactory: (_) => fakeApi(adapter));
    addTearDown(app.dispose); await app.initialize();
    expect(app.projects.single.id, 'prj_fixture'); expect(app.stale, true); expect(app.error, contains('Sem conexão')); expect(app.starting, false);
  });
  test('autoSync desativado não faz chamadas ao abrir e favoritos são por escopo', () async {
    final local = LocalData(MemoryStore()); await local.savePreferences(const Preferences(autoSync: false));
    await local.saveSession('user_fixture', null); await local.saveCache('user_fixture:personal', fixtureSnapshot());
    final tokens = MemoryTokens()..value = 'TEST_ONLY_TOKEN_PLACEHOLDER';
    final adapter = FakeAdapter((_) async => response({}));
    final app = AppController(local: local, tokens: tokens, alerts: NoAlerts(), apiFactory: (_) => fakeApi(adapter));
    addTearDown(app.dispose); await app.initialize(); await app.toggleFavorite('prj_fixture');
    expect(adapter.requests, isEmpty); expect(app.favorites, ['prj_fixture']);
    await app.selectTeam('team_fixture'); expect(app.favorites, isEmpty); expect(app.projects, isEmpty);
    await app.selectTeam(null); expect(app.favorites, ['prj_fixture']); expect(app.projects.length, 1);
  });
  test('erro de autenticação expira sessão e remove token', () async {
    final local = LocalData(MemoryStore()); await local.savePreferences(const Preferences(autoSync: false));
    final tokens = MemoryTokens()..value = 'TEST_ONLY_TOKEN_PLACEHOLDER';
    final app = AppController(local: local, tokens: tokens, alerts: NoAlerts(), apiFactory: (_) => fakeApi(FakeAdapter((_) async => response({}))));
    addTearDown(app.dispose); await app.initialize();
    await app.failure(const ApiFailure(FailureKind.authentication, 'Token inválido.'));
    expect(app.signedIn, false); expect(tokens.value, null);
  });
  test('paginação agrega sem duplicar itens', () async {
    final local = LocalData(MemoryStore()); await local.savePreferences(const Preferences(autoSync: false));
    final tokens = MemoryTokens()..value = 'TEST_ONLY_TOKEN_PLACEHOLDER';
    final adapter = FakeAdapter((_) async => response({'projects': [{'id': 'prj_fixture', 'name': 'projeto-teste'},
      {'id': 'prj_second', 'name': 'outro'}], 'pagination': {'next': null}}));
    final app = AppController(local: local, tokens: tokens, alerts: NoAlerts(), apiFactory: (_) => fakeApi(adapter));
    addTearDown(app.dispose); await app.initialize(); app.projects = [fixtureProject]; app.projectCursor = '1000';
    await app.loadMoreProjects(); expect(app.projects.length, 2); expect(app.projectCursor, null);
  });
}
