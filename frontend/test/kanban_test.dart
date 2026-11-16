import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/theme/folks_theme.dart';
import 'package:frontend/features/kanban/kanban_controller.dart';
import 'package:frontend/features/kanban/kanban_screen.dart';
import 'package:frontend/features/kanban/task.dart';
import 'package:frontend/features/vacancy_funnel/vacancy.dart';
import 'package:frontend/features/vacancy_funnel/vacancy_funnel_controller.dart';

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
  test('avançar altera etapa e responsável sem misturar status do quadro', () {
    final controller = KanbanController();
    addTearDown(controller.dispose);
    final task = controller.tasks.first;
    controller.advance(
      task.id,
      RecruitmentStage.interview,
      KanbanController.assignees[2],
    );
    expect(controller.tasks.first.stage, RecruitmentStage.interview);
    expect(controller.tasks.first.assignee, KanbanController.assignees[2]);
    expect(controller.tasks.first.status, BoardStatus.todo);
    expect(
      () => controller.advance(
        task.id,
        RecruitmentStage.screening,
        task.assignee,
      ),
      throwsArgumentError,
    );
    expect(
      () => controller.advance(
        task.id,
        RecruitmentStage.interview,
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

  test(
    'vaga criada no funil gera tarefa em A Fazer no Kanban e disponibiliza empresa/cargo',
    () {
      final funnel = VacancyFunnelController(vacancies: []);
      final kanban = KanbanController(tasks: [], funnel: funnel);
      addTearDown(funnel.dispose);
      addTearDown(kanban.dispose);

      funnel.addClient(const VacancyClient(company: 'Folks'));
      expect(kanban.companies, contains('Folks'));

      final start = DateTime(2026, 11, 16);
      final end = DateTime(2026, 11, 25);
      funnel.add(
        role: 'Vaga para Desenvolvedor',
        company: 'Folks',
        profile: 'Desenvolvimento Flutter e backend Dart.',
        assignee: 'Eduarda - Analista',
        start: start,
        end: end,
        channels: ['LinkedIn'],
      );

      expect(kanban.tasks.length, 1);
      final task = kanban.tasks.single;
      expect(task.status, BoardStatus.todo);
      expect(task.title, 'Triagem — Vaga para Desenvolvedor');
      expect(task.company, 'Folks');
      expect(task.role, 'Vaga para Desenvolvedor');
      expect(task.stage, RecruitmentStage.screening);
      expect(task.assignee, 'Eduarda — Analista');
      expect(task.start, start);
      expect(task.end, end);
      expect(task.description, 'Desenvolvimento Flutter e backend Dart.');

      expect(kanban.roles, contains('Vaga para Desenvolvedor'));
      expect(kanban.companies, contains('Folks'));
    },
  );

  testWidgets(
    'nova tarefa exibe empresas e cargos do funil e preenche dados ao selecionar cargo',
    (tester) async {
      final funnel = VacancyFunnelController(vacancies: []);
      final kanban = KanbanController(tasks: [], funnel: funnel);
      addTearDown(funnel.dispose);
      addTearDown(kanban.dispose);

      funnel.addClient(const VacancyClient(company: 'Folks'));
      final start = DateTime(2026, 11, 16);
      final end = DateTime(2026, 11, 25);
      funnel.add(
        role: 'Vaga para Desenvolvedor',
        company: 'Folks',
        profile: 'Desenvolvimento em Flutter',
        assignee: 'Eduarda - Analista',
        start: start,
        end: end,
        channels: ['LinkedIn'],
      );

      await mount(tester, kanban);
      await tester.tap(find.byTooltip('Nova tarefa'));
      await tester.pumpAndSettle();

      await tapVisible(tester, find.byKey(const ValueKey('field-Cargo')));
      expect(find.text('Vaga para Desenvolvedor'), findsWidgets);
      await tester.tap(find.text('Vaga para Desenvolvedor').last);
      await tester.pumpAndSettle();

      expect(find.text('Triagem — Vaga para Desenvolvedor'), findsWidgets);
      expect(find.text('Folks'), findsWidgets);
    },
  );

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
    await tester.tap(find.text('Lista'));
    await tester.pumpAndSettle();
    expect(controller.listView, isTrue);
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
    expect(controller.tasks.first.stage, RecruitmentStage.screening);
    await tapVisible(tester, find.text('Avançar Etapa'));
    await tester.tap(find.text('Concluir'));
    await tester.pumpAndSettle();
    expect(controller.tasks.first.stage, RecruitmentStage.interview);
    await tapVisible(tester, find.text('Fechar'));
    await tester.tap(find.byKey(const ValueKey('open-demo-screening')));
    await tester.pumpAndSettle();
    expect(controller.tasks.first.checklist.first.done, isTrue);
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
