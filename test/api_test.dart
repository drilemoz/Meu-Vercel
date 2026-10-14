import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meu_vercel/core/errors.dart';
import 'package:meu_vercel/core/repository.dart';
import 'package:meu_vercel/core/project_names.dart';
import 'support.dart';

void main() {
  test('valida autenticação usando /v2/user e não redireciona credenciais', () async {
    final adapter = FakeAdapter((_) async => response({'user': {'id': 'user_fixture', 'name': 'Pessoa'}}));
    final api = fakeApi(adapter); addTearDown(api.close);
    final account = await VercelRepository(api).account();
    expect(account.id, 'user_fixture');
    final request = adapter.requests.single;
    expect(request.uri.scheme, 'https'); expect(request.uri.host, 'api.vercel.com');
    expect(request.path, '/v2/user'); expect(request.followRedirects, false);
    expect(request.connectTimeout, const Duration(seconds: 12));
  });
  for (final entry in {401: FailureKind.authentication, 403: FailureKind.forbidden,
    404: FailureKind.missing, 400: FailureKind.invalid, 500: FailureKind.server}.entries) {
    test('HTTP ${entry.key} mapeia erro sem vazar corpo privado', () async {
      final api = fakeApi(FakeAdapter((_) async => response({'secret': 'PRIVATE_ERROR_BODY'}, status: entry.key)));
      addTearDown(api.close);
      await expectLater(api.get('/v2/user'), throwsA(isA<ApiFailure>()
        .having((e) => e.kind, 'tipo', entry.value)
        .having((e) => e.message.contains('PRIVATE_ERROR_BODY'), 'segredo omitido', false)));
    });
  }
  test('HTTP 429 respeita Retry-After e evita requisições repetidas', () async {
    var now = DateTime.utc(2026, 10, 14);
    final adapter = FakeAdapter((_) async => response({}, status: 429, headers: {'retry-after': ['120']}));
    final api = fakeApi(adapter, clock: () => now); addTearDown(api.close);
    await expectLater(api.get('/v2/user'), throwsA(isA<ApiFailure>().having((e) => e.kind, 'tipo', FailureKind.rateLimit)));
    await expectLater(api.get('/v2/user'), throwsA(isA<ApiFailure>()));
    expect(adapter.requests.length, 1);
    now = now.add(const Duration(seconds: 121));
    await expectLater(api.get('/v2/user'), throwsA(isA<ApiFailure>()));
    expect(adapter.requests.length, 2);
  });
  test('falha de conexão é informada sem diagnóstico com credenciais', () async {
    final api = fakeApi(FakeAdapter((options) async => throw DioException(requestOptions: options, type: DioExceptionType.connectionError)));
    addTearDown(api.close);
    await expectLater(api.get('/v2/user'), throwsA(isA<ApiFailure>().having((e) => e.kind, 'tipo', FailureKind.offline)));
  });
  test('GETs concorrentes iguais são deduplicados', () async {
    final pending = Completer<ResponseBody>();
    final adapter = FakeAdapter((_) => pending.future);
    final api = fakeApi(adapter); addTearDown(api.close);
    final first = api.get('/v2/user'); final second = api.get('/v2/user');
    await Future<void>.delayed(Duration.zero);
    pending.complete(response({'user': {'id': 'user_fixture'}}));
    await Future.wait([first, second]); expect(adapter.requests.length, 1);
  });
  test('paginação e escopo da equipe são enviados corretamente', () async {
    final adapter = FakeAdapter((options) async => response({'projects': [{'id': 'prj_fixture', 'name': 'projeto'}], 'pagination': {'next': 1234}}));
    final api = fakeApi(adapter); addTearDown(api.close);
    final page = await VercelRepository(api, team: 'team_fixture').projects(cursor: '9876');
    expect(page.items.single.name, 'projeto'); expect(page.next, '1234');
    expect(adapter.requests.single.queryParameters['teamId'], 'team_fixture');
    expect(adapter.requests.single.queryParameters['until'], '9876');
  });
  test('redeploy Preview omite target e Production envia target explícito', () async {
    final adapter = FakeAdapter((_) async => response({})); final api = fakeApi(adapter); addTearDown(api.close);
    final repo = VercelRepository(api);
    await repo.redeploy('dpl_fixture', 'projeto', 'preview');
    await repo.redeploy('dpl_fixture', 'projeto', 'production');
    expect((adapter.requests[0].data as Map).containsKey('target'), false);
    expect((adapter.requests[1].data as Map)['target'], 'production');
  });
  test('renomear usa PATCH com ID estável, nome e escopo corretos', () async {
    final adapter = FakeAdapter((_) async => response({}));
    final api = fakeApi(adapter); addTearDown(api.close);
    await VercelRepository(api, team: 'team_fixture').renameProject('prj_fixture', 'novo-projeto');
    final request = adapter.requests.single;
    expect(request.method, 'PATCH');
    expect(request.uri.path, '/v9/projects/prj_fixture');
    expect(request.queryParameters['teamId'], 'team_fixture');
    expect(request.data, {'name': 'novo-projeto'});
  });
  test('nome inválido nunca envia requisição de renomeação', () async {
    final adapter = FakeAdapter((_) async => response({}));
    final api = fakeApi(adapter); addTearDown(api.close);
    final repository = VercelRepository(api);
    for (final name in ['', 'LetraMaiuscula', 'nome---errado', 'dois espaços', 'a' * 101]) {
      expect(validProjectName(name), false);
      await expectLater(repository.renameProject('prj_fixture', name), throwsA(isA<ApiFailure>()));
    }
    expect(validProjectName('novo-projeto_01.vercel'), true);
    expect(adapter.requests, isEmpty);
  });
  test('variáveis nunca pedem descriptografia', () async {
    final adapter = FakeAdapter((_) async => response({'envs': [{'id': 'env_fixture', 'key': 'CHAVE', 'target': ['preview'], 'value': 'IGNORED_SECRET'}]}));
    final api = fakeApi(adapter); addTearDown(api.close);
    final env = await VercelRepository(api).variables('prj_fixture');
    expect(env.single.key, 'CHAVE'); expect(adapter.requests.single.queryParameters['decrypt'], false);
  });
  test('endereços externos e relativos fora da API são rejeitados', () async {
    final api = fakeApi(FakeAdapter((_) async => response({}))); addTearDown(api.close);
    await expectLater(api.get('https://example.com'), throwsA(isA<ApiFailure>()));
    await expectLater(api.get('//example.com/path'), throwsA(isA<ApiFailure>()));
  });
}
