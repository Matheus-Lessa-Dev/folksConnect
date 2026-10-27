// flutter test tool/capture_settings.dart --no-pub --dart-define=CAPTURE_DIR=<pasta>
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/theme/folks_theme.dart';
import 'package:frontend/features/settings/settings_controller.dart';
import 'package:frontend/features/settings/settings_screen.dart';

void main() {
  testWidgets('capturar os quatro quadros de configurações', (tester) async {
    const output = String.fromEnvironment('CAPTURE_DIR');
    if (output.isEmpty) fail('Defina CAPTURE_DIR para salvar as capturas.');
    debugDisableShadows = false;
    addTearDown(() => debugDisableShadows = true);
    for (final entry in {
      'MaterialIcons': 'fonts/MaterialIcons-Regular.otf',
      'Inter': 'assets/fonts/Inter-Variable.ttf',
      'InriaSerif': 'assets/fonts/InriaSerif-Bold.ttf',
    }.entries) {
      await (FontLoader(
        entry.key,
      )..addFont(rootBundle.load(entry.value))).load();
    }
    tester.view.physicalSize = const Size(402, 874);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final controller = SettingsController();
    addTearDown(controller.dispose);
    final key = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(
        key: key,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: FolksTheme.kanban,
          home: SettingsScreen(controller: controller),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.runAsync(
      () => precacheImage(
        const AssetImage('assets/brand/folks-white.png'),
        key.currentContext!,
      ),
    );
    await tester.pumpAndSettle();
    Future<void> capture(String name) => tester.runAsync(() async {
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final frame = await boundary.toImage(pixelRatio: 2);
      final data = await frame.toByteData(format: ui.ImageByteFormat.png);
      Directory(output).createSync(recursive: true);
      File('$output/$name.png').writeAsBytesSync(data!.buffer.asUint8List());
      frame.dispose();
    });
    Future<void> tap(String text) async {
      await tester.ensureVisible(find.text(text).last);
      await tester.tap(find.text(text).last);
      await tester.pumpAndSettle();
    }

    await capture('configuracoes');
    await tap('Kanban, funil e Checklis');
    await capture('configuracoes-gerais');
    await tap('Fechar');
    await tap('Novo usuário');
    await capture('usuarios');
    await tap('Cadastrar Usuário');
    await capture('novo-usuario');
    debugDisableShadows = true;
    expect(tester.takeException(), isNull);
  });
}
