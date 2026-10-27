import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/folks_theme.dart';
import '../kanban_controller.dart';
import '../task.dart';
import 'kanban_widgets.dart';

class TaskDetailsSheet extends StatefulWidget {
  const TaskDetailsSheet({
    super.key,
    required this.controller,
    required this.taskId,
  });
  final KanbanController controller;
  final String taskId;

  @override
  State<TaskDetailsSheet> createState() => _TaskDetailsSheetState();
}

class _TaskDetailsSheetState extends State<TaskDetailsSheet> {
  final _checklistTitle = TextEditingController();
  late final _description = TextEditingController(text: _task.description);
  bool _picking = false;
  String? _attachmentError;
  KanbanTask get _task =>
      widget.controller.tasks.firstWhere((task) => task.id == widget.taskId);

  @override
  void dispose() {
    _checklistTitle.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _attach() async {
    setState(() {
      _picking = true;
      _attachmentError = null;
    });
    try {
      final files = await openFiles();
      final additions = <TaskAttachment>[];
      for (final file in files) {
        if (await file.length() > 10 * 1024 * 1024) {
          throw StateError('Selecione arquivos de até 10 MB.');
        }
        additions.add(
          TaskAttachment(name: file.name, bytes: await file.readAsBytes()),
        );
      }
      if (!mounted || additions.isEmpty) return;
      widget.controller.update(
        _task.copyWith(attachments: [..._task.attachments, ...additions]),
      );
    } catch (_) {
      if (mounted) {
        setState(
          () => _attachmentError =
              'Não foi possível anexar. Selecione arquivos de até 10 MB.',
        );
      }
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  void _addChecklist() {
    final title = _checklistTitle.text.trim();
    if (title.isEmpty) return;
    widget.controller.update(
      _task.copyWith(checklist: [..._task.checklist, ChecklistItem(title)]),
    );
    _checklistTitle.clear();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.controller,
    builder: (context, _) {
      final task = _task;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: ProjectBadge(task.project),
          ),
          const SizedBox(height: 12),
          Text(task.title, style: FolksTheme.heading.copyWith(fontSize: 24)),
          const SizedBox(height: 6),
          Text(
            'Vaga · Cliente ${task.company}',
            style: const TextStyle(color: FolksColors.muted, fontSize: 12),
          ),
          const SizedBox(height: 16),
          Pipeline(task.stage),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(color: FolksColors.border),
          ),
          FieldLabel(
            'Responsável',
            child: DropdownButtonFormField<String>(
              key: ValueKey(task.assignee),
              initialValue: task.assignee,
              isExpanded: true,
              items: KanbanController.assignees
                  .map(
                    (name) => DropdownMenuItem(
                      value: name,
                      child: Text(name, style: const TextStyle(fontSize: 13)),
                    ),
                  )
                  .toList(),
              onChanged: (name) {
                if (name != null) {
                  widget.controller.update(task.copyWith(assignee: name));
                }
              },
            ),
          ),
          FieldLabel(
            'Prioridade',
            child: SegmentedButton<TaskPriority>(
              segments: TaskPriority.values
                  .map(
                    (priority) => ButtonSegment(
                      value: priority,
                      label: Text(
                        priority.label,
                        style: TextStyle(color: priorityColor(priority)),
                      ),
                    ),
                  )
                  .toList(),
              selected: {task.priority},
              showSelectedIcon: false,
              onSelectionChanged: (value) => widget.controller.update(
                task.copyWith(priority: value.first),
              ),
            ),
          ),
          FieldLabel(
            'Prazo estimado',
            child: Wrap(
              spacing: 24,
              runSpacing: 8,
              children: [
                Text('Início: ${shortDate(task.start)}/${task.start.year}'),
                Text('Fim: ${shortDate(task.end)}/${task.end.year}'),
              ],
            ),
          ),
          FieldLabel(
            'Descrição',
            child: TextField(
              controller: _description,
              minLines: 3,
              maxLines: null,
              decoration: const InputDecoration(
                hintText: 'Adicionar descrição',
              ),
              onChanged: (value) =>
                  widget.controller.update(_task.copyWith(description: value)),
            ),
          ),
          FieldLabel(
            'Checklist',
            child: Material(
              color: FolksColors.field,
              borderRadius: BorderRadius.circular(10),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  ...task.checklist.indexed.map(
                    (entry) => CheckboxListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                      controlAffinity: ListTileControlAffinity.leading,
                      dense: true,
                      activeColor: FolksColors.green,
                      title: Text(
                        entry.$2.title,
                        style: TextStyle(
                          fontSize: 12,
                          color: entry.$2.done
                              ? FolksColors.muted
                              : FolksColors.white,
                          decoration: entry.$2.done
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                      value: entry.$2.done,
                      onChanged: (_) {
                        final items = List.of(task.checklist);
                        items[entry.$1] = entry.$2.toggle();
                        widget.controller.update(
                          task.copyWith(checklist: items),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 4, 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _checklistTitle,
                            maxLength: 180,
                            decoration: const InputDecoration(
                              hintText: '+ Adicionar item',
                              counterText: '',
                              labelText: 'Novo item do checklist',
                            ),
                            onSubmitted: (_) => _addChecklist(),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Adicionar item ao checklist',
                          onPressed: _addChecklist,
                          icon: const Icon(Icons.add),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          FieldLabel(
            'Anexos',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                OutlinedButton.icon(
                  onPressed: _picking ? null : _attach,
                  icon: _picking
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.attach_file, size: 18),
                  label: Text(_picking ? 'Anexando…' : 'Adicionar anexos'),
                ),
                ...task.attachments.indexed.map(
                  (entry) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.description_outlined),
                    title: Text(
                      entry.$2.name,
                      style: const TextStyle(fontSize: 12),
                    ),
                    trailing: IconButton(
                      tooltip: 'Remover anexo ${entry.$2.name}',
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        final attachments = List.of(task.attachments)
                          ..removeAt(entry.$1);
                        widget.controller.update(
                          task.copyWith(attachments: attachments),
                        );
                      },
                    ),
                  ),
                ),
                if (_attachmentError != null)
                  Text(
                    _attachmentError!,
                    style: const TextStyle(
                      color: FolksColors.red,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          SheetActions(
            primaryLabel: task.stage.following.isEmpty
                ? 'Última etapa do funil'
                : 'Avançar Etapa',
            onPrimary: task.stage.following.isEmpty
                ? null
                : () => showDialog<void>(
                    context: context,
                    builder: (_) => AdvanceStageDialog(
                      controller: widget.controller,
                      taskId: task.id,
                    ),
                  ),
            onClose: () => Navigator.pop(context),
          ),
        ],
      );
    },
  );
}

class AdvanceStageDialog extends StatefulWidget {
  const AdvanceStageDialog({
    super.key,
    required this.controller,
    required this.taskId,
  });
  final KanbanController controller;
  final String taskId;

  @override
  State<AdvanceStageDialog> createState() => _AdvanceStageDialogState();
}

class _AdvanceStageDialogState extends State<AdvanceStageDialog> {
  late final _task = widget.controller.tasks.firstWhere(
    (task) => task.id == widget.taskId,
  );
  late String _assignee = _task.assignee;
  late RecruitmentStage _stage = _task.stage.following.first;

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text(
      'AVANÇAR ETAPA',
      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
    ),
    content: SizedBox(
      width: 320,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FieldLabel(
              'Responsável',
              child: DropdownButtonFormField<String>(
                initialValue: _assignee,
                isExpanded: true,
                items: KanbanController.assignees
                    .map(
                      (name) => DropdownMenuItem(
                        value: name,
                        child: Text(name, style: const TextStyle(fontSize: 12)),
                      ),
                    )
                    .toList(),
                onChanged: (name) {
                  if (name != null) setState(() => _assignee = name);
                },
              ),
            ),
            FieldLabel(
              'Etapa seguinte',
              child: DropdownButtonFormField<RecruitmentStage>(
                initialValue: _stage,
                isExpanded: true,
                items: _task.stage.following
                    .map(
                      (stage) => DropdownMenuItem(
                        value: stage,
                        child: Text(stage.label),
                      ),
                    )
                    .toList(),
                onChanged: (stage) {
                  if (stage != null) setState(() => _stage = stage);
                },
              ),
            ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancelar'),
      ),
      PrimaryAction(
        label: 'Concluir',
        onPressed: () {
          widget.controller.advance(widget.taskId, _stage, _assignee);
          Navigator.pop(context);
        },
      ),
    ],
  );
}
