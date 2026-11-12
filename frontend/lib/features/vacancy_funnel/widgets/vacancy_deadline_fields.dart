import 'package:flutter/material.dart';

import '../../../core/theme/folks_theme.dart';
import '../../kanban/task.dart';
import '../../kanban/widgets/kanban_widgets.dart';

Future<DateTime?> pickVacancyDate(
  BuildContext context, {
  required bool start,
  DateTime? initialDate,
}) => showDatePicker(
  context: context,
  initialDate: initialDate ?? DateUtils.dateOnly(DateTime.now()),
  firstDate: DateTime(2000),
  lastDate: DateTime(2100),
  helpText: start ? 'Prazo inicial' : 'Prazo final',
  cancelText: 'Cancelar',
  confirmText: 'Selecionar',
);

class VacancyDeadlineFields extends StatelessWidget {
  const VacancyDeadlineFields({
    super.key,
    required this.start,
    required this.end,
    required this.onPick,
    this.error,
  });

  final DateTime? start;
  final DateTime? end;
  final ValueChanged<bool> onPick;
  final String? error;

  Widget _date(String label, DateTime? date, bool isStart) {
    final value = date == null
        ? '01/01/2000'
        : '${shortDate(date)}/${date.year}';
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ExcludeSemantics(child: Text('$label:')),
        const SizedBox(width: 8),
        Flexible(
          child: OutlinedButton(
            key: Key(isStart ? 'vacancy-start' : 'vacancy-end'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10),
            ),
            onPressed: () => onPick(isStart),
            child: Text(
              value,
              semanticsLabel: date == null
                  ? '$label. Exemplo: $value. Selecione uma data.'
                  : '$label: $value',
              style: TextStyle(color: date == null ? FolksColors.muted : null),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) => FieldLabel(
    'Prazo estimado',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [_date('Início', start, true), _date('Fim', end, false)],
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Semantics(
              liveRegion: true,
              child: Text(
                error!,
                style: const TextStyle(color: FolksColors.red, fontSize: 12),
              ),
            ),
          ),
      ],
    ),
  );
}
