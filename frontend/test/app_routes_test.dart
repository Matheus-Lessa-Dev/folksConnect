import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/app.dart';
import 'package:frontend/core/widgets/folks_navigation.dart';
import 'package:frontend/features/auth/login_screen.dart';
import 'package:frontend/features/kanban/kanban_screen.dart';
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
    expect(find.byType(KanbanScreen), findsOneWidget);
    expect(_router(tester).routeInformationProvider.value.uri.path, '/kanban');
  });

  for (final entry in {
    '/kanban': KanbanScreen,
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
    expect(find.byType(KanbanScreen), findsOneWidget);
    expect(_router(tester).routeInformationProvider.value.uri.path, '/kanban');
  });
}
