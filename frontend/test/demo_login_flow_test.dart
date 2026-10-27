import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/app.dart';
import 'package:frontend/core/theme/folks_theme.dart';
import 'package:frontend/features/auth/authentication_service.dart';
import 'package:frontend/features/auth/login_screen.dart';
import 'package:frontend/features/kanban/kanban_controller.dart';
import 'package:frontend/features/kanban/kanban_screen.dart';
import 'package:frontend/features/splash/splash_screen.dart';
import 'package:frontend/shared/widgets/folks_logo.dart';

Future<void> _openLogin(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(402, 874));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(const FolksConnectApp());
  await tester.runAsync(
    () => precacheImage(
      const AssetImage(FolksLogo.asset),
      tester.element(find.byType(SplashScreen)),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 901));
  await tester.pumpAndSettle();
}

void main() {
  test(
    'demo aceita somente a conta solicitada e preserva a senha exata',
    () async {
      const service = DemoAuthenticationService();
      await service.signIn(username: 'joabe@gmail.com', password: '12345');
      for (final credentials in [
        (username: 'outro@gmail.com', password: '12345'),
        (username: 'joabe@gmail.com', password: 'errada'),
        (username: 'joabe@gmail.com', password: '12345 '),
        (username: '', password: ''),
      ]) {
        await expectLater(
          service.signIn(
            username: credentials.username,
            password: credentials.password,
          ),
          throwsA(isA<InvalidCredentials>()),
        );
      }
    },
  );

  testWidgets(
    'login correto abre Kanban e sair retorna a um formulario limpo',
    (tester) async {
      await _openLogin(tester);
      await tester.enterText(
        find.byType(TextFormField).at(0),
        'joabe@gmail.com',
      );
      await tester.enterText(find.byType(TextFormField).at(1), '12345');
      await tester.tap(find.text('Entrar'));
      await tester.pumpAndSettle();

      expect(find.byType(KanbanScreen), findsOneWidget);
      expect(find.text('Quadro de Tarefas'), findsOneWidget);
      expect(find.byType(LoginScreen), findsNothing);
      expect(
        Navigator.of(tester.element(find.byType(KanbanScreen))).canPop(),
        isFalse,
      );

      await tester.tap(find.byTooltip('Sair'));
      await tester.pumpAndSettle();
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.byType(KanbanScreen), findsNothing);
      for (final field in tester.widgetList<EditableText>(
        find.byType(EditableText),
      )) {
        expect(field.controller.text, isEmpty);
      }
    },
  );

  testWidgets('senha incorreta mantem login e informa erro', (tester) async {
    await _openLogin(tester);
    await tester.enterText(find.byType(TextFormField).at(0), 'joabe@gmail.com');
    await tester.enterText(find.byType(TextFormField).at(1), 'errada');
    await tester.tap(find.text('Entrar'));
    await tester.pumpAndSettle();
    expect(find.text('E-mail ou senha incorretos.'), findsOneWidget);
    expect(find.byType(KanbanScreen), findsNothing);
    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets(
    'Kanban alterna entre quadro e lista e suporta paisagem com texto ampliado',
    (tester) async {
      final controller = KanbanController(tasks: []);
      addTearDown(controller.dispose);
      await tester.binding.setSurfaceSize(const Size(844, 390));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(
          theme: FolksTheme.dark,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(2)),
            child: child!,
          ),
          home: KanbanScreen(controller: controller, onSignOut: () {}),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Lista'));
      await tester.pumpAndSettle();
      expect(find.text('Nenhuma tarefa cadastrada.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
