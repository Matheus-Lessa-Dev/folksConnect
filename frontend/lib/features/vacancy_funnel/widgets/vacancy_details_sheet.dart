import 'package:flutter/material.dart';

import '../../../core/theme/folks_theme.dart';
import '../../kanban/widgets/kanban_widgets.dart';
import '../vacancy.dart';
import '../vacancy_funnel_controller.dart';
import 'vacancy_deadline_fields.dart';

class VacancyDetailsSheet extends StatefulWidget {
  const VacancyDetailsSheet({
    super.key,
    required this.controller,
    required this.vacancy,
  });

  final VacancyFunnelController controller;
  final FunnelVacancy vacancy;

  @override
  State<VacancyDetailsSheet> createState() => _VacancyDetailsSheetState();
}

class _VacancyDetailsSheetState extends State<VacancyDetailsSheet> {
  final _form = GlobalKey<FormState>();
  late final _profile = TextEditingController(text: widget.vacancy.profile);
  late DateTime _start = widget.vacancy.start;
  late DateTime _end = widget.vacancy.end;
  late final _channels = {...widget.vacancy.channels};
  String? _dateError;

  @override
  void dispose() {
    _profile.dispose();
    super.dispose();
  }

  Future<void> _pickDate(bool start) async {
    final date = await pickVacancyDate(
      context,
      start: start,
      initialDate: start ? _start : _end,
    );
    if (!mounted || date == null) return;
    setState(() {
      if (start) {
        _start = date;
      } else {
        _end = date;
      }
      _dateError = null;
    });
  }

  Future<void> _addChannel() async {
    var name = '';
    final form = GlobalKey<FormState>();
    final channel = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Adicionar canal'),
        content: Form(
          key: form,
          child: TextFormField(
            autofocus: true,
            maxLength: 60,
            onChanged: (value) => name = value.trim(),
            decoration: const InputDecoration(labelText: 'Canal de divulgação'),
            validator: (_) {
              if (name.isEmpty) return 'Informe o nome do canal.';
              if (_channels.any(
                (channel) => channel.toLowerCase() == name.toLowerCase(),
              )) {
                return 'Este canal já está cadastrado.';
              }
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              if (form.currentState!.validate()) Navigator.pop(context, name);
            },
            child: const Text('Adicionar'),
          ),
        ],
      ),
    );
    if (!mounted || channel == null) return;
    setState(() => _channels.add(channel));
  }

  void _save() {
    final invalid = _form.currentState!.validateGranularly();
    setState(() {
      _dateError = _end.isBefore(_start)
          ? 'O fim deve ser igual ou posterior ao início.'
          : null;
    });
    if (invalid.isNotEmpty) {
      Scrollable.ensureVisible(invalid.first.context, alignment: .2);
      return;
    }
    if (_dateError != null) return;
    widget.controller.updateDetails(
      widget.vacancy,
      start: _start,
      end: _end,
      profile: _profile.text.trim(),
      channels: _channels.toList(),
    );
    Navigator.pop(context);
  }

  Widget _value(String label, String value, {IconData? icon}) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Semantics(
      label: label,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: FolksColors.field,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16),
                const SizedBox(width: 8),
              ],
              Expanded(child: Text(value.isEmpty ? 'Não informado' : value)),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _metric(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Row(
      children: [
        Expanded(child: Text(label)),
        const SizedBox(width: 12),
        SizedBox(width: 92, child: _value(label, value)),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final vacancy = widget.vacancy;
    final client = widget.controller.clients
        .where((client) => client.company == vacancy.company)
        .firstOrNull;
    final deadline = vacancy.deadline(DateTime.now());
    final (status, color) = switch (deadline) {
      VacancyDeadline.overdue => ('Atenção', FolksColors.red),
      VacancyDeadline.closing => (deadline.label, FolksColors.gold),
      VacancyDeadline.onTime => (deadline.label, FolksColors.blue),
    };
    return Form(
      key: _form,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: .15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  vacancy.assignee,
                  textAlign: TextAlign.end,
                  style: const TextStyle(color: FolksColors.muted),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Recrutamento — ${vacancy.role}',
            style: FolksTheme.heading.copyWith(fontSize: 22),
          ),
          Text(
            'Vaga • Cliente ${vacancy.company}',
            style: const TextStyle(color: FolksColors.muted),
          ),
          const SizedBox(height: 12),
          Pipeline(vacancy.stage),
          const Divider(height: 28),
          VacancyDeadlineFields(
            start: _start,
            end: _end,
            error: _dateError,
            onPick: _pickDate,
          ),
          const Text(
            'Representante',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          _value('Representante', client?.representative ?? ''),
          _value('Contato', client?.contact ?? '', icon: Icons.phone_outlined),
          _value('E-mail', client?.email ?? '', icon: Icons.mail_outline),
          const SizedBox(height: 8),
          _metric('Candidatos inscritos', '${vacancy.applicants}'),
          _metric('Candidatos ideais', '${vacancy.idealPercentage}%'),
          _metric('Erros de triagem', '${vacancy.screeningErrors}'),
          const SizedBox(height: 8),
          FieldLabel(
            'Perfil desejado',
            child: TextFormField(
              controller: _profile,
              minLines: 2,
              maxLines: 5,
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Informe o perfil desejado.'
                  : null,
            ),
          ),
          FieldLabel(
            'Canal de divulgação',
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final channel in _channels)
                  Chip(
                    label: Text(channel),
                    backgroundColor: FolksColors.purple,
                    side: const BorderSide(color: FolksColors.border),
                  ),
                ActionChip(
                  label: const Text('+ Adicionar'),
                  onPressed: _addChannel,
                ),
              ],
            ),
          ),
          SheetActions(
            primaryLabel: 'Salvar',
            onPrimary: _save,
            onClose: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}
