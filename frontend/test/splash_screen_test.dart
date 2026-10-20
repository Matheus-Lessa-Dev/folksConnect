import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/app.dart';
import 'package:frontend/features/auth/login_screen.dart';
import 'package:frontend/features/splash/splash_screen.dart';
import 'package:frontend/shared/widgets/folks_logo.dart';

void main() {
  testWidgets('abertura exibe a marca original sem controles de login', (
    tester,
  ) async {
    await tester.pumpWidget(const FolksConnectApp());
    await tester.pump();

    expect(find.byType(FolksLogo), findsOneWidget);
    expect(find.byType(TextFormField), findsNothing);
    expect(tester.takeException(), isNull);

    await tester.runAsync(
      () => precacheImage(
        const AssetImage(FolksLogo.asset),
        tester.element(find.byType(SplashScreen)),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 901));
    await tester.pumpAndSettle();
    expect(find.byType(SplashScreen), findsNothing);
    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('fechar durante a abertura cancela a navegacao pendente', (
    tester,
  ) async {
    await tester.pumpWidget(const FolksConnectApp());
    await tester.pump();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 2));
    expect(tester.takeException(), isNull);
  });
}
