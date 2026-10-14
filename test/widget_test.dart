import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meu_vercel/core/controller.dart';
import 'package:meu_vercel/core/storage.dart';
import 'package:meu_vercel/features/deployments.dart';
import 'package:meu_vercel/main.dart';
import 'support.dart';

Future<AppController> cachedApp(FakeAdapter adapter) async {
  final local = LocalData(MemoryStore()); await local.savePreferences(const Preferences(autoSync: false));
  await local.saveSession('user_fixture', null); await local.saveCache('user_fixture:personal', fixtureSnapshot());
  final tokens = MemoryTokens()..value = 'TEST_ONLY_TOKEN_PLACEHOLDER';
  final app = AppController(local: local, tokens: tokens, alerts: NoAlerts(), apiFactory: (_) => fakeApi(adapter));
  await app.initialize(); return app;
}
void main() {
  testWidgets('login em português e token oculto', (tester) async {
    final app = AppController(local: LocalData(MemoryStore()), tokens: MemoryTokens(), alerts: NoAlerts());
    await app.initialize(); await tester.pumpWidget(MeuVercelApp(app));
    expect(find.text('Validar e entrar'), findsOneWidget);
    expect(find.text('Painel Vercel'), findsOneWidget);
    expect(find.byTooltip('Colar token'), findsOneWidget);
    expect(find.byTooltip('Copiar token'), findsNothing);
    expect(find.byTooltip('Visualizar token'), findsOneWidget);
    final field = tester.widget<TextField>(find.byType(TextField)); expect(field.obscureText, true);
    await tester.pumpWidget(const SizedBox()); app.dispose();
  });
  testWidgets('colar substitui o conteúdo do token sem deixá-lo visível', (tester) async {
    final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.getData') return {'text': '  TEST_ONLY_TOKEN_PLACEHOLDER  '};
      return null;
    });
    addTearDown(() => messenger.setMockMethodCallHandler(SystemChannels.platform, null));
    final app = AppController(local: LocalData(MemoryStore()), tokens: MemoryTokens(), alerts: NoAlerts());
    await app.initialize();
    await tester.pumpWidget(MeuVercelApp(app));
    await tester.tap(find.byTooltip('Colar token'));
    await tester.pumpAndSettle();
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller!.text, 'TEST_ONLY_TOKEN_PLACEHOLDER');
    expect(field.obscureText, true);
    await tester.tap(find.byTooltip('Visualizar token'));
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(find.byType(TextField)).obscureText, false);
    await tester.pumpWidget(const SizedBox()); app.dispose();
  });
  testWidgets('navegação principal permite ver cache, projetos, deploys e ajustes', (tester) async {
    final app = await cachedApp(FakeAdapter((_) async => response({})));
    await tester.pumpWidget(MeuVercelApp(app)); await tester.pumpAndSettle();
    expect(find.textContaining('Dados antigos'), findsOneWidget);
    await tester.tap(find.text('Projetos')); await tester.pumpAndSettle();
    expect(find.text('projeto-teste'), findsOneWidget);
    await tester.tap(find.text('Deploys')); await tester.pumpAndSettle(); expect(find.text('Concluído'), findsOneWidget);
    await tester.tap(find.text('Ajustes')); await tester.pumpAndSettle(); expect(find.text('Substituir token'), findsOneWidget);
    await tester.pumpWidget(const SizedBox()); app.dispose();
  });
  testWidgets('AMOLED usa fundo preto verdadeiro', (tester) async {
    final app = await cachedApp(FakeAdapter((_) async => response({})));
    await app.savePreferences(app.prefs.copyWith(theme: 'amoled'));
    await tester.pumpWidget(MeuVercelApp(app)); await tester.pumpAndSettle();
    final context = tester.element(find.byType(AppShell)); expect(Theme.of(context).scaffoldBackgroundColor, const Color(0xFF000000));
    await tester.pumpWidget(const SizedBox()); app.dispose();
  });
  testWidgets('redeploy Production exige confirmação e cancelar não escreve API', (tester) async {
    final adapter = FakeAdapter((_) async => response({'id': 'dpl_fixture', 'name': 'projeto-teste', 'readyState': 'READY'}));
    final app = await cachedApp(adapter);
    await tester.pumpWidget(MaterialApp(home: DeploymentScreen(app, fixtureDeployment))); await tester.pumpAndSettle();
    await tester.tap(find.text('Novo deploy')); await tester.pumpAndSettle();
    await tester.tap(find.text('Production')); await tester.pumpAndSettle();
    expect(find.textContaining('pode alterar Production'), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, 'Cancelar')); await tester.pumpAndSettle();
    expect(adapter.requests.where((r) => r.method != 'GET'), isEmpty);
    await tester.pumpWidget(const SizedBox()); app.dispose();
  });
}
