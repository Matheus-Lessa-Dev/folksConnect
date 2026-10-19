import 'dart:typed_data';

enum BoardStatus {
  todo('A fazer'),
  inProgress('Em andamento'),
  waiting('Aguardando'),
  done('Concluído');

  const BoardStatus(this.label);
  final String label;
}

enum RecruitmentStage {
  screening('Triagem'),
  interview('Entrevista'),
  feedback('Retorno'),
  hiring('Contratação');

  const RecruitmentStage(this.label);
  final String label;

  List<RecruitmentStage> get following =>
      values.where((stage) => stage.index > index).toList();
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
    this.stage = RecruitmentStage.screening,
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
  final RecruitmentStage stage;
  final String description;
  final List<ChecklistItem> checklist;
  final List<TaskAttachment> attachments;

  KanbanTask copyWith({
    String? assignee,
    TaskPriority? priority,
    BoardStatus? status,
    RecruitmentStage? stage,
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
    description: description ?? this.description,
    checklist: checklist ?? this.checklist,
    attachments: attachments ?? this.attachments,
  );
}

String shortDate(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';
