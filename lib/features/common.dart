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
  return await showDialog<bool>(context: context, builder: (_) => _ConfirmActionDialog(
    title: title, resource: resource, description: description,
    destructive: destructive, production: production, confirmLabel: confirmLabel)) ?? false;
}

// Os controladores pertencem ao ciclo de vida da rota do Dialog. Destruí-los
// imediatamente após Navigator.pop deixa o TextField ativo durante a animação
// de saída e causa "TextEditingController was used after being disposed".
class _ConfirmActionDialog extends StatefulWidget {
  const _ConfirmActionDialog({required this.title, required this.resource,
    required this.description, required this.destructive, required this.production,
    required this.confirmLabel});
  final String title, resource, description;
  final bool destructive, production;
  final String? confirmLabel;

  @override State<_ConfirmActionDialog> createState() => _ConfirmActionDialogState();
}

class _ConfirmActionDialogState extends State<_ConfirmActionDialog> {
  final controller = TextEditingController();

  @override void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.title),
    content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(widget.resource, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12), Text(widget.description),
        if (widget.production) ...[const SizedBox(height: 12),
          Text('Esta ação pode alterar Production e afetar usuários.',
            style: TextStyle(color: Theme.of(context).colorScheme.error))],
        if (widget.destructive) ...[const SizedBox(height: 16),
          TextField(controller: controller, autocorrect: false, enableSuggestions: true,
            decoration: InputDecoration(labelText: 'Digite ${widget.resource} para confirmar'),
            onChanged: (_) => setState(() {}))],
      ])),
    actions: [
      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
      FilledButton(onPressed: !widget.destructive || controller.text == widget.resource
        ? () => Navigator.pop(context, true) : null,
        child: Text(widget.confirmLabel ?? (widget.destructive ? 'Excluir' : 'Confirmar'))),
    ],
  );
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
  Map<String, String> fields, {Set<String> secret = const {}, Map<String, String> initial = const {}}) {
  return showDialog<Map<String, String>>(context: context,
    builder: (_) => _FieldsDialog(title: title, fields: fields, secret: secret, initial: initial));
}

// Mesmo cuidado para o formulário: aguardar a remoção da rota antes de limpar
// e descartar os controladores. Nunca retorna referências aos controladores.
class _FieldsDialog extends StatefulWidget {
  const _FieldsDialog({required this.title, required this.fields,
    required this.secret, required this.initial});
  final String title;
  final Map<String, String> fields;
  final Set<String> secret;
  final Map<String, String> initial;

  @override State<_FieldsDialog> createState() => _FieldsDialogState();
}

class _FieldsDialogState extends State<_FieldsDialog> {
  late final Map<String, TextEditingController> controllers;

  @override void initState() {
    super.initState();
    controllers = {
      for (final key in widget.fields.keys)
        key: TextEditingController(text: widget.initial[key] ?? ''),
    };
  }

  @override void dispose() {
    for (final c in controllers.values) {
      c.clear();
      c.dispose();
    }
    super.dispose();
  }

  @override Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.title),
    content: SingleChildScrollView(child: SizedBox(width: 380,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        for (final entry in widget.fields.entries)
          Padding(padding: const EdgeInsets.only(bottom: 12),
            child: TextField(controller: controllers[entry.key],
              obscureText: widget.secret.contains(entry.key),
              // Sugestões do teclado nos campos comuns. Identificadores técnicos
              // podem receber sugestões, mas nunca correção automática.
              autocorrect: !widget.secret.contains(entry.key) &&
                !const {'repo', 'domain', 'branch', 'key', 'framework',
                  'buildCommand', 'installCommand', 'outputDirectory',
                  'rootDirectory'}.contains(entry.key),
              enableSuggestions: !widget.secret.contains(entry.key),
              textCapitalization: TextCapitalization.none,
              maxLength: widget.secret.contains(entry.key) ? 65536 : 2048,
              decoration: InputDecoration(labelText: entry.value, counterText: ''))),
      ]))),
    actions: [
      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
      FilledButton(onPressed: () => Navigator.pop(context,
        {for (final key in widget.fields.keys) key: controllers[key]!.text}),
        child: const Text('Continuar')),
    ],
  );
}
