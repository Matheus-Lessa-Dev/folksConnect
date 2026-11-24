import 'dart:typed_data';

class BoardStatus {
  const BoardStatus(this.label);
  static const todo = BoardStatus('A fazer');
  static const inProgress = BoardStatus('Em andamento');
  static const waiting = BoardStatus('Aguardando');
  static const done = BoardStatus('Concluído');
  static const values = [todo, inProgress, waiting, done];

  final String label;

  @override
  bool operator ==(Object other) =>
      other is BoardStatus && other.label.toLowerCase() == label.toLowerCase();

  @override
  int get hashCode => label.toLowerCase().hashCode;
}

enum TaskPriority {
  high('Alta'),
  medium('Média'),
  low('Baixa');

  const TaskPriority(this.label);
  final String label;
}

class ChecklistItem {
  const ChecklistItem(this.title, {this.done = false});
  final String title;
  final bool done;
  ChecklistItem toggle() => ChecklistItem(title, done: !done);
}

class TaskAttachment {
  const TaskAttachment({required this.name, required this.bytes});
  final String name;
  final Uint8List bytes;
}

class KanbanTask {
  KanbanTask({
    required this.id,
    required this.title,
    required this.project,
    required this.company,
    required this.role,
    required this.assignee,
    required this.start,
    required this.end,
    this.priority = TaskPriority.medium,
    this.status = BoardStatus.todo,
    this.stage = 0,
    this.completedAt,
    this.description = '',
    List<ChecklistItem> checklist = const [],
    List<TaskAttachment> attachments = const [],
  }) : checklist = List.unmodifiable(checklist),
       attachments = List.unmodifiable(attachments);

  final String id;
  final String title;
  final String project;
  final String company;
  final String role;
  final String assignee;
  final DateTime start;
  final DateTime end;
  final TaskPriority priority;
  final BoardStatus status;

  /// Posição da etapa na lista de etapas do funil (Configurações).
  final int stage;
  final DateTime? completedAt;
  final String description;
  final List<ChecklistItem> checklist;
  final List<TaskAttachment> attachments;

  KanbanTask copyWith({
    String? assignee,
    TaskPriority? priority,
    BoardStatus? status,
    int? stage,
    DateTime? completedAt,
    String? description,
    List<ChecklistItem>? checklist,
    List<TaskAttachment>? attachments,
  }) => KanbanTask(
    id: id,
    title: title,
    project: project,
    company: company,
    role: role,
    assignee: assignee ?? this.assignee,
    start: start,
    end: end,
    priority: priority ?? this.priority,
    status: status ?? this.status,
    stage: stage ?? this.stage,
    completedAt: (status ?? this.status) == BoardStatus.done
        ? completedAt ?? this.completedAt
        : null,
    description: description ?? this.description,
    checklist: checklist ?? this.checklist,
    attachments: attachments ?? this.attachments,
  );
}

String shortDate(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';
