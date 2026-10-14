import 'package:flutter/material.dart';
import '../core/controller.dart';
import '../core/models.dart';
import 'common.dart';
import 'dashboard.dart';
import 'deployments.dart';
import 'domains.dart';
import 'environment.dart';

class ProjectsScreen extends StatefulWidget {
  const ProjectsScreen(this.app, {super.key});
  final AppController app;
  @override State<ProjectsScreen> createState() => _ProjectsScreenState();
}
class _ProjectsScreenState extends State<ProjectsScreen> with OperationState<ProjectsScreen> {
  @override AppController get app => widget.app;
  String query = '';
  bool favoritesOnly = false;
  String sort = 'name';
  String framework = 'all';
  Future<void> _create() async {
    final input = await fieldsDialog(context, 'Criar projeto', {'name': 'Nome do projeto', 'framework': 'Framework (opcional)'});
    if (!mounted || input == null) return;
    final name = input['name']!.trim();
    if (!RegExp(r'^[a-z0-9][a-z0-9._-]{0,99}$').hasMatch(name)) { feedback(context, 'Use até 100 letras minúsculas, números, ponto, _ ou hífen.'); return; }
    if (!await confirmAction(context, title: 'Criar projeto?', resource: name,
      description: 'Criar na conta ${app.activeName}. A API pode exigir permissões ou um plano específico.')) return;
    await run(() async { await app.repository.createProject(name, input['framework']!.trim().isEmpty ? null : input['framework']!.trim());
      await app.sync(force: true); }, success: 'Projeto criado.');
  }
  @override Widget build(BuildContext context) {
    final frameworks = app.projects.map((p) => p.framework ?? 'none').toSet().toList()..sort();
    final selectedFramework = frameworks.contains(framework) ? framework : 'all';
    final projects = app.projects.where((p) => p.name.toLowerCase().contains(query.toLowerCase()) &&
      (!favoritesOnly || app.favorites.contains(p.id)) && (selectedFramework == 'all' || (p.framework ?? 'none') == selectedFramework)).toList();
    projects.sort((a, b) => sort == 'name' ? a.name.compareTo(b.name)
      : (b.updatedAt?.millisecondsSinceEpoch ?? 0).compareTo(a.updatedAt?.millisecondsSinceEpoch ?? 0));
    return Column(children: [Padding(padding: const EdgeInsets.fromLTRB(16, 8, 16, 0), child: TextField(
      decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Buscar nos projetos carregados', border: OutlineInputBorder(), isDense: true),
      onChanged: (value) => setState(() => query = value))),
      Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), child: Wrap(spacing: 8, crossAxisAlignment: WrapCrossAlignment.center,
        children: [FilterChip(label: const Text('Favoritos'), selected: favoritesOnly, onSelected: (v) => setState(() => favoritesOnly = v)),
          DropdownButton<String>(value: sort, items: const [DropdownMenuItem(value: 'name', child: Text('Nome')),
            DropdownMenuItem(value: 'updated', child: Text('Recentes'))], onChanged: (v) => setState(() => sort = v!)),
          DropdownButton<String>(value: selectedFramework, items: [const DropdownMenuItem(value: 'all', child: Text('Todos os frameworks')),
            for (final f in frameworks) DropdownMenuItem(value: f, child: Text(f == 'none' ? 'Não informado' : f))], onChanged: (v) => setState(() => framework = v!)),
          IconButton(tooltip: 'Criar projeto', onPressed: working ? null : _create, icon: const Icon(Icons.add))])),
      if (working) const LinearProgressIndicator(),
      Expanded(child: RefreshIndicator(onRefresh: () => app.sync(force: true), child: ListView(physics: const AlwaysScrollableScrollPhysics(),
        children: [if (projects.isEmpty) const EmptyView('Nenhum projeto encontrado.'), for (final p in projects) ProjectTile(app, p),
          if (app.projectCursor != null) TextButton(onPressed: app.busy ? null : () => run(app.loadMoreProjects), child: const Text('Carregar mais projetos'))]))),
    ]);
  }
}
class ProjectScreen extends StatefulWidget {
  const ProjectScreen(this.app, this.initial, {super.key});
  final AppController app;
  final Project initial;
  @override State<ProjectScreen> createState() => _ProjectScreenState();
}
class _ProjectScreenState extends State<ProjectScreen> with OperationState<ProjectScreen> {
  @override AppController get app => widget.app;
  late Project project;
  bool current = false;
  @override void initState() { super.initState(); project = widget.initial; WidgetsBinding.instance.addPostFrameCallback((_) => _reload()); }
  Future<void> _reload() => run(() async {
    setState(() => current = false);
    final loaded = await app.repository.project(project.id);
    if (mounted) setState(() { project = loaded; current = true; });
  });
  Future<void> _edit() async {
    final input = await fieldsDialog(context, 'Configurações de ${project.name}', const {
      'buildCommand': 'Comando de build', 'installCommand': 'Comando de instalação',
      'outputDirectory': 'Diretório de saída', 'rootDirectory': 'Diretório raiz'},
      initial: {for (final e in project.settings.entries) e.key: e.value as String? ?? ''});
    if (!mounted || input == null) return;
    if (!await confirmAction(context, title: 'Salvar configurações?', resource: project.name, production: true,
      description: 'As configurações serão usadas pelos próximos deploys. Campos vazios restauram o padrão.')) return;
    await run(() async { await app.repository.updateProject(project.id, {for (final e in input.entries) e.key: e.value.trim().isEmpty ? null : e.value.trim()});
      project = await app.repository.project(project.id); current = true; await app.sync(force: true); }, success: 'Configurações salvas.');
  }
  Future<void> _delete() async {
    if (!await confirmAction(context, title: 'Excluir projeto?', resource: project.name, destructive: true, production: true,
      description: 'O projeto e seus recursos na Vercel serão removidos. Esta operação não pode ser desfeita.')) return;
    await run(() async { await app.repository.deleteProject(project.id); await app.sync(force: true);
      if (mounted) Navigator.pop(context); });
  }
  @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: Text(project.name), actions: [
    IconButton(tooltip: 'Atualizar', onPressed: working ? null : _reload, icon: const Icon(Icons.refresh))]),
    body: ListView(children: [if (working) const LinearProgressIndicator(), if (!current) const ListTile(dense: true,
      leading: Icon(Icons.history), title: Text('Dados previamente sincronizados; consulta online pendente.')),
      InfoLine('Framework', project.framework), InfoLine('Repositório Git', project.repository),
      ListTile(leading: const Icon(Icons.rocket_launch_outlined), title: const Text('Histórico de deploys'), trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => ProjectDeploymentsScreen(app, project)))),
      ListTile(leading: const Icon(Icons.language), title: const Text('Domínios'), trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => DomainsScreen(app, project)))),
      ListTile(leading: const Icon(Icons.key_outlined), title: const Text('Variáveis de ambiente'), trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => EnvironmentScreen(app, project)))),
      ExpansionTile(title: const Text('Informações técnicas'), children: [InfoLine('ID', project.id),
        InfoLine('Atualização do projeto', displayDate(project.updatedAt)),
        for (final e in project.settings.entries) InfoLine(e.key, e.value as String?),
        ListTile(leading: const Icon(Icons.edit_outlined), title: const Text('Editar configurações'), onTap: working ? null : _edit)]),
      ListTile(leading: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.error), title: const Text('Excluir projeto'), onTap: working ? null : _delete),
    ]));
}
