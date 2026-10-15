import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meu_vercel/core/controller.dart';
import 'package:meu_vercel/core/storage.dart';
import 'package:meu_vercel/features/deployments.dart';
import 'package:meu_vercel/features/common.dart';
import 'package:meu_vercel/core/models.dart';
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
    expect(field.autocorrect, isFalse);
    expect(field.enableSuggestions, isFalse);
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
  testWidgets('controle de produção não é oferecido em status não READY', (tester) async {
    final adapter = FakeAdapter((_) async => response({'id': 'dpl_fixture',
      'name': 'projeto-teste', 'projectId': 'prj_fixture', 'readyState': 'BUILDING', 'target': 'preview'}));
    final app = await cachedApp(adapter);
    await tester.pumpWidget(MaterialApp(home: DeploymentScreen(app, fixtureDeployment)));
    await tester.pumpAndSettle();
    expect(find.text('Promover Preview para Production'), findsNothing);
    expect(find.text('Rollback para este deploy'), findsNothing);
    await tester.pumpWidget(const SizedBox()); app.dispose();
  });
  testWidgets('Preview READY oferece ação com confirmação de projeto, cancelar não muda produção', (tester) async {
    final adapter = FakeAdapter((options) async => response(
      options.path.startsWith('/v9/projects/')
        ? {'id': 'prj_fixture', 'name': 'projeto-teste'}
        : {'id': 'dpl_fixture', 'name': 'projeto-teste', 'projectId': 'prj_fixture',
            'readyState': 'READY', 'target': 'preview'}));
    final app = await cachedApp(adapter);
    await tester.pumpWidget(MaterialApp(home: DeploymentScreen(app, fixtureDeployment)));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Promover Preview para Production'), 200,
      scrollable: find.byType(Scrollable).last);
    await tester.tap(find.text('Promover Preview para Production')); 
    await tester.pumpAndSettle();
    expect(find.text('Promover Preview para produção?'), findsOneWidget);
    expect(tester.widget<FilledButton>(find.widgetWithText(FilledButton,
      'Criar deploy de produção')).onPressed, isNull);
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(adapter.requests.where((r) => r.method == 'POST'), isEmpty);
    await tester.pumpWidget(const SizedBox()); app.dispose();
  });
  testWidgets('confirmação de produção exibe Publicar, não Excluir', (tester) async {
    await tester.pumpWidget(MaterialApp(home: Builder(builder: (context) => Scaffold(
      body: TextButton(onPressed: () async {
        await confirmAction(context, title: 'Publicar?', resource: 'site',
          description: 'Produção', production: true, destructive: true,
          confirmLabel: 'Publicar em produção');
      }, child: const Text('Iniciar'))))));
    await tester.tap(find.text('Iniciar'));
    await tester.pumpAndSettle();
    expect(find.text('Publicar em produção'), findsOneWidget);
    expect(find.text('Excluir'), findsNothing);
    expect(tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Publicar em produção')).onPressed, isNull);
    await tester.enterText(find.byType(TextField), 'site');
    await tester.pumpAndSettle();
    expect(tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Publicar em produção')).onPressed, isNotNull);
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
  testWidgets('confirmação de produção aceita nome e conclui sem descartar controller cedo', (tester) async {
    bool? confirmed;
    await tester.pumpWidget(MaterialApp(home: Builder(builder: (context) => Scaffold(
      body: TextButton(onPressed: () async {
        confirmed = await confirmAction(context, title: 'Publicar?', resource: 'site',
          description: 'Produção', production: true, destructive: true,
          confirmLabel: 'Publicar em produção');
      }, child: const Text('Iniciar'))))));
    await tester.tap(find.text('Iniciar'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'site');
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Publicar em produção'));
    await tester.pumpAndSettle();
    expect(confirmed, isTrue);
    expect(tester.takeException(), isNull);
  });
  testWidgets('formulário devolve valores e libera campos após fechar', (tester) async {
    Map<String, String>? result;
    await tester.pumpWidget(MaterialApp(home: Builder(builder: (context) => Scaffold(
      body: TextButton(onPressed: () async {
        result = await fieldsDialog(context, 'Novo projeto',
          {'name': 'Nome', 'token': 'Token'}, secret: {'token'});
      }, child: const Text('Abrir formulário'))))));
    await tester.tap(find.text('Abrir formulário'));
    await tester.pumpAndSettle();
    final inputs = tester.widgetList<TextField>(find.byType(TextField)).toList();
    expect(inputs.first.autocorrect, isTrue);
    expect(inputs.first.enableSuggestions, isTrue);
    expect(inputs.last.obscureText, isTrue);
    expect(inputs.last.autocorrect, isFalse);
    expect(inputs.last.enableSuggestions, isFalse);
    await tester.enterText(find.byType(TextField).first, 'site');
    await tester.enterText(find.byType(TextField).last, 'temporario');
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();
    expect(result, {'name': 'site', 'token': 'temporario'});
    expect(tester.takeException(), isNull);
  });
  testWidgets('formulários técnicos exibem sugestões sem trocar nomes', (tester) async {
    await tester.pumpWidget(MaterialApp(home: Builder(builder: (context) => Scaffold(
      body: TextButton(onPressed: () => fieldsDialog(context, 'Configuração',
        {'repo': 'Repositório', 'domain': 'Domínio', 'name': 'Nome do projeto'}),
        child: const Text('Abrir'))))));
    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
    final inputs = tester.widgetList<TextField>(find.byType(TextField)).toList();
    expect(inputs.length, 3);
    expect(inputs[0].autocorrect, isFalse);
    expect(inputs[1].autocorrect, isFalse);
    expect(inputs[2].autocorrect, isTrue);
    for (final field in inputs) {
      expect(field.enableSuggestions, isTrue);
    }
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
  testWidgets('busca de projetos permite sugestões do teclado', (tester) async {
    final app = await cachedApp(FakeAdapter((_) async => response({})));
    await tester.pumpWidget(MeuVercelApp(app));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Projetos'));
    await tester.pumpAndSettle();
    final search = tester.widget<TextField>(find.byWidgetPredicate((widget) =>
      widget is TextField && widget.decoration?.hintText == 'Buscar nos projetos carregados'));
    expect(search.autocorrect, isTrue);
    expect(search.enableSuggestions, isTrue);
    await tester.pumpWidget(const SizedBox());
    app.dispose();
  });
  testWidgets('deploy acompanhado alcança READY, oferece copiar e abrir', (tester) async {
    var reads = 0;
    final adapter = FakeAdapter((req) async {
      if (req.uri.path.startsWith('/v13/deployments/')) {
        reads++;
        return response({'id': 'dpl_site', 'name': 'site',
          'readyState': 'READY', 'target': 'preview', 'url': 'site.vercel.app'});
      }
      return response({});
    });
    final app = await cachedApp(adapter);
    await tester.pumpWidget(MaterialApp(home: DeploymentScreen(app,
      const Deployment(id: 'dpl_site', name: 'site', status: 'QUEUED', environment: 'preview'),
      trackOnOpen: true)));
    await tester.pumpAndSettle();
    expect(reads, 1);
    expect(find.text('Concluído'), findsOneWidget);
    expect(find.text('Abrir site'), findsOneWidget);
    expect(find.byTooltip('Copiar URL'), findsOneWidget);
    expect(find.textContaining('A Vercel confirmou READY.'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    app.dispose();
  });

}
