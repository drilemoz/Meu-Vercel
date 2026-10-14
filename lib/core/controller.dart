import 'package:flutter/foundation.dart';
import 'api.dart';
import 'errors.dart';
import 'models.dart';
import 'notifications.dart';
import 'repository.dart';
import 'storage.dart';

typedef ApiFactory = VercelApi Function(String token);
class AppController extends ChangeNotifier {
  AppController({required this.local, required this.tokens, required this.alerts, ApiFactory? apiFactory})
    : _apiFactory = apiFactory ?? VercelApi.new;
  final LocalData local;
  final TokenStore tokens;
  final DeployAlerts alerts;
  final ApiFactory _apiFactory;
  VercelApi? _api;
  Preferences prefs = const Preferences();
  Account? account;
  List<Team> teams = [];
  String? teamId;
  List<Project> projects = [];
  List<Deployment> deployments = [];
  String? projectCursor;
  String? deployCursor;
  DateTime? syncedAt;
  DateTime? _attemptAt;
  String? error;
  bool starting = true;
  bool busy = false;
  bool stale = true;
  bool needsToken = false;
  int pendingOperations = 0;
  void beginOperation() { pendingOperations++; notifyListeners(); }
  void endOperation() { if (pendingOperations > 0) pendingOperations--; notifyListeners(); }
  int _epoch = 0;
  bool get signedIn => _api != null && !needsToken;
  String get scope => local.scope(account?.id ?? 'unknown', teamId);
  String get activeName => teamId == null ? account?.name ?? 'Conta pessoal'
    : teams.where((t) => t.id == teamId).map((t) => t.name).firstOrNull ?? 'Equipe';
  List<String> get favorites => prefs.favorites[scope] ?? [];
  VercelRepository get repository {
    if (!signedIn) throw const ApiFailure(FailureKind.authentication, 'Configure um token válido.');
    return VercelRepository(_api!, team: teamId);
  }
  Future<void> initialize() async {
    prefs = local.preferences();
    try {
      final token = await tokens.read();
      if (token != null && token.isNotEmpty) {
        _api = _apiFactory(token);
        final session = local.session();
        final id = optionalString(session?['account']);
        teamId = optionalString(session?['team']);
        if (id != null) _restore(local.scope(id, teamId));
        if (prefs.autoSync) await sync(force: true);
      }
    } catch (_) { error = 'Não foi possível acessar a sessão segura. Configure o token novamente.'; }
    starting = false;
    notifyListeners();
  }
  void _restore(String cacheScope) {
    final snapshot = local.cache(cacheScope);
    if (snapshot == null) return;
    account = snapshot.account; teams = snapshot.teams; projects = snapshot.projects;
    deployments = snapshot.deployments; syncedAt = snapshot.syncedAt;
    projectCursor = snapshot.projectCursor; deployCursor = snapshot.deployCursor; stale = true;
  }
  Future<void> login(String raw) async {
    if (busy) return;
    final token = raw.trim();
    if (token.isEmpty || token.contains(RegExp(r'\s')) || token.length > 4096) {
      throw const ApiFailure(FailureKind.invalid, 'Informe um token pessoal válido.');
    }
    busy = true; error = null; notifyListeners();
    final candidate = _apiFactory(token);
    try {
      final repo = VercelRepository(candidate);
      final user = await repo.account();
      final availableTeams = await _allTeams(repo);
      await tokens.write(token);
      _epoch++; _api?.close(); _api = candidate;
      account = user; teams = availableTeams; teamId = null; needsToken = false;
      projects = []; deployments = []; syncedAt = null; projectCursor = null; deployCursor = null; stale = true;
      await local.saveSession(user.id, null);
    } catch (e) {
      if (!identical(_api, candidate)) candidate.close();
      if (e is ApiFailure) rethrow;
      throw const ApiFailure(FailureKind.invalid, 'Não foi possível salvar a sessão com segurança.');
    } finally { busy = false; notifyListeners(); }
    await sync(force: true);
  }
  Future<List<Team>> _allTeams(VercelRepository repo) async {
    final result = <Team>[];
    String? cursor;
    final seen = <String>{};
    do {
      final page = await repo.teams(cursor: cursor);
      result.addAll(page.items); cursor = page.next;
      if (cursor != null && !seen.add(cursor)) throw const ApiFailure(FailureKind.invalid, 'Paginação de equipes inconsistente.');
    } while (cursor != null);
    return result;
  }
  Future<void> _cache() async {
    if (account == null || syncedAt == null) return;
    await local.saveCache(scope, Snapshot(account: account!, teams: teams, projects: projects,
      deployments: deployments, syncedAt: syncedAt!, projectCursor: projectCursor, deployCursor: deployCursor));
  }
  Future<void> sync({bool force = false}) async {
    if (!signedIn || busy) return;
    if (!force && _attemptAt != null && DateTime.now().difference(_attemptAt!).inSeconds < 30) return;
    final epoch = _epoch;
    final repo = repository;
    busy = true; error = null; _attemptAt = DateTime.now(); notifyListeners();
    try {
      final values = await Future.wait<Object>([repo.account(), _allTeams(repo), repo.projects(), repo.deployments()]);
      if (epoch != _epoch) return;
      final user = values[0] as Account;
      if (account != null && account!.id != user.id) {
        throw const ApiFailure(FailureKind.authentication, 'A conta do token mudou. Autentique novamente.');
      }
      final old = deployments;
      account = user; teams = values[1] as List<Team>;
      final p = values[2] as Page<Project>; final d = values[3] as Page<Deployment>;
      projects = p.items; projectCursor = p.next; deployments = d.items; deployCursor = d.next;
      syncedAt = DateTime.now().toUtc(); stale = false;
      await local.saveSession(user.id, teamId);
      await _cache();
      try { await alerts.transitions(old, deployments, prefs); }
      catch (_) { error = 'Dados atualizados; os alertas não puderam ser exibidos.'; }
    } catch (e) { if (epoch == _epoch) { stale = true; await failure(e); } }
    finally { if (epoch == _epoch) { busy = false; notifyListeners(); } }
  }
  Future<void> failure(Object e) async {
    error = e is ApiFailure ? e.message : 'Não foi possível concluir a operação ou salvar os dados locais.';
    if (e is ApiFailure && e.kind == FailureKind.offline) stale = true;
    if (e is ApiFailure && e.kind == FailureKind.authentication) {
      needsToken = true; _api?.cancel();
      try { await tokens.clear(); } catch (_) { /* No diagnostics containing credentials. */ }
    }
    notifyListeners();
  }
  Future<void> selectTeam(String? id) async {
    if (id == teamId || busy || pendingOperations > 0) return;
    _epoch++; _api?.cancel();
    teamId = id; projects = []; deployments = []; syncedAt = null; stale = true;
    projectCursor = null; deployCursor = null; error = null;
    _restore(scope);
    if (account != null) await local.saveSession(account!.id, id);
    notifyListeners();
    if (prefs.autoSync) await sync(force: true);
  }
  Future<void> loadMoreProjects() async {
    if (busy || projectCursor == null) return;
    final epoch = _epoch; final cursor = projectCursor;
    busy = true; notifyListeners();
    try {
      final page = await repository.projects(cursor: cursor);
      if (epoch != _epoch) return;
      projects = {for (final p in [...projects, ...page.items]) p.id: p}.values.toList();
      projectCursor = page.next == cursor ? null : page.next;
      await _cache();
    } catch (e) { await failure(e); }
    finally { if (epoch == _epoch) { busy = false; notifyListeners(); } }
  }
  Future<void> loadMoreDeployments() async {
    if (busy || deployCursor == null) return;
    final epoch = _epoch; final cursor = deployCursor;
    busy = true; notifyListeners();
    try {
      final page = await repository.deployments(cursor: cursor);
      if (epoch != _epoch) return;
      deployments = {for (final d in [...deployments, ...page.items]) d.id: d}.values.toList();
      deployCursor = page.next == cursor ? null : page.next;
      await _cache();
    } catch (e) { await failure(e); }
    finally { if (epoch == _epoch) { busy = false; notifyListeners(); } }
  }
  Future<void> savePreferences(Preferences value) async {
    await local.savePreferences(value); prefs = value; notifyListeners();
  }
  Future<void> toggleFavorite(String id) async {
    final values = [...favorites]; values.contains(id) ? values.remove(id) : values.add(id);
    await savePreferences(prefs.copyWith(favorites: {...prefs.favorites, scope: values}));
  }
  Future<void> logout() async {
    await tokens.clear();
    _epoch++; _api?.close(); _api = null;
    account = null; teamId = null; teams = []; projects = []; deployments = [];
    syncedAt = null; needsToken = false; busy = false; error = null;
    notifyListeners();
    await local.clearSessionCache();
  }
  @override void dispose() { _api?.close(); super.dispose(); }
}
