import 'package:flutter/material.dart';
import '../core/controller.dart';
import '../core/models.dart';
import 'common.dart';

class EnvironmentScreen extends StatefulWidget {
  const EnvironmentScreen(this.app, this.project, {super.key});
  final AppController app;
  final Project project;
  @override State<EnvironmentScreen> createState() => _EnvironmentScreenState();
}
class _EnvironmentScreenState extends State<EnvironmentScreen> with OperationState<EnvironmentScreen> {
  @override AppController get app => widget.app;
  List<EnvironmentVariable> variables = [];
  bool loaded = false;
  @override void initState() { super.initState(); WidgetsBinding.instance.addPostFrameCallback((_) => _load()); }
  Future<void> _load() => run(() async { final result = await app.repository.variables(widget.project.id);
    if (mounted) setState(() { variables = result; loaded = true; }); });
  Future<List<String>?> _targets(List<String> initial) async {
    final selected = initial.where((s) => ['production', 'preview', 'development'].contains(s)).toSet();
    return showDialog<List<String>>(context: context, builder: (context) => StatefulBuilder(builder: (context, update) => AlertDialog(
      title: const Text('Ambientes da variável'), content: Column(mainAxisSize: MainAxisSize.min, children: [
        for (final target in ['production', 'preview', 'development']) CheckboxListTile(title: Text(target == 'production' ? 'Production' : target == 'preview' ? 'Preview' : 'Development'),
          value: selected.contains(target), onChanged: (v) => update(() { if (v == true) { selected.add(target); } else { selected.remove(target); } }))]),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(onPressed: selected.isEmpty ? null : () => Navigator.pop(context, selected.toList()), child: const Text('Continuar'))])));
  }
  Future<void> _edit([EnvironmentVariable? variable]) async {
    final input = await fieldsDialog(context, variable == null ? 'Criar variável' : 'Substituir variável', const {
      'key': 'Nome', 'value': 'Novo valor (oculto)', 'branch': 'Branch Preview (opcional)'}, secret: {'value'},
      initial: {'key': variable?.key ?? '', 'branch': variable?.branch ?? ''});
    if (!mounted || input == null) return;
    final key = input['key']!.trim();
    if (!RegExp(r'^[A-Za-z_][A-Za-z0-9_]*$').hasMatch(key) || key.length > 256) {
      input.clear(); feedback(context, 'Informe um nome de variável válido.'); return;
    }
    final targets = await _targets(variable?.targets ?? ['preview']);
    if (!mounted || targets == null) { input.clear(); return; }
    final branch = input['branch']!.trim();
    if (branch.isNotEmpty && (!targets.contains('preview') || targets.length != 1)) {
      input.clear(); feedback(context, 'Uma branch específica exige apenas o ambiente Preview.'); return;
    }
    final production = targets.contains('production') || (variable?.targets.contains('production') ?? false);
    final approved = await confirmAction(context, title: 'Salvar variável?', resource: '$key · ${widget.project.name}', production: production,
      description: 'Ambientes: ${targets.join(', ')}. O novo valor substituirá o anterior. Os próximos deploys usarão a alteração.');
    if (!approved) { input.clear(); return; }
    await run(() async {
      try {
        await app.repository.saveVariable(widget.project.id, id: variable?.id, key: key,
          value: input['value']!, targets: targets, branch: branch);
        variables = await app.repository.variables(widget.project.id); loaded = true;
      } finally { input.clear(); }
    }, success: 'Variável salva.');
  }
  Future<void> _remove(EnvironmentVariable variable) async {
    if (!await confirmAction(context, title: 'Remover variável?', resource: variable.key, destructive: true,
      production: variable.targets.contains('production'), description: 'Remover de ${widget.project.name} (${variable.targets.join(', ')}). Isso pode impedir futuros builds.')) return;
    await run(() async { await app.repository.removeVariable(widget.project.id, variable.id); variables.removeWhere((v) => v.id == variable.id); }, success: 'Variável removida.');
  }
  @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: Text('Variáveis · ${widget.project.name}'), actions: [
    IconButton(tooltip: 'Atualizar', onPressed: working ? null : _load, icon: const Icon(Icons.refresh)),
    IconButton(tooltip: 'Criar variável', onPressed: working ? null : () => _edit(), icon: const Icon(Icons.add))]),
    body: ListView(children: [if (working) const LinearProgressIndicator(),
      if (variables.isEmpty && !working) EmptyView(loaded ? 'Nenhuma variável cadastrada.' : 'A consulta de variáveis exige conexão com a Vercel.'),
      for (final variable in variables) ExpansionTile(title: Text(variable.key), subtitle: Text(variable.targets.join(' · ')),
        leading: const Icon(Icons.lock_outline), children: [const InfoLine('Valor', '•••••••• (não solicitado à API)'),
          InfoLine('Tipo', variable.type), InfoLine('Criada em', displayDate(variable.createdAt)),
          InfoLine('Atualizada em', displayDate(variable.updatedAt)), if (variable.branch != null) InfoLine('Branch', variable.branch),
          Wrap(spacing: 8, children: [TextButton(onPressed: working ? null : () => _edit(variable), child: const Text('Substituir valor')),
            TextButton(onPressed: working ? null : () => _remove(variable), child: const Text('Remover'))])]) ]));
}
