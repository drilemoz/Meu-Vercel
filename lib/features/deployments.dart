import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/controller.dart';
import '../core/errors.dart';
import '../core/deployment_links.dart';
import '../core/deployment_tracking.dart';
import '../core/models.dart';
import '../core/storage.dart';
import 'common.dart';
import 'dashboard.dart';

const deployStatuses = ['all', 'READY', 'ERROR', 'BUILDING', 'QUEUED', 'INITIALIZING', 'CANCELED'];
class DeployFilters extends StatelessWidget {
  const DeployFilters({required this.status, required this.target, required this.onStatus, required this.onTarget, super.key});
  final String status;
  final String target;
  final ValueChanged<String> onStatus;
  final ValueChanged<String> onTarget;
  @override Widget build(BuildContext context) => Padding(padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Wrap(spacing: 16, children: [DropdownButton<String>(value: status, items: [for (final s in deployStatuses)
      DropdownMenuItem(value: s, child: Text(s == 'all' ? 'Todos os status' : statusLabel(s)))], onChanged: (s) => onStatus(s!)),
      DropdownButton<String>(value: target, items: const [DropdownMenuItem(value: 'all', child: Text('Todos os ambientes')),
        DropdownMenuItem(value: 'preview', child: Text('Preview')), DropdownMenuItem(value: 'production', child: Text('Production'))], onChanged: (s) => onTarget(s!))]));
}
class DeploymentsScreen extends StatefulWidget {
  const DeploymentsScreen(this.app, {super.key});
  final AppController app;
  @override State<DeploymentsScreen> createState() => _DeploymentsScreenState();
}
class _DeploymentsScreenState extends State<DeploymentsScreen> with OperationState<DeploymentsScreen> {
  @override AppController get app => widget.app;
  String status = 'all', target = 'all';
  @override Widget build(BuildContext context) {
    final items = app.deployments.where((d) => (status == 'all' || d.status == status) && (target == 'all' || d.environment == target));
    return Column(children: [DeployFilters(status: status, target: target,
      onStatus: (s) => setState(() => status = s), onTarget: (s) => setState(() => target = s)),
      Expanded(child: RefreshIndicator(onRefresh: () => app.sync(force: true), child: ListView(physics: const AlwaysScrollableScrollPhysics(), children: [
        if (items.isEmpty) const EmptyView('Nenhum deploy encontrado nos dados carregados.'),
        for (final d in items) DeploymentTile(app, d),
        if (app.deployCursor != null) TextButton(onPressed: app.busy ? null : () => run(app.loadMoreDeployments), child: const Text('Carregar mais deploys'))])))]);
  }
}
class ProjectDeploymentsScreen extends StatefulWidget {
  const ProjectDeploymentsScreen(this.app, this.project, {super.key});
  final AppController app;
  final Project project;
  @override State<ProjectDeploymentsScreen> createState() => _ProjectDeploymentsScreenState();
}
class _ProjectDeploymentsScreenState extends State<ProjectDeploymentsScreen> with OperationState<ProjectDeploymentsScreen> {
  @override AppController get app => widget.app;
  List<Deployment> items = [];
  String? cursor;
  String status = 'all', target = 'all';
  bool stale = true;
  DateTime? syncedAt;
  String get cacheScope => '${app.scope}:project:${widget.project.id}:$status:$target';
  @override void initState() { super.initState(); _restore(); WidgetsBinding.instance.addPostFrameCallback((_) => _load()); }
  void _restore() {
    final snapshot = app.local.cache(cacheScope);
    items = snapshot?.deployments ?? []; cursor = snapshot?.deployCursor; syncedAt = snapshot?.syncedAt; stale = true;
  }
  Future<void> _load({bool more = false}) => run(() async {
    setState(() => stale = true);
    final previousCursor = more ? cursor : null;
    final page = await app.repository.deployments(projectId: widget.project.id, cursor: previousCursor,
      state: status == 'all' ? null : status, target: target == 'all' ? null : target);
    if (!mounted) return;
    setState(() { items = {for (final d in [...(more ? items : <Deployment>[]), ...page.items]) d.id: d}.values.toList();
      cursor = page.next == previousCursor ? null : page.next; stale = false; syncedAt = DateTime.now().toUtc(); });
    if (app.account != null) await app.local.saveCache(cacheScope, Snapshot(account: app.account!, teams: app.teams,
      projects: [widget.project], deployments: items, syncedAt: syncedAt!, deployCursor: cursor));
  });
  void _filter(String value, bool isStatus) {
    if (working) return;
    setState(() { if (isStatus) { status = value; } else { target = value; } _restore(); }); _load();
  }
  @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: Text('Deploys · ${widget.project.name}'),
    actions: [IconButton(tooltip: 'Atualizar', onPressed: working ? null : () => _load(), icon: const Icon(Icons.refresh))]),
    body: Column(children: [if (working) const LinearProgressIndicator(), DeployFilters(status: status, target: target,
      onStatus: (v) => _filter(v, true), onTarget: (v) => _filter(v, false)),
      ListTile(dense: true, leading: Icon(stale ? Icons.history : Icons.check_circle_outline),
        title: Text(stale ? 'Cache · ${displayDate(syncedAt)}' : 'Atualizado · ${displayDate(syncedAt)}')),
      Expanded(child: ListView(children: [if (items.isEmpty) const EmptyView('Nenhum deploy carregado.'),
        for (final d in items) DeploymentTile(app, d),
        if (cursor != null) TextButton(onPressed: working ? null : () => _load(more: true), child: const Text('Carregar mais'))]))]));
}
class DeploymentScreen extends StatefulWidget {
  const DeploymentScreen(this.app, this.initial, {this.trackOnOpen = false, super.key});
  final AppController app;
  final Deployment initial;
  final bool trackOnOpen;
  @override State<DeploymentScreen> createState() => _DeploymentScreenState();
}
class _DeploymentScreenState extends State<DeploymentScreen>
    with WidgetsBindingObserver, OperationState<DeploymentScreen> {
  @override AppController get app => widget.app;
  late Deployment deployment;
  List<String> logs = [];
  bool current = false;
  bool tracking = false;
  int checks = 0;
  int _trackGeneration = 0;
  String? trackingNote;
  @override void initState() {
    super.initState();
    deployment = widget.initial;
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (widget.trackOnOpen) { unawaited(_track()); }
      else { unawaited(_reload()); }
    });
  }
  @override void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed && tracking) {
      _pauseTracking('Acompanhamento pausado ao sair do aplicativo. Atualize ao retornar.');
    }
  }
  @override void dispose() {
    ++_trackGeneration; // Invalidates any pending network result or delayed check.
    WidgetsBinding.instance.removeObserver(this);
    logs.clear();
    super.dispose();
  }
  void _pauseTracking(String message) {
    ++_trackGeneration;
    if (mounted) setState(() { tracking = false; trackingNote = message; });
  }
  Future<void> _track() async {
    if (!mounted || tracking || working) return;
    final generation = ++_trackGeneration;
    setState(() { tracking = true; trackingNote = null; checks = 0; });
    for (var i = 0; i < DeploymentTracking.maxChecks; i++) {
      if (!mounted || generation != _trackGeneration) return;
      try {
        final value = await app.repository.deployment(deployment.id);
        if (!mounted || generation != _trackGeneration) return;
        setState(() { deployment = value; current = true; checks = i + 1; });
        if (DeploymentTracking.isTerminal(value.status)) {
          _pauseTracking(DeploymentTracking.summary(value.status));
          return;
        }
      } catch (e) {
        if (!mounted || generation != _trackGeneration) return;
        _pauseTracking(e is ApiFailure ? e.message : 'Não foi possível consultar o status.');
        return;
      }
      if (i + 1 < DeploymentTracking.maxChecks) {
        await Future<void>.delayed(DeploymentTracking.interval);
      }
    }
    if (mounted && generation == _trackGeneration) {
      _pauseTracking('Acompanhamento encerrado após 12 consultas. '
        'O deploy pode continuar em execução. Atualize quando quiser.');
    }
  }
  Future<void> _reload() => run(() async {
    final value = await app.repository.deployment(deployment.id);
    if (mounted) setState(() { deployment = value; current = true;
      trackingNote = DeploymentTracking.isTerminal(value.status)
        ? DeploymentTracking.summary(value.status) : null; });
  });
  Future<void> _logs() => run(() async {
    final events = await app.repository.events(deployment.id);
    final text = <String>[];
    for (final event in events.take(200)) {
      final payload = event['payload'] is Map ? object(event['payload']) : <String, dynamic>{};
      final value = optionalString(event['text']) ?? optionalString(payload['text']) ?? optionalString(payload['message']);
      if (value != null) {
        final safe = app.repository.redactLog(value);
        text.add(safe.length > 16000 ? safe.substring(0, 16000) : safe);
      }
    }
    if (mounted) setState(() => logs = text.reversed.toList());
  });
  Future<void> _cancel() async {
    if (!await confirmAction(context, title: 'Cancelar deploy?', resource: '${deployment.name} · ${deployment.id}', production: deployment.production,
      description: 'O deploy em execução será interrompido quando permitido pela Vercel.')) return;
    await run(() async { await app.repository.cancelDeployment(deployment.id); deployment = await app.repository.deployment(deployment.id);
      await app.sync(force: true); }, success: 'Cancelamento solicitado.');
  }
  Future<void> _redeploy() async {
    final target = await showDialog<String>(context: context, builder: (context) => SimpleDialog(title: const Text('Ambiente do novo deploy'),
      children: [SimpleDialogOption(onPressed: () => Navigator.pop(context, 'preview'), child: const Text('Preview')),
        SimpleDialogOption(onPressed: () => Navigator.pop(context, 'production'), child: const Text('Production'))]));
    if (!mounted || target == null) return;
    if (!await confirmAction(context, title: 'Criar novo deploy?', resource: '${deployment.name} · ${deployment.id}', production: target == 'production',
      description: 'Refazer este deploy em ${target == 'production' ? 'Production' : 'Preview'} usando o mecanismo oficial da Vercel.')) return;
    await run(() async { await app.repository.redeploy(deployment.id, deployment.name, target); await app.sync(force: true); }, success: 'Novo deploy solicitado.');
  }
  Uri? get _siteUrl => deploymentHttpsUrl(deployment.url);
  Future<void> _openUrl() => run(() async {
    final uri = _siteUrl;
    if (uri == null) throw const ApiFailure(FailureKind.invalid, 'URL HTTPS inválida.');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw const ApiFailure(FailureKind.invalid, 'Não foi possível abrir a URL.');
    }
  });
  Future<void> _copyUrl() async {
    final uri = _siteUrl;
    if (uri == null) return;
    try {
      await Clipboard.setData(ClipboardData(text: uri.toString()));
      if (mounted) feedback(context, 'URL copiada.');
    } catch (_) {
      if (mounted) feedback(context, 'Não foi possível copiar a URL.');
    }
  }
  @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: Text(deployment.name), actions: [
    IconButton(tooltip: 'Atualizar', onPressed: working || tracking ? null : _reload, icon: const Icon(Icons.refresh))]),
    body: ListView(children: [if (working || tracking) const LinearProgressIndicator(),
      ListTile(title: Text(deployment.environmentLabel), trailing: StatusBadge(deployment)),
      if (tracking) ListTile(leading: const Icon(Icons.sync),
        title: Text('Acompanhando deploy · consulta $checks/${DeploymentTracking.maxChecks}'),
        subtitle: const Text('A Vercel ainda não confirmou a conclusão.'),
        trailing: TextButton(onPressed: () => _pauseTracking('Acompanhamento pausado. Atualize manualmente.'),
          child: const Text('Pausar'))),
      if (trackingNote != null) ListTile(leading: Icon(
          deployment.status == 'READY' ? Icons.check_circle_outline : Icons.info_outline),
        title: Text(trackingNote!)),
      if (!tracking && !DeploymentTracking.isTerminal(deployment.status))
        Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: OutlinedButton.icon(
          onPressed: working ? null : () => unawaited(_track()),
          icon: const Icon(Icons.sync), label: const Text('Acompanhar status (até 12 consultas)'))),
      if (!current) const ListTile(dense: true, leading: Icon(Icons.history), title: Text('Status ainda não confirmado online.')),
      InfoLine('Data e horário', displayDate(deployment.createdAt)), InfoLine('Commit', deployment.commit), InfoLine('Mensagem', deployment.commitMessage),
      InfoLine('Branch', deployment.branch),
      ListTile(title: const Text('URL do deploy'), subtitle: SelectableText(_siteUrl?.toString() ?? 'Não disponível'),
        trailing: _siteUrl == null ? null : IconButton(tooltip: 'Copiar URL',
          onPressed: _copyUrl, icon: const Icon(Icons.copy_outlined))),
      if (_siteUrl != null) Padding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        child: Align(alignment: Alignment.centerLeft, child: FilledButton.tonalIcon(
          onPressed: working ? null : _openUrl, icon: const Icon(Icons.open_in_new),
          label: Text(deployment.status == 'READY' ? 'Abrir site' : 'Abrir URL (pode não estar pronta)')))),
      Padding(padding: const EdgeInsets.all(16), child: Wrap(spacing: 8, runSpacing: 8, children: [
        FilledButton.tonalIcon(onPressed: working || tracking ? null : _redeploy, icon: const Icon(Icons.replay), label: const Text('Novo deploy')),
        if (deployment.running) OutlinedButton.icon(onPressed: working || tracking ? null : _cancel, icon: const Icon(Icons.stop_circle_outlined), label: const Text('Cancelar'))])),
      ExpansionTile(title: const Text('Eventos e erros de build'), children: [
        const Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('Logs da Vercel podem conter dados do seu projeto. São exibidos apenas nesta tela, sem cache ou backup.', style: TextStyle(fontSize: 12))),
        TextButton(onPressed: working ? null : _logs, child: const Text('Consultar até 200 eventos recentes')),
        if (logs.isEmpty) const EmptyView('Consulte os eventos para ver os registros disponíveis.'),
        for (final line in logs) Padding(padding: const EdgeInsets.fromLTRB(16, 4, 16, 4), child: SelectableText(line, style: const TextStyle(fontFamily: 'monospace', fontSize: 12))),
      ]), ExpansionTile(title: const Text('Informações técnicas'), children: [InfoLine('ID', deployment.id)]),
    ]));
}
