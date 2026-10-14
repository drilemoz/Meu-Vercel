import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/controller.dart';
import 'common.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen(this.app, {this.replacement = false, super.key});
  final AppController app;
  final bool replacement;
  @override State<LoginScreen> createState() => _LoginScreenState();
}
class _LoginScreenState extends State<LoginScreen> with OperationState<LoginScreen> {
  final _token = TextEditingController();
  bool _showToken = false;
  Future<void> _openVercel() async {
    try {
      final uri = Uri.parse('https://vercel.com/dashboard');
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication) && mounted) {
        feedback(context, 'Não foi possível abrir o painel da Vercel.');
      }
    } catch (_) {
      if (mounted) feedback(context, 'Não foi possível abrir o painel da Vercel.');
    }
  }
  Future<void> _pasteToken() async {
    try {
      final value = (await Clipboard.getData(Clipboard.kTextPlain))?.text;
      if (!mounted) return;
      if (value == null || value.trim().isEmpty) {
        feedback(context, 'A área de transferência não contém texto para colar.');
        return;
      }
      _token.value = TextEditingValue(
        text: value.trim(), selection: TextSelection.collapsed(offset: value.trim().length));
      feedback(context, 'Texto colado no campo do token.');
    } catch (_) {
      if (mounted) feedback(context, 'Não foi possível acessar a área de transferência.');
    }
  }
  @override AppController get app => widget.app;
  @override void dispose() { _token.clear(); _token.dispose(); super.dispose(); }
  Future<void> _login() => run(() async {
    await app.login(_token.text); _token.clear();
    if (mounted && widget.replacement && app.signedIn) Navigator.pop(context);
  });
  @override Widget build(BuildContext context) => Scaffold(
    appBar: widget.replacement ? AppBar(title: const Text('Substituir token')) : null,
    body: SafeArea(child: Center(child: SingleChildScrollView(padding: const EdgeInsets.all(24),
      child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 420), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [const Icon(Icons.change_history, size: 52), const SizedBox(height: 20),
          Text('Meu Vercel', textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8), const Text('Gerencie seus projetos e deploys.', textAlign: TextAlign.center),
          const SizedBox(height: 32), TextField(controller: _token, obscureText: !_showToken, autocorrect: false,
            enableSuggestions: false, keyboardType: TextInputType.visiblePassword, autofillHints: const [],
            decoration: InputDecoration(labelText: 'Token pessoal da Vercel', border: const OutlineInputBorder(),
              suffixIcon: Row(mainAxisSize: MainAxisSize.min, children: [
                IconButton(tooltip: _showToken ? 'Ocultar token' : 'Visualizar token',
                  icon: Icon(_showToken ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                  onPressed: () => setState(() => _showToken = !_showToken)),
                IconButton(tooltip: 'Colar token', icon: const Icon(Icons.content_paste_outlined), onPressed: working ? null : _pasteToken),
              ])),
            onSubmitted: (_) { if (!working) _login(); }), const SizedBox(height: 12),
          Row(children: [
            Expanded(child: FilledButton(
              onPressed: working || app.busy ? null : _login,
              child: working
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Validar e entrar', maxLines: 1, overflow: TextOverflow.ellipsis))),
            const SizedBox(width: 8),
            Expanded(child: OutlinedButton.icon(
              onPressed: _openVercel, icon: const Icon(Icons.open_in_new, size: 18),
              label: const Text('Painel Vercel', maxLines: 1, overflow: TextOverflow.ellipsis))),
          ]),
          if (app.error != null) Padding(padding: const EdgeInsets.only(top: 12),
            child: Text(app.error!, style: TextStyle(color: Theme.of(context).colorScheme.error))),
          const SizedBox(height: 18), const Text('Crie um token em vercel.com/account/tokens. Use Colar para inseri-lo e o olho para conferir antes de validar. O token será protegido no Android.',
            style: TextStyle(fontSize: 12)),
        ]))))));
}
