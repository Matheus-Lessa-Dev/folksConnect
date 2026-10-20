import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/theme/folks_theme.dart';
import 'package:frontend/features/auth/authentication_service.dart';
import 'package:frontend/features/auth/login_screen.dart';
import 'package:frontend/shared/widgets/folks_logo.dart';

class _PendingAuthentication implements AuthenticationService {
  final result = Completer<void>();
  int calls = 0;
  String? username;
  String? password;

  @override
  Future<void> signIn({required String username, required String password}) {
    calls++;
    this.username = username;
    this.password = password;
    return result.future;
  }
}

Future<void> _render(
  WidgetTester tester, {
  AuthenticationService? service,
}) async {
  await tester.binding.setSurfaceSize(const Size(402, 874));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MaterialApp(
      theme: FolksTheme.dark,
      home: LoginScreen(
        authentication: service ?? const UnavailableAuthenticationService(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('mantem a marca na posicao do quadro Figma 402 x 874', (
    tester,
  ) async {
    await _render(tester);
    expect(tester.getTopLeft(find.byType(FolksLogo)), const Offset(111, 108));
    expect(tester.getTopLeft(find.text('Usuário:')).dy, 400);
  });

  testWidgets('campos vazios nao iniciam autenticacao', (tester) async {
    final service = _PendingAuthentication();
    await _render(tester, service: service);
    await tester.tap(find.text('Entrar'));
    await tester.pumpAndSettle();
    expect(find.text('Informe seu usuário.'), findsOneWidget);
    expect(find.text('Informe sua senha.'), findsOneWidget);
    expect(service.calls, 0);
  });

  testWidgets('protege senha, preserva espacos e evita envios duplicados', (
    tester,
  ) async {
    final service = _PendingAuthentication();
    await _render(tester, service: service);
    final fields = find.byType(TextFormField);
    expect(
      tester.widget<EditableText>(find.byType(EditableText).at(1)).obscureText,
      isTrue,
    );
    await tester.enterText(fields.at(0), ' ana ');
    await tester.enterText(fields.at(1), ' senha de teste ');
    await tester.tap(find.text('Entrar'));
    await tester.pump();
    expect(find.text('Entrando…'), findsOneWidget);
    await tester.tap(find.text('Entrando…'));
    await tester.pump();
    expect(service.calls, 1);
    expect(service.username, 'ana');
    expect(service.password, ' senha de teste ');
    service.result.completeError(const AuthenticationUnavailable());
    await tester.pumpAndSettle();
    expect(
      find.text('Não foi possível entrar. Tente novamente mais tarde.'),
      findsOneWidget,
    );
    expect(find.text('Entrar'), findsOneWidget);
  });

  testWidgets('recuperacao informa indisponibilidade sem simular envio', (
    tester,
  ) async {
    await _render(tester);
    await tester.tap(find.text('Esqueceu a Senha?'));
    await tester.pumpAndSettle();
    expect(find.text('Recuperar senha'), findsOneWidget);
    expect(find.textContaining('indisponível'), findsOneWidget);
    await tester.tap(find.text('Fechar'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
  });

  for (final size in [const Size(375, 667), const Size(844, 390)]) {
    testWidgets('formulario acessivel em $size com texto ampliado e teclado', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(
          theme: FolksTheme.dark,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: const TextScaler.linear(2),
              viewInsets: const EdgeInsets.only(bottom: 260),
              disableAnimations: true,
            ),
            child: child!,
          ),
          home: const LoginScreen(),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Entrar'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}
