import 'package:flutter_test/flutter_test.dart';
import 'package:meu_vercel/core/errors.dart';
import 'package:meu_vercel/core/models.dart';
import 'package:meu_vercel/core/production_actions.dart';
import 'package:meu_vercel/core/repository.dart';
import 'support.dart';

Deployment deploy({String id = 'dpl_preview', String project = 'prj_site',
    String status = 'READY', String target = 'preview'}) => Deployment(
  id: id, name: 'meu-site', projectId: project,
  status: status, environment: target);

void main() {
  test('modelo preserva projectId no cache sem guardar credenciais', () {
    final parsed = Deployment.fromJson({'uid': 'dpl_test', 'name': 'site',
      'projectId': 'prj_site', 'readyState': 'READY', 'target': 'preview'});
    expect(parsed.projectId, 'prj_site');
    expect(Deployment.fromJson(parsed.toJson()).projectId, 'prj_site');
  });
  test('READY, projeto e ambiente são exigidos antes da mutação', () {
    ProductionActions.requireDeployment(deploy(), 'prj_site', preview: true);
    for (final source in [
      deploy(project: 'prj_outro'),
      deploy(project: ''),
      deploy(status: 'BUILDING'),
      deploy(status: 'ERROR'),
      deploy(target: 'production'),
    ]) {
      expect(() => ProductionActions.requireDeployment(source, 'prj_site', preview: true),
        throwsA(isA<ApiFailure>()));
    }
    ProductionActions.requireDeployment(deploy(target: 'production'), 'prj_site', preview: false);
    expect(() => ProductionActions.requireDeployment(deploy(), 'prj_site', preview: false),
      throwsA(isA<ApiFailure>()));
  });
  test('Preview cria um novo deployment Production, sem usar endpoint de alias', () async {
    final adapter = FakeAdapter((options) async {
      if (options.method == 'GET') return response({'id': 'dpl_preview', 'name': 'meu-site',
        'projectId': 'prj_site', 'readyState': 'READY', 'target': 'preview'});
      return response({'id': 'dpl_novo'});
    });
    final api = fakeApi(adapter); addTearDown(api.close);
    final result = await VercelRepository(api, team: 'team_um').promotePreview('prj_site', 'dpl_preview');
    expect(result, 'dpl_novo');
    expect(adapter.requests.map((r) => r.method), ['GET', 'POST']);
    final request = adapter.requests.last;
    expect(request.uri.path, '/v13/deployments');
    expect(request.queryParameters['teamId'], 'team_um');
    expect(request.data, {'deploymentId': 'dpl_preview', 'name': 'meu-site', 'project': 'prj_site', 'target': 'production'});
  });
  test('Preview não publica caso deploy consultado pertença a outro projeto', () async {
    final adapter = FakeAdapter((_) async => response({'id': 'dpl_preview', 'name': 'meu-site',
      'projectId': 'prj_outro', 'readyState': 'READY', 'target': 'preview'}));
    final api = fakeApi(adapter); addTearDown(api.close);
    await expectLater(VercelRepository(api).promotePreview('prj_site', 'dpl_preview'), throwsA(isA<ApiFailure>()));
    expect(adapter.requests.map((r) => r.method), ['GET']);
  });
  test('Production staged promove pelo endpoint correto com teamId e sem rebuild', () async {
    final adapter = FakeAdapter((options) async => response(options.method == 'GET'
      ? {'id': 'dpl_stage', 'name': 'meu-site', 'projectId': 'prj_site',
          'readyState': 'READY', 'target': 'production'} : {}));
    final api = fakeApi(adapter); addTearDown(api.close);
    await VercelRepository(api, team: 'team_um').promoteProduction('prj_site', 'dpl_stage');
    expect(adapter.requests.last.method, 'POST');
    expect(adapter.requests.last.uri.path, '/v10/projects/prj_site/promote/dpl_stage');
    expect(adapter.requests.last.queryParameters['teamId'], 'team_um');
  });
  test('Rollback só envia POST para deploy production anterior', () async {
    final adapter = FakeAdapter((options) async {
      if (options.path.startsWith('/v13/deployments/')) return response({'id': 'dpl_old',
        'name': 'meu-site', 'projectId': 'prj_site', 'readyState': 'READY', 'target': 'production'});
      if (options.path == '/v6/deployments') return response({'deployments': [
        {'uid': 'dpl_current', 'projectId': 'prj_site', 'name': 'meu-site', 'readyState': 'READY', 'target': 'production'},
        {'uid': 'dpl_old', 'projectId': 'prj_site', 'name': 'meu-site', 'readyState': 'READY', 'target': 'production'},
      ], 'pagination': {}});
      return response({}, status: 201);
    });
    final api = fakeApi(adapter); addTearDown(api.close);
    await VercelRepository(api, team: 'team_um').rollbackProduction('prj_site', 'dpl_old');
    expect(adapter.requests.map((r) => r.method), ['GET', 'GET', 'POST']);
    final request = adapter.requests.last;
    expect(request.uri.path, '/v1/projects/prj_site/rollback/dpl_old');
    expect(request.queryParameters['teamId'], 'team_um');
  });
  test('Rollback do mais recente é bloqueado sem POST', () async {
    final adapter = FakeAdapter((options) async => response(options.path.startsWith('/v13/')
      ? {'id': 'dpl_current', 'name': 'meu-site', 'projectId': 'prj_site', 'readyState': 'READY', 'target': 'production'}
      : {'deployments': [{'uid': 'dpl_current', 'projectId': 'prj_site', 'name': 'meu-site',
          'readyState': 'READY', 'target': 'production'}], 'pagination': {}}));
    final api = fakeApi(adapter); addTearDown(api.close);
    await expectLater(VercelRepository(api).rollbackProduction('prj_site', 'dpl_current'), throwsA(isA<ApiFailure>()));
    expect(adapter.requests.where((r) => r.method == 'POST'), isEmpty);
  });
}
