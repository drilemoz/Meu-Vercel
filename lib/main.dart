import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/controller.dart';
import 'core/notifications.dart';
import 'core/storage.dart';
import 'features/common.dart';
import 'features/dashboard.dart';
import 'features/deployments.dart';
import 'features/login.dart';
import 'features/projects.dart';
import 'features/settings.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    final preferences = await SharedPreferences.getInstance();
    final app = AppController(local: LocalData(PreferencesStore(preferences)),
      tokens: SecureTokenStore(), alerts: LocalDeployAlerts());
    runApp(MeuVercelApp(app));
    unawaited(app.initialize());
  } catch (_) {
    runApp(MaterialApp(theme: ThemeData(useMaterial3: true), home: Scaffold(body: Center(child: Column(
      mainAxisSize: MainAxisSize.min, children: [const Text('Não foi possível abrir o armazenamento local.'),
        TextButton(onPressed: main, child: const Text('Tentar novamente'))])))));
  }
}
class MeuVercelApp extends StatefulWidget {
  const MeuVercelApp(this.app, {super.key});
  final AppController app;
  @override State<MeuVercelApp> createState() => _MeuVercelAppState();
}
class _MeuVercelAppState extends State<MeuVercelApp> with WidgetsBindingObserver {
  final _navigator = GlobalKey<NavigatorState>();
  @override void initState() { super.initState(); WidgetsBinding.instance.addObserver(this); widget.app.addListener(_session); }
  void _session() {
    if (!widget.app.signedIn && !widget.app.starting) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _navigator.currentState?.popUntil((route) => route.isFirst));
    }
  }
  @override void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && widget.app.prefs.autoSync) unawaited(widget.app.sync());
  }
  @override void dispose() { widget.app.removeListener(_session); WidgetsBinding.instance.removeObserver(this); super.dispose(); }
  @override Widget build(BuildContext context) => AnimatedBuilder(animation: widget.app, builder: (context, _) => MaterialApp(
    navigatorKey: _navigator, title: 'Meu Vercel', debugShowCheckedModeBanner: false,
    locale: const Locale('pt', 'BR'), supportedLocales: const [Locale('pt', 'BR')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    themeMode: widget.app.prefs.theme == 'amoled' ? ThemeMode.dark : widget.app.prefs.theme == 'light' ? ThemeMode.light : ThemeMode.system,
    theme: ThemeData(useMaterial3: true, colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF4055A8), brightness: Brightness.light),
      scaffoldBackgroundColor: Colors.white, appBarTheme: const AppBarTheme(backgroundColor: Colors.white),
      visualDensity: VisualDensity.compact, navigationBarTheme: const NavigationBarThemeData(height: 64, backgroundColor: Colors.white)),
    darkTheme: ThemeData(useMaterial3: true, colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF9BADFF), brightness: Brightness.dark)
      .copyWith(surface: Colors.black), scaffoldBackgroundColor: Colors.black,
      appBarTheme: const AppBarTheme(backgroundColor: Colors.black), visualDensity: VisualDensity.compact,
      navigationBarTheme: const NavigationBarThemeData(height: 64, backgroundColor: Colors.black)),
    home: widget.app.starting ? const Scaffold(body: Center(child: CircularProgressIndicator()))
      : widget.app.signedIn ? AppShell(widget.app) : LoginScreen(widget.app)));
}
class AppShell extends StatefulWidget {
  const AppShell(this.app, {super.key});
  final AppController app;
  @override State<AppShell> createState() => _AppShellState();
}
class _AppShellState extends State<AppShell> {
  int index = 0;
  @override Widget build(BuildContext context) {
    final app = widget.app;
    return Scaffold(appBar: AppBar(title: const Text('Meu Vercel'), actions: [
      PopupMenuButton<String>(tooltip: 'Alternar conta ou equipe', initialValue: app.teamId ?? 'personal',
        enabled: !app.busy && app.pendingOperations == 0, icon: const Icon(Icons.manage_accounts_outlined), onSelected: (id) async {
          try { await app.selectTeam(id == 'personal' ? null : id); } catch (e) { await app.failure(e); }
        }, itemBuilder: (_) => [const PopupMenuItem(value: 'personal', child: Text('Conta pessoal')),
          for (final team in app.teams) PopupMenuItem(value: team.id, child: Text(team.name))]),
      IconButton(tooltip: 'Atualizar dados', onPressed: app.busy ? null : () => app.sync(force: true), icon: const Icon(Icons.refresh)),
    ]), body: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 900), child: Column(children: [
      if (app.busy) const LinearProgressIndicator(minHeight: 2),
      Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4), child: Row(children: [
        Icon(app.stale ? Icons.history : Icons.check_circle_outline, size: 14), const SizedBox(width: 6),
        Expanded(child: Text('${app.stale ? 'Dados antigos · ' : ''}${displayDate(app.syncedAt)}', style: Theme.of(context).textTheme.bodySmall))])),
      if (app.error != null) Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Text(app.error!, style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12))),
      Expanded(child: IndexedStack(index: index, children: [DashboardScreen(app), ProjectsScreen(app), DeploymentsScreen(app), SettingsScreen(app)])),
    ]))), bottomNavigationBar: NavigationBar(selectedIndex: index, onDestinationSelected: (i) => setState(() => index = i),
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow, destinations: const [
        NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Início'),
        NavigationDestination(icon: Icon(Icons.folder_outlined), selectedIcon: Icon(Icons.folder), label: 'Projetos'),
        NavigationDestination(icon: Icon(Icons.rocket_launch_outlined), selectedIcon: Icon(Icons.rocket_launch), label: 'Deploys'),
        NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: 'Ajustes') ]));
  }
}
