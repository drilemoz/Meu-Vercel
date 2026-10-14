import 'package:flutter/material.dart';
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
          const SizedBox(height: 32), TextField(controller: _token, obscureText: true, autocorrect: false,
            enableSuggestions: false, keyboardType: TextInputType.visiblePassword, autofillHints: const [],
            decoration: const InputDecoration(labelText: 'Token pessoal da Vercel', border: OutlineInputBorder()),
            onSubmitted: (_) { if (!working) _login(); }), const SizedBox(height: 12),
          FilledButton(onPressed: working || app.busy ? null : _login,
            child: working ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Validar e entrar')),
          if (app.error != null) Padding(padding: const EdgeInsets.only(top: 12), child: Text(app.error!, style: TextStyle(color: Theme.of(context).colorScheme.error))),
          const SizedBox(height: 18), const Text('Crie um token em vercel.com/account/tokens. Ele será validado pela API oficial e protegido no Android.',
            style: TextStyle(fontSize: 12)),
        ]))))));
}
