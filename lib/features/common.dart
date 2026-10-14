import 'package:flutter/material.dart';
import '../core/controller.dart';
import '../core/errors.dart';
import '../core/models.dart';

String displayDate(DateTime? date) {
  if (date == null) return '—';
  final d = date.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(d.day)}/${two(d.month)}/${d.year} ${two(d.hour)}:${two(d.minute)}';
}
String statusLabel(String s) => const {'READY': 'Concluído', 'ERROR': 'Falhou', 'BUILDING': 'Compilando',
  'QUEUED': 'Na fila', 'CANCELED': 'Cancelado', 'INITIALIZING': 'Iniciando'}[s] ?? s;

class StatusBadge extends StatelessWidget {
  const StatusBadge(this.deployment, {super.key});
  final Deployment deployment;
  @override Widget build(BuildContext context) {
    final color = deployment.status == 'ERROR' ? Theme.of(context).colorScheme.error
      : deployment.status == 'READY' ? Colors.green : Theme.of(context).colorScheme.primary;
    return Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.circle, size: 8, color: color),
      const SizedBox(width: 5), Text(statusLabel(deployment.status), style: TextStyle(color: color, fontSize: 12))]);
  }
}
class EmptyView extends StatelessWidget {
  const EmptyView(this.message, {this.icon = Icons.inbox_outlined, super.key});
  final String message;
  final IconData icon;
  @override Widget build(BuildContext context) => Padding(padding: const EdgeInsets.all(24),
    child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 32),
      const SizedBox(height: 10), Text(message, textAlign: TextAlign.center)]));
}
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key});
  final String text;
  @override Widget build(BuildContext context) => Padding(padding: const EdgeInsets.fromLTRB(16, 18, 16, 6),
    child: Text(text, style: Theme.of(context).textTheme.titleSmall));
}
class InfoLine extends StatelessWidget {
  const InfoLine(this.label, this.value, {super.key});
  final String label;
  final String? value;
  @override Widget build(BuildContext context) => ListTile(dense: true, title: Text(label),
    subtitle: SelectableText(value?.isNotEmpty == true ? value! : 'Não informado'));
}
Future<bool> confirmAction(BuildContext context, {required String title, required String resource,
  required String description, bool destructive = false, bool production = false, String? confirmLabel}) async {
  final controller = TextEditingController();
  try {
    return await showDialog<bool>(context: context, builder: (context) => StatefulBuilder(builder: (context, update) => AlertDialog(
      title: Text(title), content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start, children: [Text(resource, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12), Text(description), if (production) ...[const SizedBox(height: 12),
            Text('Esta ação pode alterar Production e afetar usuários.', style: TextStyle(color: Theme.of(context).colorScheme.error))],
          if (destructive) ...[const SizedBox(height: 16), TextField(controller: controller, autocorrect: false,
            decoration: InputDecoration(labelText: 'Digite $resource para confirmar'), onChanged: (_) => update(() {}))]])),
      actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
        FilledButton(onPressed: !destructive || controller.text == resource ? () => Navigator.pop(context, true) : null,
          child: Text(confirmLabel ?? (destructive ? 'Excluir' : 'Confirmar')))])) ) ?? false;
  } finally { controller.dispose(); }
}
void feedback(BuildContext context, String text) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

mixin OperationState<T extends StatefulWidget> on State<T> {
  AppController get app;
  bool working = false;
  Future<void> run(Future<void> Function() action, {String? success}) async {
    if (!mounted || working) return;
    setState(() => working = true);
    app.beginOperation();
    try {
      await action();
      if (mounted && success != null) feedback(context, success);
    } catch (e) {
      await app.failure(e);
      if (mounted) feedback(context, e is ApiFailure ? e.message : 'Não foi possível concluir a operação.');
    } finally { app.endOperation(); if (mounted) setState(() => working = false); }
  }
}
Future<Map<String, String>?> fieldsDialog(BuildContext context, String title,
  Map<String, String> fields, {Set<String> secret = const {}, Map<String, String> initial = const {}}) async {
  final controllers = {for (final key in fields.keys) key: TextEditingController(text: initial[key] ?? '')};
  try {
    return await showDialog<Map<String, String>>(context: context, builder: (context) => AlertDialog(title: Text(title),
      content: SingleChildScrollView(child: SizedBox(width: 380, child: Column(mainAxisSize: MainAxisSize.min,
        children: [for (final entry in fields.entries) Padding(padding: const EdgeInsets.only(bottom: 12),
          child: TextField(controller: controllers[entry.key], obscureText: secret.contains(entry.key),
            autocorrect: false, enableSuggestions: false, maxLength: secret.contains(entry.key) ? 65536 : 2048,
            decoration: InputDecoration(labelText: entry.value, counterText: '')))]))),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(onPressed: () => Navigator.pop(context, {for (final key in fields.keys) key: controllers[key]!.text}), child: const Text('Continuar'))]));
  } finally { for (final c in controllers.values) { c.clear(); c.dispose(); } }
}
