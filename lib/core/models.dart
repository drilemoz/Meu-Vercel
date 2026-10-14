import 'errors.dart';

typedef Json = Map<String, dynamic>;

Json object(Object? value) {
  if (value is Map<String, dynamic>) return value;
  throw const ApiFailure(FailureKind.invalid, 'Resposta inesperada da API.');
}
String requiredString(Json json, String key) {
  final value = json[key];
  if (value is! String || value.isEmpty) {
    throw const ApiFailure(FailureKind.invalid, 'Recurso recebido sem identificação válida.');
  }
  return value;
}
String? optionalString(Object? value) => value is String ? value : null;
List<String> strings(Object? value) => value is List ? value.whereType<String>().toList() : [];
DateTime? date(Object? value) {
  if (value is num) return DateTime.fromMillisecondsSinceEpoch(value.toInt(), isUtc: true);
  return value is String ? DateTime.tryParse(value)?.toUtc() : null;
}
List<Json> objects(Object? value) {
  if (value is! List) throw const ApiFailure(FailureKind.invalid, 'Lista inválida recebida da API.');
  return value.map(object).toList();
}

class Account {
  const Account({required this.id, required this.name, this.email});
  final String id;
  final String name;
  final String? email;
  factory Account.fromJson(Json j) => Account(
    id: requiredString(j, 'id'),
    name: optionalString(j['name']) ?? optionalString(j['username']) ?? 'Conta pessoal',
    email: optionalString(j['email']),
  );
  // Email is intentionally excluded from local cache.
  Json toJson() => {'id': id, 'name': name};
}
class Team {
  const Team(this.id, this.name);
  final String id;
  final String name;
  factory Team.fromJson(Json j) => Team(requiredString(j, 'id'),
    optionalString(j['name']) ?? optionalString(j['slug']) ?? 'Equipe');
  Json toJson() => {'id': id, 'name': name};
}
class Project {
  const Project({required this.id, required this.name, this.framework, this.repository,
    this.updatedAt, this.settings = const {}});
  final String id;
  final String name;
  final String? framework;
  final String? repository;
  final DateTime? updatedAt;
  final Json settings;
  static const settingKeys = ['buildCommand', 'installCommand', 'outputDirectory', 'rootDirectory'];
  factory Project.fromJson(Json j) {
    final link = j['link'] is Map ? object(j['link']) : <String, dynamic>{};
    final repo = optionalString(link['repo']) ?? optionalString(link['repoId']);
    final owner = optionalString(link['org']) ?? optionalString(link['repoOwner']);
    return Project(id: requiredString(j, 'id'), name: requiredString(j, 'name'),
      framework: optionalString(j['framework']), updatedAt: date(j['updatedAt']),
      repository: optionalString(j['repository']) ?? (repo == null ? null : [if (owner != null) owner, repo].join('/')),
      settings: {for (final k in settingKeys) k: optionalString((j['settings'] is Map ? object(j['settings']) : j)[k])});
  }
  Json toJson() => {'id': id, 'name': name, 'framework': framework,
    'repository': repository, 'updatedAt': updatedAt?.toIso8601String(),
    'settings': {for (final key in ['rootDirectory', 'outputDirectory']) key: settings[key]}};
}
class Deployment {
  const Deployment({required this.id, required this.name, required this.status,
    required this.environment, this.url, this.createdAt, this.commit, this.commitMessage, this.branch});
  final String id;
  final String name;
  final String status;
  final String environment;
  final String? url;
  final DateTime? createdAt;
  final String? commit;
  final String? commitMessage;
  final String? branch;
  bool get running => ['QUEUED', 'BUILDING', 'INITIALIZING'].contains(status);
  bool get production => environment == 'production';
  String get environmentLabel => production ? 'Production' : environment == 'preview' ? 'Preview' : 'Outro ($environment)';
  factory Deployment.fromJson(Json j) {
    final meta = j['meta'] is Map ? object(j['meta']) : <String, dynamic>{};
    return Deployment(id: optionalString(j['uid']) ?? requiredString(j, 'id'),
      name: requiredString(j, 'name'), status: optionalString(j['readyState']) ?? optionalString(j['state']) ?? 'UNKNOWN',
      environment: optionalString(j['target']) ?? 'preview', url: optionalString(j['url']),
      createdAt: date(j['createdAt'] ?? j['created']),
      commit: optionalString(j['commit']) ?? optionalString(meta['githubCommitSha']) ?? optionalString(meta['gitlabCommitSha']) ?? optionalString(meta['bitbucketCommitSha']),
      commitMessage: optionalString(j['commitMessage']) ?? optionalString(meta['githubCommitMessage']) ?? optionalString(meta['gitlabCommitMessage']),
      branch: optionalString(j['branch']) ?? optionalString(meta['githubCommitRef']) ?? optionalString(meta['gitlabCommitRef']));
  }
  Json toJson() => {'id': id, 'name': name, 'readyState': status, 'target': environment,
    'url': url, 'createdAt': createdAt?.toIso8601String(), 'commit': commit,
    'commitMessage': commitMessage, 'branch': branch};
}
class ProjectDomain {
  const ProjectDomain(this.name, this.verified, this.verification);
  final String name;
  final bool verified;
  final List<Json> verification;
  factory ProjectDomain.fromJson(Json j) => ProjectDomain(requiredString(j, 'name'),
    j['verified'] == true, j['verification'] is List ? objects(j['verification']) : []);
}
class EnvironmentVariable {
  const EnvironmentVariable(this.id, this.key, this.targets, this.type, this.branch, this.createdAt, this.updatedAt);
  final String id;
  final String key;
  final List<String> targets;
  final String type;
  final String? branch;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  factory EnvironmentVariable.fromJson(Json j) => EnvironmentVariable(requiredString(j, 'id'),
    requiredString(j, 'key'), strings(j['target']), optionalString(j['type']) ?? 'encrypted', optionalString(j['gitBranch']), date(j['createdAt']), date(j['updatedAt']));
  // Values are neither represented in this model nor written to storage.
}
class Page<T> {
  const Page(this.items, this.next);
  final List<T> items;
  final String? next;
  factory Page.decode(Json j, String key, T Function(Json) parse) {
    final pagination = j['pagination'] is Map ? object(j['pagination']) : <String, dynamic>{};
    final cursor = pagination['next'];
    if (cursor != null && cursor is! String && cursor is! num) {
      throw const ApiFailure(FailureKind.invalid, 'Paginação inválida recebida da API.');
    }
    return Page(objects(j[key]).map(parse).toList(), cursor?.toString());
  }
}
