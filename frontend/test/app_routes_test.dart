import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/app.dart';
import 'package:frontend/core/theme/folks_theme.dart';
import 'package:frontend/core/widgets/folks_navigation.dart';
import 'package:frontend/features/auth/login_screen.dart';
import 'package:frontend/features/dashboard/dashboard_screen.dart';
import 'package:frontend/features/home/home_screen.dart';
import 'package:frontend/features/kanban/kanban_controller.dart';
import 'package:frontend/features/kanban/kanban_screen.dart';
import 'package:frontend/features/kanban/task.dart';
import 'package:frontend/features/settings/settings_screen.dart';
import 'package:frontend/features/splash/splash_screen.dart';
import 'package:frontend/features/vacancy_funnel/vacancy_funnel_screen.dart';
import 'package:go_router/go_router.dart';

Future<void> _open(WidgetTester tester, String path) async {
  tester.binding.platformDispatcher.defaultRouteNameTestValue = path;
  addTearDown(tester.binding.platformDispatcher.clearDefaultRouteNameTestValue);
  await tester.binding.setSurfaceSize(const Size(402, 874));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(const FolksConnectApp());
  await tester.pumpAndSettle();
}

Future<void> _signIn(WidgetTester tester) async {
  await tester.enterText(find.byType(TextFormField).at(0), 'joabe@gmail.com');
  await tester.enterText(find.byType(TextFormField).at(1), '12345');
  await tester.tap(find.text('Entrar'));
  await tester.pumpAndSettle();
}

GoRouter _router(WidgetTester tester) =>
    GoRouter.of(tester.element(find.byType(FolksNavigation)));

Future<void> _pushRoute(WidgetTester tester, String path) async {
  await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
    'flutter/navigation',
    const JSONMethodCodec().encodeMethodCall(
      MethodCall('pushRouteInformation', {'location': path}),
    ),
    (_) {},
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('/login abre o formulario diretamente', (tester) async {
    await _open(tester, '/login');
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byType(SplashScreen), findsNothing);
    await _signIn(tester);
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(_router(tester).routeInformationProvider.value.uri.path, '/inicio');
  });

  for (final entry in {
    '/inicio': HomeScreen,
    '/kanban': KanbanScreen,
    '/dashboard': DashboardScreen,
    '/funil-vagas': VacancyFunnelScreen,
    '/configuracoes': SettingsScreen,
  }.entries) {
    testWidgets('${entry.key} retoma a aba solicitada depois do login', (
      tester,
    ) async {
      await _open(tester, entry.key);
      expect(find.byType(LoginScreen), findsOneWidget);
      final router = GoRouter.of(tester.element(find.byType(LoginScreen)));
      expect(router.routeInformationProvider.value.uri.path, '/login');
      expect(
        router.routeInformationProvider.value.uri.queryParameters['redirect'],
        entry.key,
      );
      await _signIn(tester);
      expect(find.byType(entry.value), findsOneWidget);
      expect(router.routeInformationProvider.value.uri.path, entry.key);
      expect(
        tester
            .widget<FolksNavigation>(find.byType(FolksNavigation))
            .selectedRoute,
        entry.key,
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('abas atualizam URL e recebem navegacao pelo historico', (
    tester,
  ) async {
    await _open(tester, '/login');
    await _signIn(tester);
    await tester.tap(find.byTooltip('Kanban'));
    await tester.pumpAndSettle();
    final router = _router(tester);
    final controller = tester
        .widget<KanbanScreen>(find.byType(KanbanScreen))
        .controller;

    await tester.tap(find.byTooltip('Funil de Vagas'));
    await tester.pumpAndSettle();
    expect(find.byType(VacancyFunnelScreen), findsOneWidget);
    expect(router.routeInformationProvider.value.uri.path, '/funil-vagas');

    await tester.tap(find.byTooltip('Configurações'));
    await tester.pumpAndSettle();
    expect(find.byType(SettingsScreen), findsOneWidget);
    expect(router.routeInformationProvider.value.uri.path, '/configuracoes');

    for (final path in ['/funil-vagas', '/kanban', '/configuracoes']) {
      await _pushRoute(tester, path);
      expect(router.routeInformationProvider.value.uri.path, path);
      expect(
        tester
            .widget<FolksNavigation>(find.byType(FolksNavigation))
            .selectedRoute,
        path,
      );
      if (path == '/kanban') {
        expect(
          tester.widget<KanbanScreen>(find.byType(KanbanScreen)).controller,
          same(controller),
        );
      }
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('botao central mostra etapas e entregas do mesmo Kanban', (
    tester,
  ) async {
    await _open(tester, '/login');
    await _signIn(tester);
    final router = _router(tester);
    final controller = tester
        .widget<HomeScreen>(find.byType(HomeScreen))
        .controller;
    final task = controller.tasks.first;

    // O topo do botão fica acima da barra. Essa área também deve aceitar toque.
    await tester.tapAt(
      tester.getTopLeft(find.byTooltip('Dashboard')) + const Offset(31, 12),
    );
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, '/dashboard');
    expect(
      tester.widget<DashboardScreen>(find.byType(DashboardScreen)).controller,
      same(controller),
    );
    expect(find.text('Triagem: 3'), findsOneWidget);
    expect(find.text('Entrevista: 1'), findsOneWidget);
    expect(find.text('0 concluídas no total'), findsOneWidget);

    controller.filterBy('Financeiro');
    controller.advance(task.id, RecruitmentStage.interview, task.assignee);
    await tester.pumpAndSettle();
    expect(find.text('Triagem: 2'), findsOneWidget);
    expect(find.text('Entrevista: 2'), findsOneWidget);
    controller.update(
      controller.tasks.first.copyWith(status: BoardStatus.done),
    );
    await tester.pumpAndSettle();
    expect(find.text('Entrevista: 1'), findsOneWidget);
    expect(find.text('1 concluídas no total'), findsOneWidget);
    expect(find.text('No prazo: 1'), findsOneWidget);

    controller.update(
      controller.tasks.first.copyWith(status: BoardStatus.todo),
    );
    await tester.pumpAndSettle();
    expect(find.text('Entrevista: 2'), findsOneWidget);
    expect(find.text('0 concluídas no total'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final size in [const Size(375, 812), const Size(812, 375)]) {
    testWidgets('dashboard comporta texto ampliado em $size', (tester) async {
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final controller = KanbanController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        MaterialApp(
          theme: FolksTheme.kanban,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(2)),
            child: child!,
          ),
          home: DashboardScreen(controller: controller),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('Entregas'), 150);
      expect(find.text('Entregas'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('sair impede reabrir uma aba pelo historico sem login', (
    tester,
  ) async {
    await _open(tester, '/funil-vagas');
    await _signIn(tester);
    await tester.tap(find.byTooltip('Sair'));
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);

    await _pushRoute(tester, '/configuracoes');
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byType(SettingsScreen), findsNothing);
    await _signIn(tester);
    expect(find.byType(SettingsScreen), findsOneWidget);
  });

  testWidgets('rotas desconhecidas e retorno externo usam destinos internos', (
    tester,
  ) async {
    await _open(tester, '/nao-existe');
    expect(find.byType(LoginScreen), findsOneWidget);
    await _pushRoute(tester, '/login?redirect=https%3A%2F%2Fexample.com');
    await _signIn(tester);
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(_router(tester).routeInformationProvider.value.uri.path, '/inicio');
  });

  testWidgets(
    'início exibe as três pendências recentes e abre as abas existentes',
    (tester) async {
      await _open(tester, '/login');
      await _signIn(tester);
      final home = tester.widget<HomeScreen>(find.byType(HomeScreen));
      final controller = home.controller;
      expect(find.text('Olá, ---!'), findsOneWidget);
      final first = controller.tasks.first;
      final recent = controller.tasks.last;
      expect(find.text(first.title), findsNothing);
      expect(find.text(recent.title), findsOneWidget);
      controller.filterBy('Financeiro');
      await tester.pumpAndSettle();
      expect(find.text(recent.title), findsOneWidget);
      await tester.tap(find.text(recent.title));
      await tester.pumpAndSettle();
      expect(
        tester.widget<KanbanScreen>(find.byType(KanbanScreen)).controller,
        same(controller),
      );

      await tester.tap(find.byTooltip('Início'));
      await tester.pumpAndSettle();
      controller.update(recent.copyWith(status: BoardStatus.done));
      await tester.pumpAndSettle();
      expect(find.text(recent.title), findsNothing);
      await tester.scrollUntilVisible(find.text(first.title), 150);
      expect(find.text(first.title), findsOneWidget);

      final performance = find.text('Desempenho');
      await tester.scrollUntilVisible(performance, 150);
      await tester.tap(performance);
      await tester.pumpAndSettle();
      expect(find.byType(HomeScreen), findsOneWidget);
      await tester.tap(find.text('Funil de Vagas'));
      await tester.pumpAndSettle();
      expect(find.byType(VacancyFunnelScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('início comporta texto ampliado em tela estreita', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(375, 667));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final controller = KanbanController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: FolksTheme.kanban,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(2)),
          child: child!,
        ),
        home: HomeScreen(controller: controller, userName: 'Ana'),
      ),
    );
    await tester.scrollUntilVisible(find.text('Desempenho'), 200);
    expect(tester.takeException(), isNull);
  });
}
