import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../core/backup.dart';
import '../core/controller.dart';
import '../core/version.dart';
import 'common.dart';
import 'login.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen(this.app, {super.key});
  final AppController app;
  @override State<SettingsScreen> createState() => _SettingsScreenState();
}
class _SettingsScreenState extends State<SettingsScreen> with OperationState<SettingsScreen> {
  @override AppController get app => widget.app;
  Future<void> _export() => run(() async {
    final content = BackupCodec().encode(app.prefs);
    final result = await FilePicker.platform.saveFile(dialogTitle: 'Exportar backup', fileName: 'Meu-Vercel-backup.json',
      type: FileType.custom, allowedExtensions: ['json'], bytes: utf8.encode(content));
    if (result != null && mounted) feedback(context, 'Backup exportado sem tokens, cache ou valores secretos.');
  });
  Future<void> _import() => run(() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['json'], withData: false);
    if (result == null) return;
    final file = result.files.single;
    if (file.size > 1024 * 1024 || file.path == null) throw const FormatException('Backup inválido ou maior que 1 MB.');
    final bytes = await File(file.path!).openRead(0, 1024 * 1024 + 1)
      .fold<List<int>>(<int>[], (all, chunk) => all..addAll(chunk));
    final prefs = BackupCodec().decode(utf8.decode(bytes));
    if (!mounted) return;
    if (!await confirmAction(context, title: 'Restaurar backup?', resource: file.name,
      description: 'As preferências e os favoritos atuais serão substituídos. O token e os dados da Vercel serão preservados.')) return;
    // Importing a backup never bypasses the notification permission prompt.
    var approved = prefs;
    if (prefs.notifyFailure || prefs.notifySuccess) {
      if (!await app.alerts.requestPermission()) approved = prefs.copyWith(notifyFailure: false, notifySuccess: false);
    }
    await app.savePreferences(approved);
    if (mounted) feedback(context, 'Backup validado e restaurado.');
  });
  Future<void> _alert(bool value, bool failure) => run(() async {
    if (value && !await app.alerts.requestPermission()) {
      if (mounted) feedback(context, 'Permissão de notificações não concedida.'); return;
    }
    await app.savePreferences(failure ? app.prefs.copyWith(notifyFailure: value) : app.prefs.copyWith(notifySuccess: value));
  });
  Future<void> _logout() async {
    if (!await confirmAction(context, title: 'Encerrar sessão?', resource: app.account?.name ?? 'Conta ativa',
      description: 'O token e o cache de contas serão removidos deste aparelho. Preferências e favoritos serão preservados.')) return;
    await run(app.logout);
  }
  @override Widget build(BuildContext context) => ListView(children: [if (working) const LinearProgressIndicator(),
    const SectionLabel('Conta'), InfoLine('Nome', app.account?.name), if (app.account?.email != null) InfoLine('E-mail', app.account!.email),
    ListTile(leading: const Icon(Icons.key), title: const Text('Substituir token'), onTap: working ? null : () => Navigator.push(context,
      MaterialPageRoute<void>(builder: (_) => LoginScreen(app, replacement: true)))),
    ListTile(leading: const Icon(Icons.logout), title: const Text('Encerrar sessão'), onTap: working ? null : _logout),
    const SectionLabel('Aparência'), Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: DropdownButtonFormField<String>(
      initialValue: app.prefs.theme, key: ValueKey(app.prefs.theme), decoration: const InputDecoration(labelText: 'Tema'),
      items: const [DropdownMenuItem(value: 'light', child: Text('Claro')), DropdownMenuItem(value: 'amoled', child: Text('AMOLED')),
        DropdownMenuItem(value: 'system', child: Text('Seguir o sistema'))], onChanged: working ? null : (value) => run(() => app.savePreferences(app.prefs.copyWith(theme: value))))),
    const SectionLabel('Sincronização'), SwitchListTile(title: const Text('Atualizar ao abrir'), value: app.prefs.autoSync,
      onChanged: working ? null : (v) => run(() => app.savePreferences(app.prefs.copyWith(autoSync: v)))),
    InfoLine('Última sincronização', displayDate(app.syncedAt)),
    const SectionLabel('Alertas opcionais'), SwitchListTile(title: const Text('Falha de deploy'), value: app.prefs.notifyFailure,
      onChanged: working ? null : (v) => _alert(v, true)), SwitchListTile(title: const Text('Conclusão de deploy'), value: app.prefs.notifySuccess,
      onChanged: working ? null : (v) => _alert(v, false)),
    const Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('Alertas são gerados por mudanças observadas ao sincronizar. Sem monitoramento contínuo em segundo plano.', style: TextStyle(fontSize: 12))),
    const SectionLabel('Backup local'), ListTile(leading: const Icon(Icons.upload_file_outlined), title: const Text('Exportar backup'), onTap: working ? null : _export),
    ListTile(leading: const Icon(Icons.restore), title: const Text('Importar backup'), onTap: working ? null : _import),
    ExpansionTile(title: const Text('Novidades · $appVersion'), children: [for (final highlight in releaseHighlights) ListTile(dense: true, title: Text(highlight))]),
    ExpansionTile(title: const Text('Sobre e informações técnicas'), children: [const InfoLine('Versão', '$appVersion ($appVersionCode)'),
      const InfoLine('Pacote Android', applicationId), const InfoLine('API', 'https://api.vercel.com'),
      const InfoLine('Integração GitHub', 'Arquitetura preparada; autenticação e ações GitHub ainda não implementadas.'),
      const InfoLine('Limitações', 'Permissões, planos e limites da Vercel se aplicam. Aplicativo independente, sem vínculo oficial com a Vercel.')]),
    const SizedBox(height: 24),
  ]);
}
