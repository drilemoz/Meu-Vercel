import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:meu_vercel/core/errors.dart';
import 'package:meu_vercel/core/models.dart';
import 'package:meu_vercel/core/storage.dart';
import 'support.dart';

void main() {
  test('converte commit, ambiente e horário do deploy real', () {
    final d = Deployment.fromJson({'id': 'dpl_fixture', 'name': 'projeto', 'readyState': 'ERROR', 'target': 'production',
      'createdAt': 1000, 'meta': {'githubCommitSha': 'abc123', 'githubCommitMessage': 'Atualização', 'githubCommitRef': 'main'}});
    expect(d.production, true); expect(d.commit, 'abc123'); expect(d.branch, 'main');
    expect(d.createdAt, DateTime.fromMillisecondsSinceEpoch(1000, isUtc: true));
  });
  test('respostas malformadas são recusadas', () {
    expect(() => Project.fromJson({'name': 'sem-id'}), throwsA(isA<ApiFailure>()));
    expect(() => Page<Project>.decode({'projects': null}, 'projects', Project.fromJson), throwsA(isA<ApiFailure>()));
    expect(() => Page<Project>.decode({'projects': [], 'pagination': {'next': {}}}, 'projects', Project.fromJson), throwsA(isA<ApiFailure>()));
  });
  test('cache persiste somente projeção permitida e mantém dados offline', () async {
    final store = MemoryStore(); final local = LocalData(store);
    final p = Project.fromJson({'id': 'prj_fixture', 'name': 'projeto', 'env': [{'value': 'SECRET_NOT_FOR_CACHE'}],
      'link': {'org': 'owner', 'repo': 'repo'}, 'token': 'SECRET_NOT_FOR_CACHE', 'buildCommand': 'SECRET_NOT_FOR_CACHE'});
    final snapshot = Snapshot(account: const Account(id: 'user_fixture', name: 'Teste', email: 'email-not-cached@example.com'),
      teams: [], projects: [p], deployments: [fixtureDeployment], syncedAt: DateTime.utc(2026));
    await local.saveCache('user_fixture:personal', snapshot);
    final persisted = store.values.values.join();
    expect(persisted.contains('SECRET_NOT_FOR_CACHE'), false); expect(persisted.contains('email-not-cached'), false);
    final restored = local.cache('user_fixture:personal')!;
    expect(restored.projects.single.repository, 'owner/repo'); expect(restored.deployments.single.id, 'dpl_fixture');
    expect(local.cache('other:personal'), null);
  });
  test('cache corrompido não impede inicialização', () async {
    final store = MemoryStore(); await store.write('cache.v1.fixture', '{bad');
    expect(LocalData(store).cache('fixture'), null);
  });
  test('encerramento limpa sessões e cache, preservando preferências', () async {
    final store = MemoryStore(); final local = LocalData(store);
    await local.savePreferences(const Preferences(theme: 'amoled', favorites: {'user_fixture:personal': ['prj_fixture']}));
    await local.saveSession('user_fixture', null); await local.saveCache('user_fixture:personal', fixtureSnapshot());
    await local.clearSessionCache();
    expect(local.session(), null); expect(local.cache('user_fixture:personal'), null);
    expect(local.preferences().theme, 'amoled');
    expect(jsonDecode(store.read('preferences.v1')!)['favorites']['user_fixture:personal'], ['prj_fixture']);
  });
}
