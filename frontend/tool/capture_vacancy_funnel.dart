// flutter test tool/capture_vacancy_funnel.dart --no-pub
//   --dart-define=CAPTURE_DIR=<pasta>
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/theme/folks_theme.dart';
import 'package:frontend/features/vacancy_funnel/vacancy_funnel_screen.dart';

void main() {
  testWidgets('capturar funil e cadastro para revisão visual', (tester) async {
    const output = String.fromEnvironment('CAPTURE_DIR');
    if (output.isEmpty) fail('Defina CAPTURE_DIR para salvar as capturas.');
    debugDisableShadows = false;
    addTearDown(() => debugDisableShadows = true);
    for (final entry in {
      'MaterialIcons': ['fonts/MaterialIcons-Regular.otf'],
      'Inter': ['assets/fonts/Inter-Variable.ttf'],
      'InriaSerif': ['assets/fonts/InriaSerif-Bold.ttf'],
    }.entries) {
      final loader = FontLoader(entry.key);
      for (final path in entry.value) {
        loader.addFont(rootBundle.load(path));
      }
      await loader.load();
    }
    tester.view.physicalSize = const Size(402, 874);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final key = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(
        key: key,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: FolksTheme.dark,
          home: const VacancyFunnelScreen(),
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
    await capture('funil-vagas');
    await tester.tap(find.text('+ Vaga'));
    await tester.pumpAndSettle();
    await capture('cadastrar-vaga');
    debugDisableShadows = true;
    expect(tester.takeException(), isNull);
  });
}
