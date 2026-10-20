import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/app.dart';
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
  });
}
