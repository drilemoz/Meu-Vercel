import 'package:flutter/material.dart';
import '../core/controller.dart';
import '../core/models.dart';
import 'common.dart';
import 'deployments.dart';
import 'projects.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen(this.app, {super.key});
  final AppController app;
  @override Widget build(BuildContext context) {
    final favorites = app.projects.where((p) => app.favorites.contains(p.id)).toList();
    final failures = app.deployments.where((d) => d.status == 'ERROR').length;
    return RefreshIndicator(onRefresh: () => app.sync(force: true), child: ListView(
      physics: const AlwaysScrollableScrollPhysics(), children: [
        ListTile(title: Text(app.activeName, style: Theme.of(context).textTheme.titleLarge), subtitle: Text(app.teamId == null ? 'Conta pessoal' : 'Equipe')),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Wrap(spacing: 10, runSpacing: 8, children: [
          Chip(avatar: const Icon(Icons.folder_outlined, size: 18), label: Text('${app.projects.length}${app.projectCursor == null ? '' : '+'} projetos')),
          Chip(avatar: const Icon(Icons.error_outline, size: 18), label: Text('$failures falhas recentes'))])),
        const SectionLabel('Favoritos'), if (favorites.isEmpty) const EmptyView('Favorite projetos para encontrá-los aqui.', icon: Icons.star_border),
        for (final p in favorites.take(8)) ProjectTile(app, p),
        const SectionLabel('Deploys recentes'), if (app.deployments.isEmpty) const EmptyView('Nenhum deploy sincronizado.'),
        for (final d in app.deployments.take(8)) DeploymentTile(app, d),
        const SizedBox(height: 16),
      ]));
  }
}
class ProjectTile extends StatelessWidget {
  const ProjectTile(this.app, this.project, {super.key});
  final AppController app;
  final Project project;
  @override Widget build(BuildContext context) => ListTile(dense: true, leading: const Icon(Icons.folder_outlined),
    title: Text(project.name), subtitle: Text(project.framework ?? 'Framework não informado'),
    onTap: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => ProjectScreen(app, project))),
    trailing: IconButton(tooltip: app.favorites.contains(project.id) ? 'Remover dos favoritos' : 'Favoritar',
      icon: Icon(app.favorites.contains(project.id) ? Icons.star : Icons.star_border),
      onPressed: () async { try { await app.toggleFavorite(project.id); } catch (_) { if (context.mounted) feedback(context, 'Não foi possível salvar o favorito.'); } }));
}
class DeploymentTile extends StatelessWidget {
  const DeploymentTile(this.app, this.deployment, {super.key});
  final AppController app;
  final Deployment deployment;
  @override Widget build(BuildContext context) => ListTile(dense: true,
    title: Row(children: [Expanded(child: Text(deployment.name, overflow: TextOverflow.ellipsis)), StatusBadge(deployment)]),
    subtitle: Text('${deployment.environmentLabel} · ${displayDate(deployment.createdAt)}'),
    leading: Icon(deployment.production ? Icons.public : Icons.science_outlined, size: 22),
    onTap: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => DeploymentScreen(app, deployment))));
}
