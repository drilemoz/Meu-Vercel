import 'dart:convert';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meu_vercel/core/errors.dart';
import 'package:meu_vercel/core/github_projects.dart';
import 'package:meu_vercel/core/models.dart';
import 'package:meu_vercel/core/repository.dart';
import 'package:meu_vercel/core/static_deploy.dart';
import 'support.dart';

Uint8List sampleZip(Map<String, String> files) {
  final archive = Archive();
  for (final entry in files.entries) {
    final content = utf8.encode(entry.value);
    archive.add(ArchiveFile(entry.key, content.length, content));
  }
  return ZipEncoder().encodeBytes(archive);
}

void main() {
  test('GitHub aceita caminho/URL e rejeita hosts, credenciais e caminhos extras', () {
    expect(githubRepositoryPath('vercel/next.js'), 'vercel/next.js');
    expect(githubRepositoryPath('https://github.com/owner/repo.git'), 'owner/repo');
    for (final value in ['github.com/owner/repo', 'http://github.com/owner/repo',
      'https://github.com.evil.test/owner/repo', 'https://github.com/owner/repo/issues',
      'https://name:pass@github.com/owner/repo', 'https://github.com/owner/repo?token=x',
      'one', 'owner/../repo']) {
      expect(() => githubRepositoryPath(value), throwsA(isA<ApiFailure>()));
    }
  });
  test('criar GitHub usa API de projetos, path seguro e escopo da equipe', () async {
    final adapter = FakeAdapter((_) async => response({'id': 'prj_mock'}));
    final api = fakeApi(adapter); addTearDown(api.close);
    await VercelRepository(api, team: 'team_example').createGitHubProject('site-novo', 'owner/repo');
    final req = adapter.requests.single;
    expect(req.uri.path, '/v11/projects');
    expect(req.queryParameters['teamId'], 'team_example');
    expect(req.data, {'name': 'site-novo', 'gitRepository': {'type': 'github', 'repo': 'owner/repo'}});
  });
  test('ZIP estático aceita diretório raiz ou envelope único', () {
    for (final entries in [
      {'index.html': '<h1>Teste</h1>', 'app.js': 'alert(1)'},
      {'site/index.html': 'ok', 'site/css/site.css': '* {}'},
    ]) {
      final files = StaticZip.prepare(sampleZip(entries));
      expect(files.any((file) => file.path == 'index.html'), true);
      expect(files.first.sha.length, 40);
      expect(files.length, 2);
    }
  });
  test('ZIP rejeita travessia, segredo, duplicado, sem index, excesso de arquivos', () {
    for (final entries in [
      {'../index.html': 'x'}, {'site/.env': 'TOKEN=xx', 'site/index.html': 'hi'},
      {'index.html': 'x', 'INDEX.HTML': 'x'}, {'README.md': 'x'},
      {'index.html': 'x', 'other/private.pem': 'key'},
    ]) {
      expect(() => StaticZip.prepare(sampleZip(entries)), throwsA(isA<ApiFailure>()));
    }
    final tooMany = {for (var i = 0; i < 121; i++) 'file$i.txt': 'ok'}..['index.html'] = 'hi';
    expect(() => StaticZip.prepare(sampleZip(tooMany)), throwsA(isA<ApiFailure>()));
  });
  test('upload usa SHA1/arquivo binário e cria somente Preview', () async {
    final adapter = FakeAdapter((req) async => response(req.uri.path == '/v13/deployments' ? {'id': 'dpl_example'} : {}));
    final api = fakeApi(adapter); addTearDown(api.close);
    final files = StaticZip.prepare(sampleZip({'index.html': 'teste', 'a.css': 'teste'}));
    final progress = <int>[];
    final id = await VercelRepository(api, team: 'team_abc').deployStaticPreview(
      const Project(id: 'prj_abc', name: 'estatico'), files,
      onProgress: (sent, _) => progress.add(sent));
    expect(id, 'dpl_example');
    expect(progress, [1, 2]);
    expect(adapter.requests.length, 2); // duplicate digest uploaded just once.
    final upload = adapter.requests.first;
    expect(upload.uri.path, '/v2/files');
    expect(upload.headers['x-vercel-digest'], files.first.sha);
    expect(upload.queryParameters['teamId'], 'team_abc');
    final req = adapter.requests.last;
    expect(req.uri.path, '/v13/deployments');
    final body = req.data as Map;
    expect(body['target'], isNull);
    expect(body['project'], 'prj_abc');
    expect(body['projectSettings'], {'framework': null});
    expect((body['files'] as List).length, 2);
    expect(body['files'][0]['size'], utf8.encode('teste').length);
  });
  test('ZIP não publica em projeto com repositório ou framework', () async {
    final adapter = FakeAdapter((_) async => response({}));
    final api = fakeApi(adapter); addTearDown(api.close);
    final files = StaticZip.prepare(sampleZip({'index.html': 'ok'}));
    for (final project in [
      const Project(id: 'prj1', name: 'git', repository: 'org/repo'),
      const Project(id: 'prj2', name: 'next', framework: 'nextjs')]) {
      await expectLater(VercelRepository(api).deployStaticPreview(project, files), throwsA(isA<ApiFailure>()));
    }
    expect(adapter.requests, isEmpty);
  });
  test('seleção de arquivos diretos mantém nomes e SHA-1', () {
    final files = StaticSite.prepare([
      (path: 'index.html', bytes: Uint8List.fromList(utf8.encode('<h1>Olá</h1>'))),
      (path: 'assets/styles.css', bytes: Uint8List.fromList(utf8.encode('body {}'))),
    ]);
    expect(files.length, 2);
    expect(files[1].path, 'assets/styles.css');
    StaticSite.validate(files);
  });
  test('seleção direta impede traversal, credenciais, colisões e sem index', () {
    for (final bad in ['../index.html', '.env.local', '.ssh/id_rsa',
      'site/private.key', '/index.html', r'css\bad.css', 'C:/index.html',
      'foo//index.html', '.vercel/output/index.html', 'credentials.json']) {
      expect(() => StaticSite.prepare([
        (path: 'index.html', bytes: Uint8List(1)),
        (path: bad, bytes: Uint8List(1)),
      ]), throwsA(isA<ApiFailure>()), reason: bad);
    }
    expect(() => StaticSite.prepare([
      (path: 'index.html', bytes: Uint8List(1)),
      (path: 'INDEX.HTML', bytes: Uint8List(1)),
    ]), throwsA(isA<ApiFailure>()));
    expect(() => StaticSite.prepare([
      (path: 'css/site.css', bytes: Uint8List(2)),
    ]), throwsA(isA<ApiFailure>()));
  });
  test('validação rejeita checksums inventados antes de enviar', () async {
    final adapter = FakeAdapter((_) async => response({}));
    final api = fakeApi(adapter); addTearDown(api.close);
    final invalid = [(path: 'index.html', bytes: Uint8List(2), sha: 'forged')];
    await expectLater(VercelRepository(api).deployStatic(
      const Project(id: 'prj', name: 'static'), invalid,
    ), throwsA(isA<ApiFailure>()));
    expect(adapter.requests, isEmpty);
  });
  test('publicação Production inclui target e mantém equipe/projeto', () async {
    final adapter = FakeAdapter((req) async => response(
      req.uri.path == '/v13/deployments' ? {'id': 'dpl_prod'} : {}));
    final api = fakeApi(adapter); addTearDown(api.close);
    final files = StaticSite.prepare([
      (path: 'index.html', bytes: Uint8List.fromList(utf8.encode('ok'))),
    ]);
    final repository = VercelRepository(api, team: 'team_42');
    expect(await repository.deployStatic(
      const Project(id: 'prj_42', name: 'site-estatico'), files,
      target: 'production'), 'dpl_prod');
    final deployment = adapter.requests.last;
    final body = deployment.data as Map;
    expect(body['target'], 'production');
    expect(body['project'], 'prj_42');
    expect(body['name'], 'site-estatico');
    expect(deployment.queryParameters['teamId'], 'team_42');
  });
  test('ambiente inválido é recusado antes de tocar rede', () async {
    final adapter = FakeAdapter((_) async => response({}));
    final api = fakeApi(adapter); addTearDown(api.close);
    final files = StaticSite.prepare([(path: 'index.html', bytes: Uint8List(1))]);
    await expectLater(VercelRepository(api).deployStatic(
      const Project(id: 'prj', name: 'static'), files, target: 'custom'),
      throwsA(isA<ApiFailure>()));
    expect(adapter.requests, isEmpty);
  });

}
