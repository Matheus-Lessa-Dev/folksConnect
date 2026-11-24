import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/funnel_stages.dart';
import 'package:frontend/core/theme/folks_theme.dart';
import 'package:frontend/features/kanban/kanban_controller.dart';
import 'package:frontend/features/kanban/kanban_screen.dart';
import 'package:frontend/features/kanban/task.dart';
import 'package:frontend/features/kanban/widgets/kanban_widgets.dart';
import 'package:frontend/features/settings/settings_controller.dart';

Future<void> mount(
  WidgetTester tester,
  KanbanController controller, {
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
      home: KanbanScreen(controller: controller),
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
  testWidgets('coluna configurada aparece e recebe tarefas', (tester) async {
    final settings = SettingsController();
    final controller = KanbanController(settings: settings);
    addTearDown(settings.dispose);
    addTearDown(controller.dispose);
    await mount(tester, controller);
    settings.saveConfiguration(
      kanban: [...settings.kanbanStages, 'Revisão'],
      funnel: settings.funnelStages,
      checklist: settings.checklist,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lista'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Mover tarefa').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mover para Revisão'));
    await tester.pumpAndSettle();
    expect(controller.tasks.first.status, const BoardStatus('Revisão'));
    expect(find.text('Revisão'), findsOneWidget);
    await tester.tap(find.text('Kanban'));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(Scrollbar).first, const Offset(-2000, 0));
    await tester.pumpAndSettle();
    expect(find.text('REVISÃO'), findsOneWidget);
  });

  test('avançar altera etapa e responsável sem misturar status do quadro', () {
    final controller = KanbanController();
    addTearDown(controller.dispose);
    final task = controller.tasks.first;
    controller.advance(
      task.id,
      1,
      KanbanController.assignees[2],
    );
    expect(controller.tasks.first.stage, 1);
    expect(controller.tasks.first.assignee, KanbanController.assignees[2]);
    expect(controller.tasks.first.status, BoardStatus.todo);
    expect(
      () => controller.advance(
        task.id,
        0,
        task.assignee,
      ),
      throwsArgumentError,
    );
    expect(
      () => controller.advance(
        task.id,
        1,
        task.assignee,
      ),
      throwsArgumentError,
    );
  });

  test('criar revela a tarefa no filtro e rejeita datas invertidas', () {
    final controller = KanbanController(tasks: []);
    addTearDown(controller.dispose);
    controller.filterBy('Financeiro');
    KanbanTask task(DateTime start, DateTime end) => KanbanTask(
      id: controller.nextId(),
      title: 'Nova triagem',
      project: 'Recrutamento',
      company: 'Meta',
      role: 'HelpDesk',
      assignee: KanbanController.assignees.first,
      start: start,
      end: end,
    );
    expect(
      () =>
          controller.add(task(DateTime(2026, 10, 20), DateTime(2026, 10, 19))),
      throwsArgumentError,
    );
    expect(controller.tasks, isEmpty);
    controller.add(task(DateTime(2026, 10, 19), DateTime(2026, 10, 20)));
    expect(controller.filter, 'Recrutamento');
    expect(controller.visibleTasks.single.title, 'Nova triagem');
  });

  testWidgets('filtra por projeto, alterna lista e move cartão', (
    tester,
  ) async {
    final controller = KanbanController();
    addTearDown(controller.dispose);
    await mount(tester, controller);
    await tester.tap(find.widgetWithText(ChoiceChip, 'Recrutamento'));
    await tester.pumpAndSettle();
    expect(controller.visibleTasks.length, 2);
    expect(find.text('Triagem de currículos'), findsNothing);
    final card = find.byKey(const ValueKey('open-demo-screening'));
    expect(card, findsOneWidget);
    for (final label in controller.stages.names) {
      expect(
        find.descendant(of: card, matching: find.text(label)),
        findsNothing,
      );
    }
    await tester.tap(find.text('Lista'));
    await tester.pumpAndSettle();
    expect(controller.listView, isTrue);
    for (final label in controller.stages.names) {
      expect(
        find.descendant(of: card, matching: find.text(label)),
        findsOneWidget,
      );
    }
    expect(find.text('Entrevistas — Desenvolvedor Sênior'), findsOneWidget);
    await tester.tap(find.byTooltip('Mover tarefa').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mover para Concluído'));
    await tester.pumpAndSettle();
    expect(controller.tasks.first.status, BoardStatus.done);
    expect(tester.takeException(), isNull);
  });

  testWidgets('valida formulário, cria tarefa e retorna ao quadro', (
    tester,
  ) async {
    final controller = KanbanController(tasks: []);
    addTearDown(controller.dispose);
    await mount(tester, controller);
    await tester.tap(find.byTooltip('Nova tarefa'));
    await tester.pumpAndSettle();
    await tapVisible(tester, find.text('Criar Tarefas'));
    expect(controller.tasks, isEmpty);
    expect(find.text('Informe o título da tarefa.'), findsOneWidget);
    await tapVisible(tester, find.byKey(const Key('task-title')));
    await tester.enterText(
      find.byKey(const Key('task-title')),
      'Triagem de candidatos',
    );
    for (final entry in {'Empresa': 'Meta', 'Cargo': 'HelpDesk'}.entries) {
      await tapVisible(tester, find.byKey(ValueKey('field-${entry.key}')));
      await tester.tap(find.text(entry.value).last);
      await tester.pumpAndSettle();
    }
    for (final key in ['start-date', 'end-date']) {
      await tapVisible(tester, find.byKey(Key(key)));
      await tester.tap(find.text('Selecionar'));
      await tester.pumpAndSettle();
    }
    await tapVisible(tester, find.text('Criar Tarefas'));
    expect(controller.tasks.single.title, 'Triagem de candidatos');
    expect(find.text('Nova Tarefa'), findsNothing);
    expect(find.text('Triagem de candidatos'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('checklist mantém edição e avanço só acontece ao confirmar', (
    tester,
  ) async {
    final controller = KanbanController();
    addTearDown(controller.dispose);
    await mount(tester, controller);
    await tester.tap(find.byKey(const ValueKey('open-demo-screening')));
    await tester.pumpAndSettle();
    await tapVisible(tester, find.text('Coletar currículos inscritos'));
    expect(controller.tasks.first.checklist.first.done, isTrue);
    await tapVisible(tester, find.text('Avançar Etapa'));
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(controller.tasks.first.stage, 0);
    await tapVisible(tester, find.text('Avançar Etapa'));
    await tester.tap(find.text('Concluir'));
    await tester.pumpAndSettle();
    expect(controller.tasks.first.stage, 1);
    await tapVisible(tester, find.text('Fechar'));
    await tester.tap(find.byKey(const ValueKey('open-demo-screening')));
    await tester.pumpAndSettle();
    expect(controller.tasks.first.checklist.first.done, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('selo de status mostra a etapa e permite escolher a próxima', (
    tester,
  ) async {
    final controller = KanbanController();
    addTearDown(controller.dispose);
    await mount(tester, controller);
    await tester.tap(find.byKey(const ValueKey('open-demo-screening')));
    await tester.pumpAndSettle();
    final badge = find.byKey(const ValueKey('stage-badge'));
    expect(
      find.descendant(of: badge, matching: find.text('Triagem')),
      findsOneWidget,
    );
    await tapVisible(tester, badge);
    expect(find.text('AVANÇAR ETAPA'), findsOneWidget);
    await tester.tap(find.text('Concluir'));
    await tester.pumpAndSettle();
    expect(controller.tasks.first.stage, 1);
    expect(
      find.descendant(of: badge, matching: find.text('Entrevista')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('barras e selo seguem as etapas cadastradas nas configurações', (
    tester,
  ) async {
    final stages = FunnelStages(['Recebido', 'Análise', 'Proposta']);
    addTearDown(stages.dispose);
    final controller = KanbanController(stages: stages);
    addTearDown(controller.dispose);
    await mount(tester, controller);
    await tester.tap(find.byKey(const ValueKey('open-demo-screening')));
    await tester.pumpAndSettle();
    final badge = find.byKey(const ValueKey('stage-badge'));
    expect(
      find.descendant(of: badge, matching: find.text('Recebido')),
      findsOneWidget,
    );
    // "Triagem" também é nome de projeto nas tarefas de demonstração; por isso
    // as checagens olham só as barrinhas de etapa.
    final bars = find.byType(Pipeline);
    expect(
      find.descendant(of: bars, matching: find.text('Triagem')),
      findsNothing,
    );
    expect(
      find.descendant(of: bars, matching: find.text('Análise')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: bars, matching: find.text('Proposta')),
      findsOneWidget,
    );

    // Alterar as etapas nas configurações atualiza as barras já abertas.
    stages.update(['Recebido', 'Análise', 'Proposta', 'Fechado']);
    await tester.pumpAndSettle();
    expect(
      find.descendant(of: bars, matching: find.text('Fechado')),
      findsOneWidget,
    );

    await tapVisible(tester, badge);
    await tester.tap(find.text('Concluir'));
    await tester.pumpAndSettle();
    expect(controller.tasks.first.stage, 1);
    expect(
      find.descendant(of: badge, matching: find.text('Análise')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  for (final size in [
    const Size(375, 812),
    const Size(812, 375),
    const Size(1024, 768),
  ]) {
    testWidgets('layout ${size.width}x${size.height} com texto ampliado', (
      tester,
    ) async {
      final controller = KanbanController();
      addTearDown(controller.dispose);
      await mount(tester, controller, size: size, textScale: 1.5);
      expect(tester.takeException(), isNull);
      await tester.tap(find.byTooltip('Nova tarefa'));
      await tester.pumpAndSettle();
      expect(find.text('Nova Tarefa'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
