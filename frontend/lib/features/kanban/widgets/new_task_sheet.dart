import 'package:flutter/material.dart';

import '../../../core/theme/folks_theme.dart';
import '../kanban_controller.dart';
import '../task.dart';
import 'kanban_widgets.dart';

class NewTaskSheet extends StatefulWidget {
  const NewTaskSheet({super.key, required this.controller});
  final KanbanController controller;

  @override
  State<NewTaskSheet> createState() => _NewTaskSheetState();
}

class _NewTaskSheetState extends State<NewTaskSheet> {
  final _form = GlobalKey<FormState>();
  final _title = TextEditingController();
  late String _project = widget.controller.filter == 'Todos'
      ? KanbanController.projects.first
      : widget.controller.filter;
  String? _company;
  String? _role;
  String _assignee = KanbanController.assignees.first;
  TaskPriority _priority = TaskPriority.medium;
  DateTime? _start;
  DateTime? _end;
  String? _dateError;

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  Future<void> _pickDate(bool start) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final first = DateTime(2020);
    final last = DateTime(2100);
    final date = await showDatePicker(
      context: context,
      initialDate: (start ? _start : _end) ?? _start ?? today,
      firstDate: first,
      lastDate: last,
      helpText: start ? 'Prazo inicial' : 'Prazo final',
      cancelText: 'Cancelar',
      confirmText: 'Selecionar',
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

  void _create() {
    final invalidFields = _form.currentState!.validateGranularly();
    setState(() {
      _dateError = _start == null || _end == null
          ? 'Selecione o início e o fim do prazo.'
          : _end!.isBefore(_start!)
          ? 'O fim deve ser igual ou posterior ao início.'
          : null;
    });
    if (invalidFields.isNotEmpty) {
      Scrollable.ensureVisible(invalidFields.first.context, alignment: .2);
      return;
    }
    if (_dateError != null) return;
    final task = KanbanTask(
      id: widget.controller.nextId(),
      title: _title.text.trim(),
      project: _project,
      company: _company!,
      role: _role!,
      assignee: _assignee,
      start: _start!,
      end: _end!,
      priority: _priority,
      checklist: KanbanController.defaultChecklist,
    );
    widget.controller.add(task);
    Navigator.pop(context, task);
  }

  Widget _select(
    String label,
    String? value,
    List<String> options,
    ValueChanged<String> change,
  ) => FieldLabel(
    label,
    child: DropdownButtonFormField<String>(
      key: ValueKey('field-$label'),
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(
        hintText: 'Selecionar',
        semanticCounterText: label,
      ),
      items: options
          .map(
            (item) => DropdownMenuItem(
              value: item,
              child: Text(item, style: const TextStyle(fontSize: 13)),
            ),
          )
          .toList(),
      onChanged: (item) {
        if (item != null) setState(() => change(item));
      },
      validator: (item) =>
          item == null ? 'Selecione ${label.toLowerCase()}.' : null,
    ),
  );

  @override
  Widget build(BuildContext context) => Form(
    key: _form,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Nova Tarefa', style: FolksTheme.heading.copyWith(fontSize: 25)),
        const SizedBox(height: 24),
        FieldLabel(
          'Título',
          child: TextFormField(
            key: const Key('task-title'),
            controller: _title,
            textCapitalization: TextCapitalization.sentences,
            maxLength: 120,
            decoration: const InputDecoration(
              hintText: 'Ex.: Triagem — Vaga Comercial',
              counterText: '',
            ),
            validator: (value) => value == null || value.trim().isEmpty
                ? 'Informe o título da tarefa.'
                : null,
          ),
        ),
        _select(
          'Projeto',
          _project,
          KanbanController.projects,
          (value) => _project = value,
        ),
        _select(
          'Empresa',
          _company,
          KanbanController.companies,
          (value) => _company = value,
        ),
        _select(
          'Cargo',
          _role,
          KanbanController.roles,
          (value) => _role = value,
        ),
        _select(
          'Responsável',
          _assignee,
          KanbanController.assignees,
          (value) => _assignee = value,
        ),
        FieldLabel(
          'Prazo estimado',
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      key: const Key('start-date'),
                      onPressed: () => _pickDate(true),
                      child: Text(
                        'Início: ${_start == null ? '/ /' : shortDate(_start!)}',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      key: const Key('end-date'),
                      onPressed: () => _pickDate(false),
                      child: Text(
                        'Fim: ${_end == null ? '/ /' : shortDate(_end!)}',
                      ),
                    ),
                  ),
                ],
              ),
              if (_dateError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    _dateError!,
                    style: const TextStyle(
                      color: FolksColors.red,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
        ),
        FieldLabel(
          'Prioridade',
          child: SegmentedButton<TaskPriority>(
            segments: TaskPriority.values
                .map(
                  (priority) => ButtonSegment(
                    value: priority,
                    label: Text(priority.label),
                  ),
                )
                .toList(),
            selected: {_priority},
            showSelectedIcon: false,
            onSelectionChanged: (value) =>
                setState(() => _priority = value.first),
          ),
        ),
        SheetActions(
          primaryLabel: 'Criar Tarefas',
          onPrimary: _create,
          secondaryLabel: 'Cancelar',
          onClose: () => Navigator.pop(context),
        ),
      ],
    ),
  );
}
