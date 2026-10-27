// Captura de revisao visual; nao e um teste golden nem uma comparacao com Figma.
// flutter test tool/capture_kanban.dart --no-pub
//   --dart-define=CAPTURE_DIR=<pasta>
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/theme/folks_theme.dart';
import 'package:frontend/features/kanban/kanban_controller.dart';
import 'package:frontend/features/kanban/kanban_screen.dart';

void main() {
  testWidgets('capturar estados do Kanban para revisao', (tester) async {
    debugDisableShadows = false;
    addTearDown(() => debugDisableShadows = true);
    const output = String.fromEnvironment('CAPTURE_DIR');
    if (output.isEmpty) fail('Defina CAPTURE_DIR para salvar as capturas.');
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();
    final inter = FontLoader('Inter')
      ..addFont(rootBundle.load('assets/fonts/Inter-Variable.ttf'));
    final sans = FontLoader('InriaSans')
      ..addFont(rootBundle.load('assets/fonts/InriaSans-Regular.ttf'))
      ..addFont(rootBundle.load('assets/fonts/InriaSans-Bold.ttf'));
    final serif = FontLoader('InriaSerif')
      ..addFont(rootBundle.load('assets/fonts/InriaSerif-Bold.ttf'));
    await Future.wait([inter.load(), sans.load(), serif.load()]);
    final key = GlobalKey();
    final controller = KanbanController();
    addTearDown(controller.dispose);
    tester.view.physicalSize = const Size(402, 874);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      RepaintBoundary(
        key: key,
        child: MaterialApp(
          theme: FolksTheme.kanban,
          debugShowCheckedModeBanner: false,
          home: KanbanScreen(controller: controller),
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
    Future<void> capture(String name) async {
      await tester.runAsync(() async {
        final boundary =
            key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final image = await boundary.toImage(pixelRatio: 2);
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        Directory(output).createSync(recursive: true);
        File('$output/$name.png').writeAsBytesSync(data!.buffer.asUint8List());
        image.dispose();
      });
    }

    await capture('kanban');
    await tester.tap(find.byTooltip('Nova tarefa'));
    await tester.pumpAndSettle();
    await capture('nova-tarefa');
    await tester.ensureVisible(find.text('Cancelar'));
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('open-demo-screening')));
    await tester.pumpAndSettle();
    await capture('detalhes-tarefa');
    await tester.ensureVisible(find.text('Avançar Etapa'));
    await tester.tap(find.text('Avançar Etapa'));
    await tester.pumpAndSettle();
    await capture('avancar-etapa');
    debugDisableShadows = true;
    expect(tester.takeException(), isNull);
  });
}
