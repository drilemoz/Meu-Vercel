import 'api.dart';
import 'models.dart';
import 'project_names.dart';
import 'errors.dart';
import 'github_projects.dart';
import 'static_deploy.dart';

class VercelRepository {
  VercelRepository(this.api, {this.team});
  final VercelApi api;
  final String? team;
  String projectPath(String id) => '/v9/projects/${VercelApi.segment(id)}';
  Future<Account> account() async => Account.fromJson(object((await api.get('/v2/user'))['user']));
  Future<Page<Team>> teams({String? cursor}) async => Page.decode(await api.get('/v2/teams',
    query: {'limit': 100, if (cursor != null) 'until': cursor}), 'teams', Team.fromJson);
  Future<Page<Project>> projects({String? cursor}) async => Page.decode(await api.get('/v9/projects', team: team,
    query: {'limit': 50, if (cursor != null) 'until': cursor}), 'projects', Project.fromJson);
  Future<Project> project(String id) async => Project.fromJson(await api.get(projectPath(id), team: team));
  Future<Page<Deployment>> deployments({String? projectId, String? cursor, String? state, String? target}) async =>
    Page.decode(await api.get('/v6/deployments', team: team, query: {
      'limit': 30, if (projectId != null) 'projectId': projectId, if (cursor != null) 'until': cursor,
      if (state != null) 'state': state, if (target != null) 'target': target}), 'deployments', Deployment.fromJson);
  Future<Deployment> deployment(String id) async => Deployment.fromJson(await api.get('/v13/deployments/${VercelApi.segment(id)}', team: team));
  String redactLog(String text) => api.redact(text);
  Future<List<Json>> events(String id) async {
    final value = await api.read('/v3/deployments/${VercelApi.segment(id)}/events', team: team,
      query: {'direction': 'backward', 'limit': 200, 'follow': 0});
    return objects(value);
  }
  Future<void> createProject(String name, String? framework) async {
    await api.write('POST', '/v11/projects', team: team, body: {'name': name, if (framework != null) 'framework': framework});
  }
  Future<void> createGitHubProject(String name, String githubInput, {String? framework}) async {
    if (!validProjectName(name)) {
      throw const ApiFailure(FailureKind.invalid, 'Nome de projeto inválido.');
    }
    final repo = githubRepositoryPath(githubInput);
    await api.write('POST', '/v11/projects', team: team, body: {
      'name': name,
      'gitRepository': {'type': 'github', 'repo': repo},
      if (framework != null && framework.isNotEmpty) 'framework': framework,
    });
  }
  /// Uploads a static site and creates a Preview only, never a production deploy.
  /// Returns the newly created deployment ID, not a claim of a READY build.
  Future<String> deployStaticPreview(Project project, List<SiteFile> files,
      {void Function(int completed, int total)? onProgress}) async {
    if (project.repository != null || (project.framework != null && project.framework != 'other')) {
      throw const ApiFailure(FailureKind.invalid, 'Use um projeto estático sem Git ou framework vinculado.');
    }
    if (files.isEmpty || files.length > StaticZip.maxFiles ||
        !files.any((file) => file.path == 'index.html')) {
      throw const ApiFailure(FailureKind.invalid, 'Selecione um ZIP de site estático válido.');
    }
    final uploaded = <String>{};
    for (var i = 0; i < files.length; i++) {
      final file = files[i];
      if (uploaded.add(file.sha)) {
        await api.write('POST', '/v2/files', team: team, body: file.bytes,
          headers: {'x-vercel-digest': file.sha});
      }
      onProgress?.call(i + 1, files.length);
    }
    final result = object(await api.write('POST', '/v13/deployments', team: team, body: {
      'name': project.name,
      'project': project.id,
      'files': [for (final file in files) {
        'file': file.path, 'sha': file.sha, 'size': file.bytes.length,
      }],
      'projectSettings': {'framework': null},
      // Intentionally omit target: per Vercel API, this creates a Preview.
    }));
    return requiredString(result, 'id');
  }
  Future<void> updateProject(String id, Json settings) async {
    await api.write('PATCH', projectPath(id), team: team, body: settings);
  }
  Future<void> renameProject(String id, String newName) async {
    if (!validProjectName(newName)) {
      throw const ApiFailure(FailureKind.invalid, 'Nome de projeto inválido.');
    }
    // Busca pelo ID estável mesmo quando o nome for alterado.
    await api.write('PATCH', projectPath(id), team: team, body: {'name': newName});
  }
  Future<void> deleteProject(String id) async { await api.write('DELETE', projectPath(id), team: team); }
  Future<void> cancelDeployment(String id) async { await api.write('PATCH', '/v12/deployments/${VercelApi.segment(id)}/cancel', team: team); }
  /// Official redeployment mechanism. No arbitrary source files or deploy hooks.
  Future<void> redeploy(String id, String name, String target) async {
    await api.write('POST', '/v13/deployments', team: team,
      body: {'deploymentId': id, 'name': name, if (target == 'production') 'target': 'production'});
  }
  Future<Page<ProjectDomain>> domains(String id, {String? cursor}) async => Page.decode(
    await api.get('/v9/projects/${VercelApi.segment(id)}/domains', team: team,
      query: {'limit': 50, if (cursor != null) 'until': cursor}), 'domains', ProjectDomain.fromJson);
  Future<Json> domainConfiguration(String domain) => api.get('/v6/domains/${VercelApi.segment(domain)}/config', team: team);
  Future<void> addDomain(String id, String domain) async {
    await api.write('POST', '/v10/projects/${VercelApi.segment(id)}/domains', team: team, body: {'name': domain});
  }
  Future<void> removeDomain(String id, String domain) async {
    await api.write('DELETE', '/v9/projects/${VercelApi.segment(id)}/domains/${VercelApi.segment(domain)}', team: team);
  }
  Future<void> verifyDomain(String id, String domain) async {
    await api.write('POST', '/v9/projects/${VercelApi.segment(id)}/domains/${VercelApi.segment(domain)}/verify', team: team);
  }
  Future<List<EnvironmentVariable>> variables(String id) async {
    // Never request decrypt=true. Any returned value is discarded by the model.
    final j = await api.get('/v9/projects/${VercelApi.segment(id)}/env', team: team, query: {'decrypt': false});
    return objects(j['envs']).map(EnvironmentVariable.fromJson).toList();
  }
  Future<void> saveVariable(String project, {String? id, required String key,
      required String value, required List<String> targets, String? branch}) async {
    final base = '/v10/projects/${VercelApi.segment(project)}/env';
    await api.write(id == null ? 'POST' : 'PATCH', id == null ? base : '/v9/projects/${VercelApi.segment(project)}/env/${VercelApi.segment(id)}', team: team,
      body: {'key': key, 'value': value, 'type': 'encrypted', 'target': targets,
        if (branch != null && branch.isNotEmpty) 'gitBranch': branch});
  }
  Future<void> removeVariable(String project, String id) async {
    await api.write('DELETE', '/v9/projects/${VercelApi.segment(project)}/env/${VercelApi.segment(id)}', team: team);
  }
}
