import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/funnel_stages.dart';
import 'package:frontend/features/settings/settings_controller.dart';
import 'package:frontend/features/kanban/kanban_controller.dart';
import 'package:frontend/features/vacancy_funnel/vacancy_funnel_controller.dart';

void main() {
  test('reordenar etapas preserva a etapa de tarefas e vagas', () {
    final stages = FunnelStages();
    final settings = SettingsController(stages: stages);
    final kanban = KanbanController(stages: stages, settings: settings);
    final funnel = VacancyFunnelController(stages: stages);
    addTearDown(stages.dispose);
    addTearDown(settings.dispose);
    addTearDown(kanban.dispose);
    addTearDown(funnel.dispose);
    final task = kanban.tasks.last;
    final vacancy = funnel.vacancies.first;
    final taskLabel = stages.label(task.stage);
    final vacancyLabel = stages.label(vacancy.stage);
    settings.saveConfiguration(
      kanban: settings.kanbanStages.reversed.toList(),
      funnel: stages.names.reversed.toList(),
      checklist: settings.checklist.reversed.toList(),
      funnelPreviousIndices: [3, 2, 1, 0],
    );
    expect(stages.label(kanban.tasks.last.stage), taskLabel);
    expect(stages.label(funnel.vacancies.first.stage), vacancyLabel);
    expect(
      kanban.boardStatuses.map((item) => item.label),
      settings.kanbanStages,
    );
    expect(
      kanban.configuredChecklist.map((item) => item.title),
      settings.checklist,
    );
    expect(
      kanban.tasks.first.checklist.map((item) => item.title),
      settings.checklist,
    );
  });
  test('rótulo, limite e etapas seguintes seguem a lista atual', () {
    final stages = FunnelStages(['A', 'B', 'C']);
    addTearDown(stages.dispose);
    expect(stages.label(1), 'B');
    expect(stages.label(9), 'C');
    expect(stages.clamp(-1), 0);
    expect(stages.following(0), [1, 2]);
    expect(stages.following(2), isEmpty);
    expect(stages.following(9), isEmpty);
  });

  test('atualizar notifica e não aceita lista vazia', () {
    final stages = FunnelStages();
    addTearDown(stages.dispose);
    var calls = 0;
    stages.addListener(() => calls++);
    stages.update(['X', 'Y']);
    expect(stages.names, ['X', 'Y']);
    expect(calls, 1);
    expect(() => stages.update([]), throwsArgumentError);
    expect(stages.names, ['X', 'Y']);
  });

  test('salvar configurações atualiza as etapas compartilhadas', () {
    final stages = FunnelStages();
    addTearDown(stages.dispose);
    final settings = SettingsController(stages: stages);
    addTearDown(settings.dispose);
    settings.saveConfiguration(
      kanban: settings.kanbanStages,
      funnel: ['Recebido', 'Proposta'],
      checklist: settings.checklist,
    );
    expect(stages.names, ['Recebido', 'Proposta']);
    expect(settings.funnelStages, ['Recebido', 'Proposta']);
  });
}
