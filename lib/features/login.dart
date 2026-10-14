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
    final uri = Uri.parse('https://vercel.com/dashboard');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication) && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Não foi possível abrir o painel da Vercel.')));
    }
  }
  Future<void> _copyToken() async {
    if (_token.text.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: _token.text));
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Token copiado. A área de transferência pode ser acessada por outros aplicativos.')));
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
                IconButton(tooltip: 'Copiar token', icon: const Icon(Icons.copy_outlined), onPressed: _copyToken),
              ])),
            onSubmitted: (_) { if (!working) _login(); }), const SizedBox(height: 12),
          FilledButton(onPressed: working || app.busy ? null : _login,
            child: working ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Validar e entrar')),
          if (app.error != null) Padding(padding: const EdgeInsets.only(top: 12), child: Text(app.error!, style: TextStyle(color: Theme.of(context).colorScheme.error))),
          const SizedBox(height: 14), OutlinedButton.icon(onPressed: _openVercel,
            icon: const Icon(Icons.open_in_new), label: const Text('Abrir painel da Vercel')),
          const SizedBox(height: 18), const Text('Crie um token em vercel.com/account/tokens. Ele será validado pela API oficial e protegido no Android.',
            style: TextStyle(fontSize: 12)),
        ]))))));
}
