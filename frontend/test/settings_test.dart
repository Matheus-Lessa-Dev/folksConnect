import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/theme/folks_theme.dart';
import 'package:frontend/features/settings/settings_controller.dart';
import 'package:frontend/features/settings/settings_screen.dart';

Future<void> mount(
  WidgetTester tester,
  SettingsController controller, {
  Size size = const Size(402, 874),
  double textScale = 1,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      theme: FolksTheme.kanban,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(textScale),
          disableAnimations: true,
        ),
        child: child!,
      ),
      home: SettingsScreen(controller: controller),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  test('configuração valida todas as seções antes de gravar', () {
    final controller = SettingsController();
    addTearDown(controller.dispose);
    expect(
      () => controller.saveConfiguration(
        kanban: ['Novo'],
        funnel: ['Triagem', ' triagem '],
        checklist: ['Revisar'],
      ),
      throwsArgumentError,
    );
    expect(controller.kanbanStages.first, 'A fazer');
    controller.saveConfiguration(
      kanban: [' Novo '],
      funnel: ['Contato'],
      checklist: ['Revisar'],
    );
    expect(controller.kanbanStages, ['Novo']);
    expect(() => controller.checklist.add('Outro'), throwsUnsupportedError);
  });

  test('cadastro rejeita e-mail duplicado e mantém permissões imutáveis', () {
    final controller = SettingsController();
    addTearDown(controller.dispose);
    final permissions = <String>{'Editar Vaga'};
    controller.addUser(
      name: ' Maria ',
      email: 'maria@example.com',
      role: 'Analista',
      permissions: permissions,
    );
    permissions.clear();
    final user = controller.users.last;
    expect(user.name, 'Maria');
    expect(user.permissions, {'Editar Vaga'});
    expect(
      () => controller.addUser(
        name: 'Outra',
        email: ' MARIA@example.com ',
        role: 'Gerente',
        permissions: {},
      ),
      throwsArgumentError,
    );
    controller.changeRole(user.id, 'Diretor');
    expect(controller.users.last.role, 'Diretor');
    controller.removeUser(user.id);
    expect(controller.hasEmail('maria@example.com'), isFalse);
  });

  testWidgets(
    'fechar descarta rascunho e salvar mantém configuração na sessão',
    (tester) async {
      final controller = SettingsController();
      addTearDown(controller.dispose);
      await mount(tester, controller);
      await tapVisible(tester, find.text('Kanban, funil e Checklis'));
      await tester.enterText(find.byType(TextFormField).first, 'Pendente');
      await tapVisible(tester, find.text('Fechar'));
      expect(controller.kanbanStages.first, 'A fazer');
      await tapVisible(tester, find.text('Kanban, funil e Checklis'));
      expect(find.widgetWithText(TextFormField, 'A fazer'), findsOneWidget);
      await tester.enterText(find.byType(TextFormField).first, 'Pendente');
      await tapVisible(tester, find.text('Salvar Alteração'));
      expect(controller.kanbanStages.first, 'Pendente');
      expect(find.text('Alterações salvas nesta sessão.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'cadastro valida campos e retorna à lista com usuário e permissões',
    (tester) async {
      final controller = SettingsController();
      addTearDown(controller.dispose);
      await mount(tester, controller);
      await tapVisible(tester, find.text('Novo usuário'));
      await tapVisible(tester, find.text('Cadastrar Usuário'));
      await tapVisible(
        tester,
        find.widgetWithText(FilledButton, 'Cadastrar Usuário').last,
      );
      expect(find.text('Informe o nome completo.'), findsOneWidget);
      expect(find.text('Informe um e-mail válido.'), findsOneWidget);
      await tester.enterText(find.byType(TextFormField).at(0), 'Maria Silva');
      await tester.enterText(
        find.byType(TextFormField).at(1),
        'maria@example.com',
      );
      await tapVisible(tester, find.widgetWithText(FilterChip, 'Editar Vaga'));
      await tapVisible(
        tester,
        find.widgetWithText(FilledButton, 'Cadastrar Usuário').last,
      );
      expect(controller.users.last.permissions, {
        'Cadastrar Tarefas',
        'Editar Vaga',
      });
      expect(find.text('Maria Silva'), findsOneWidget);
      await tapVisible(tester, find.byTooltip('Remover Maria Silva'));
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      expect(controller.hasEmail('maria@example.com'), isTrue);
      await tapVisible(tester, find.byTooltip('Remover Maria Silva'));
      await tester.tap(find.text('Remover'));
      await tester.pumpAndSettle();
      expect(controller.hasEmail('maria@example.com'), isFalse);
      expect(tester.takeException(), isNull);
    },
  );

  for (final size in [
    const Size(375, 667),
    const Size(844, 390),
    const Size(768, 1024),
  ]) {
    testWidgets(
      'configurações e formulários em $size com fonte ampliada e teclado',
      (tester) async {
        final controller = SettingsController();
        addTearDown(controller.dispose);
        await mount(tester, controller, size: size, textScale: 2);
        await tapVisible(tester, find.text('Kanban, funil e Checklis'));
        await tapVisible(tester, find.text('Fechar'));
        await tapVisible(tester, find.text('Novo usuário'));
        await tapVisible(tester, find.text('Cadastrar Usuário'));
        tester.view.viewInsets = const FakeViewPadding(bottom: 200);
        addTearDown(tester.view.resetViewInsets);
        await tester.pumpAndSettle();
        await tapVisible(tester, find.text('Fechar').last);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
