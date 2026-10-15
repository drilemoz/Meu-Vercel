import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import '../core/controller.dart';
import '../core/models.dart';
import '../core/project_names.dart';
import '../core/static_deploy.dart';
import '../core/android_site_folder.dart';
import '../core/errors.dart';
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
    if (!validProjectName(name)) { feedback(context, 'Use 1 a 100 caracteres: letras minúsculas, números, ponto, _ ou hífen. Evite --- .'); return; }
    if (!await confirmAction(context, title: 'Criar projeto?', resource: name,
      description: 'Criar na conta ${app.activeName}. A API pode exigir permissões ou um plano específico.')) return;
    await run(() async { await app.repository.createProject(name, input['framework']!.trim().isEmpty ? null : input['framework']!.trim());
      await app.sync(force: true); }, success: 'Projeto criado.');
  }
  Future<void> _importGitHub() async {
    final input = await fieldsDialog(context, 'Importar repositório GitHub', {
      'name': 'Nome do projeto na Vercel',
      'repo': 'GitHub: proprietário/repositório ou URL HTTPS',
    });
    if (!mounted || input == null) return;
    final name = input['name']!.trim();
    final repository = input['repo']!.trim();
    if (!validProjectName(name)) {
      feedback(context, 'Nome do projeto inválido. Use apenas minúsculas, números e - _ .');
      return;
    }
    if (!await confirmAction(context, title: 'Importar do GitHub?', resource: name,
      description: 'Conectar $repository à conta ${app.activeName}. A Vercel precisa ter acesso ao repositório por uma integração GitHub já autorizada. Isso pode iniciar deploys automáticos.')) return;
    await run(() async {
      await app.repository.createGitHubProject(name, repository);
      await app.sync(force: true);
    }, success: 'Projeto GitHub conectado. Confira o deploy na Vercel.');
  }
  @override Widget build(BuildContext context) {
    final frameworks = app.projects.map((p) => p.framework ?? 'none').toSet().toList()..sort();
    final selectedFramework = frameworks.contains(framework) ? framework : 'all';
    final projects = app.projects.where((p) => p.name.toLowerCase().contains(query.toLowerCase()) &&
      (!favoritesOnly || app.favorites.contains(p.id)) && (selectedFramework == 'all' || (p.framework ?? 'none') == selectedFramework)).toList();
    projects.sort((a, b) => sort == 'name' ? a.name.compareTo(b.name)
      : (b.updatedAt?.millisecondsSinceEpoch ?? 0).compareTo(a.updatedAt?.millisecondsSinceEpoch ?? 0));
    return Column(children: [Padding(padding: const EdgeInsets.fromLTRB(16, 8, 16, 0), child: TextField(
      autocorrect: true, enableSuggestions: true,
      textCapitalization: TextCapitalization.none,
      decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Buscar nos projetos carregados', border: OutlineInputBorder(), isDense: true),
      onChanged: (value) => setState(() => query = value))),
      Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), child: Wrap(spacing: 8, crossAxisAlignment: WrapCrossAlignment.center,
        children: [FilterChip(label: const Text('Favoritos'), selected: favoritesOnly, onSelected: (v) => setState(() => favoritesOnly = v)),
          DropdownButton<String>(value: sort, items: const [DropdownMenuItem(value: 'name', child: Text('Nome')),
            DropdownMenuItem(value: 'updated', child: Text('Recentes'))], onChanged: (v) => setState(() => sort = v!)),
          DropdownButton<String>(value: selectedFramework, items: [const DropdownMenuItem(value: 'all', child: Text('Todos os frameworks')),
            for (final f in frameworks) DropdownMenuItem(value: f, child: Text(f == 'none' ? 'Não informado' : f))], onChanged: (v) => setState(() => framework = v!)),
          FilledButton.tonalIcon(onPressed: working || app.busy ? null : _create,
            icon: const Icon(Icons.add), label: const Text('Criar projeto')),
          OutlinedButton.icon(onPressed: working || app.busy ? null : _importGitHub,
            icon: const Icon(Icons.code), label: const Text('Importar GitHub'))])),
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
  int uploaded = 0;
  int uploadTotal = 0;
  @override void initState() { super.initState(); project = widget.initial; WidgetsBinding.instance.addPostFrameCallback((_) => _reload()); }
  Future<void> _reload() => run(() async {
    setState(() => current = false);
    final loaded = await app.repository.project(project.id);
    if (mounted) setState(() { project = loaded; current = true; });
  });
  Future<void> _rename() async {
    final input = await fieldsDialog(context, 'Renomear projeto',
      const {'name': 'Novo nome do projeto'}, initial: {'name': project.name});
    if (!mounted || input == null) return;
    final newName = input['name']!.trim();
    if (!validProjectName(newName)) {
      feedback(context, 'Nome inválido: use 1 a 100 caracteres minúsculos, números, ponto, _ ou hífen, sem --- .');
      return;
    }
    if (newName == project.name) return;
    final oldName = project.name;
    if (!await confirmAction(context, title: 'Renomear projeto?', resource: oldName,
      production: true,
      description: 'Alterar o nome de "$oldName" para "$newName" na conta ${app.activeName}. '
        'Links e configurações associados ao nome podem ser afetados.')) return;
    await run(() async {
      await app.repository.renameProject(project.id, newName);
      final updated = await app.repository.project(project.id);
      if (mounted) setState(() { project = updated; current = true; });
      await app.sync(force: true);
    }, success: 'Projeto renomeado.');
  }
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
  bool get _supportsStaticFiles => project.repository == null &&
    (project.framework == null || project.framework == 'other');

  Future<void> _publishFiles() async {
    if (!_supportsStaticFiles) {
      feedback(context, 'Disponível somente em projetos estáticos sem Git/framework.');
      return;
    }
    await run(() async {
      final chosen = await FilePicker.platform.pickFiles(
        type: FileType.any, allowMultiple: true, withData: false);
      if (chosen == null || chosen.files.isEmpty) return;
      if (chosen.files.length > StaticSite.maxFiles) {
        throw const ApiFailure(FailureKind.invalid, 'Selecione no máximo 120 arquivos.');
      }
      final sources = <SiteSource>[];
      var total = 0;
      for (final file in chosen.files) {
        // Multi-file picker supplies only base names, never folder structure.
        StaticSite.checkPath(file.name);
        final path = file.path;
        if (path == null) {
          throw const ApiFailure(FailureKind.invalid, 'Arquivo não acessível. Use a seleção de pasta ou ZIP.');
        }
        final selected = File(path);
        final size = await selected.length();
        if (size > StaticSite.maxSiteBytes - total) {
          throw const ApiFailure(FailureKind.invalid, 'Arquivos ultrapassam 20 MiB.');
        }
        final bytes = await selected.readAsBytes();
        if (bytes.length > StaticSite.maxSiteBytes - total) {
          throw const ApiFailure(FailureKind.invalid, 'Arquivos ultrapassam 20 MiB.');
        }
        total += bytes.length;
        sources.add((path: file.name, bytes: bytes));
      }
      await _startDeployment(StaticSite.prepare(sources));
    });
  }

  Future<void> _publishFolder() async {
    if (!_supportsStaticFiles) {
      feedback(context, 'Disponível somente em projetos estáticos sem Git/framework.');
      return;
    }
    await run(() async {
      final files = await AndroidSiteFolder.pick();
      if (files == null) return;
      await _startDeployment(files);
    });
  }

  Future<void> _publishZip() async {
    if (!_supportsStaticFiles) {
      feedback(context, 'Disponível somente em projetos estáticos sem Git/framework.');
      return;
    }
    await run(() async {
      final chosen = await FilePicker.platform.pickFiles(
        type: FileType.custom, allowedExtensions: ['zip'], withData: false);
      if (chosen == null || chosen.files.isEmpty) return;
      final path = chosen.files.single.path;
      if (path == null) {
        throw const ApiFailure(FailureKind.invalid, 'Não foi possível acessar o ZIP selecionado.');
      }
      final selected = File(path);
      final length = await selected.length();
      if (length <= 0 || length > StaticZip.maxZipBytes) {
        throw const ApiFailure(FailureKind.invalid, 'O ZIP deve ter no máximo 12 MiB.');
      }
      final files = await compute(StaticZip.prepare, await selected.readAsBytes());
      await _startDeployment(files);
    });
  }

  Future<String?> _chooseTarget(List<SiteFile> files) async {
    if (!mounted) return null;
    final totalBytes = files.fold<int>(0, (sum, item) => sum + item.bytes.length);
    final preview = files.take(10).map((item) => item.path).join('\n');
    final more = files.length > 10 ? '\n... e mais ${files.length - 10} arquivos' : '';
    var chosen = 'preview';
    return showDialog<String>(context: context, builder: (dialogContext) =>
      StatefulBuilder(builder: (context, update) => AlertDialog(
        title: const Text('Conferir publicação'),
        content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Projeto: ${project.name}\nConta: ${app.activeName}\n'
              '${files.length} arquivos · ${(totalBytes / 1024).toStringAsFixed(1)} KiB'),
            const SizedBox(height: 12),
            const Text('Arquivos que serão enviados:'),
            SelectableText('$preview$more', style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 16),
            const Text('Ambiente:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(spacing: 8, children: [
              ChoiceChip(label: const Text('Preview'), selected: chosen == 'preview',
                onSelected: (_) => update(() => chosen = 'preview')),
              ChoiceChip(label: const Text('Produção'), selected: chosen == 'production',
                onSelected: (_) => update(() => chosen = 'production')),
            ]),
            const SizedBox(height: 12),
            Text(chosen == 'preview'
              ? 'Cria uma versão de teste, sem substituir o site em produção.'
              : 'ATENÇÃO: uma publicação bem-sucedida em produção pode substituir o site público e afetar visitantes.',
              style: TextStyle(color: chosen == 'production'
                ? Theme.of(context).colorScheme.error : null)),
            const SizedBox(height: 8),
            const Text('Serão enviados arquivos à Vercel. Isso consome internet e pode usar a cota do plano.'),
          ])),
        actions: [TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, chosen), child: const Text('Continuar'))],
      )));
  }

  Future<void> _startDeployment(List<SiteFile> files) async {
    if (!mounted) return;
    final target = await _chooseTarget(files);
    if (!mounted || target == null) return;
    final production = target == 'production';
    final confirmed = await confirmAction(context,
      title: production ? 'Confirmar publicação em PRODUÇÃO?' : 'Criar publicação Preview?',
      resource: project.name,
      destructive: production, production: production,
      confirmLabel: production ? 'Publicar em produção' : 'Enviar Preview',
      description: production
        ? 'Digite exatamente o nome do projeto para autorizar a publicação em produção '
          'na conta ${app.activeName}. Se o deploy ficar READY, os domínios públicos '
          'podem mudar. Não há reversão automática.'
        : 'Enviar os arquivos selecionados para um novo deploy Preview. '
          'O site atual em produção não será substituído.');
    if (!mounted || !confirmed) return;
    try {
      setState(() { uploaded = 0; uploadTotal = files.length; });
      final id = await app.repository.deployStatic(project, files, target: target,
        onProgress: (completed, total) {
          if (mounted) setState(() { uploaded = completed; uploadTotal = total; });
        });
      if (!mounted) return;
      feedback(context, 'Deploy aceito pela Vercel. Acompanhe o status antes de compartilhar.');
      unawaited(app.sync(force: true)); // Refresh lists without delaying status tracking.
      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => DeploymentScreen(
        app, Deployment(id: id, name: project.name, status: 'QUEUED', environment: target, projectId: project.id),
        trackOnOpen: true)));
    } finally {
      if (mounted) setState(() { uploaded = 0; uploadTotal = 0; });
    }
  }
  Future<void> _delete() async {
    if (!await confirmAction(context, title: 'Excluir projeto?', resource: project.name, destructive: true, production: true,
      description: 'O projeto e seus recursos na Vercel serão removidos. Esta operação não pode ser desfeita.')) return;
    await run(() async { await app.repository.deleteProject(project.id); await app.sync(force: true);
      if (mounted) Navigator.pop(context); });
  }
  @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: Text(project.name), actions: [
    IconButton(tooltip: 'Atualizar', onPressed: working ? null : _reload, icon: const Icon(Icons.refresh))]),
    body: ListView(children: [if (working) LinearProgressIndicator(
      value: uploadTotal > 0 ? uploaded / uploadTotal : null),
      if (uploadTotal > 0) ListTile(title: Text('Enviando $uploaded de $uploadTotal arquivos')),
      if (!current) const ListTile(dense: true,
      leading: Icon(Icons.history), title: Text('Dados previamente sincronizados; consulta online pendente.')),
      InfoLine('Framework', project.framework), InfoLine('Repositório Git', project.repository),
      ListTile(leading: const Icon(Icons.drive_file_rename_outline), title: const Text('Renomear projeto'),
        subtitle: const Text('Alterar o nome na Vercel'), onTap: working || app.busy ? null : _rename),
      const SectionLabel('Publicar site estático (sem GitHub)'),
      ListTile(leading: const Icon(Icons.folder_open_outlined), title: const Text('Selecionar pasta do site'),
        subtitle: const Text('Mantém subpastas (css, js, imagens). Precisa ter index.html na raiz.'),
        onTap: working || app.busy || !_supportsStaticFiles ? null : _publishFolder),
      ListTile(leading: const Icon(Icons.library_add_outlined), title: const Text('Selecionar arquivos'),
        subtitle: const Text('Vários arquivos da raiz, sem subpastas. Inclua index.html.'),
        onTap: working || app.busy || !_supportsStaticFiles ? null : _publishFiles),
      ListTile(leading: const Icon(Icons.upload_file_outlined), title: const Text('Selecionar ZIP'),
        subtitle: const Text('Alternativa para sites estáticos com pastas e index.html.'),
        onTap: working || app.busy || !_supportsStaticFiles ? null : _publishZip),
      const Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8), child:
        Text('Após selecionar, escolha Preview ou Produção. Produção exige digitar o nome do projeto. '
          'Até 120 arquivos e 20 MiB de conteúdo; ZIP de até 12 MiB.')),
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
