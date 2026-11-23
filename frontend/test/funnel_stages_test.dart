import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/funnel_stages.dart';
import 'package:frontend/features/settings/settings_controller.dart';

void main() {
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
