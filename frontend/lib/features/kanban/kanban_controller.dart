import 'package:flutter/foundation.dart';

import 'task.dart';

/// Estado de demonstracao. A API existente ainda so expoe health check.
/// O controller nao grava nem simula gravacao no backend.
class KanbanController extends ChangeNotifier {
  KanbanController({List<KanbanTask>? tasks})
    : _tasks = List.of(tasks ?? demoTasks());

  static const projects = [
    'Recrutamento',
    'Triagem',
    'Consultoria',
    'Financeiro',
    'Mentoria',
  ];
  static const companies = ['Faculdade Donaduzzi', 'Meta', 'Spotty'];
  static const roles = [
    'Analista Financeiro Jr.',
    'Desenvolvedor Sênior',
    'HelpDesk',
  ];
  static const assignees = [
    'Ana Munaro — Assistente',
    'Joabe — Analista',
    'Eduarda — Analista',
    'Matheus — Gerente',
  ];
  static const defaultChecklist = [
    ChecklistItem('Coletar currículos inscritos'),
    ChecklistItem('Filtrar por requisitos mínimos'),
    ChecklistItem('Marcar candidatos para entrevista'),
    ChecklistItem('Registrar motivo de reprovação dos demais'),
  ];

  final List<KanbanTask> _tasks;
  String _filter = 'Todos';
  bool _listView = false;
  int _sequence = 0;

  String get filter => _filter;
  bool get listView => _listView;
  List<KanbanTask> get tasks => List.unmodifiable(_tasks);
  List<KanbanTask> get visibleTasks => _tasks
      .where((task) => _filter == 'Todos' || task.project == _filter)
      .toList(growable: false);

  void filterBy(String project) {
    _filter = project;
    notifyListeners();
  }

  void setListView(bool value) {
    _listView = value;
    notifyListeners();
  }

  String nextId() =>
      'task-${DateTime.now().microsecondsSinceEpoch}-${_sequence++}';

  void add(KanbanTask task) {
    if (task.end.isBefore(task.start)) {
      throw ArgumentError('O fim deve ser igual ou posterior ao início.');
    }
    _tasks.add(task);
    // A tarefa recem-criada deve continuar visivel, mesmo sob outro filtro.
    if (_filter != 'Todos' && _filter != task.project) _filter = task.project;
    notifyListeners();
  }

  void update(KanbanTask task) {
    final index = _tasks.indexWhere((item) => item.id == task.id);
    if (index < 0) return;
    _tasks[index] = task;
    notifyListeners();
  }

  void advance(String id, RecruitmentStage stage, String assignee) {
    final task = _tasks.firstWhere((item) => item.id == id);
    if (!task.stage.following.contains(stage)) {
      throw ArgumentError('Selecione uma etapa posterior à etapa atual.');
    }
    update(task.copyWith(stage: stage, assignee: assignee));
  }

  static List<KanbanTask> demoTasks() {
    final now = DateTime.now();
    final day = DateTime(now.year, now.month, now.day);
    return [
      KanbanTask(
        id: 'demo-screening',
        title: 'Triagem — Analista Financeiro Jr.',
        project: 'Recrutamento',
        company: companies.first,
        role: roles.first,
        assignee: assignees[1],
        start: day,
        end: day.add(const Duration(days: 2)),
        priority: TaskPriority.high,
        description:
            'Fazer a triagem inicial de currículos recebidos, checar aderência ao perfil da vaga e sinalizar candidatos aptos para entrevista com o analista.',
        checklist: defaultChecklist,
      ),
      KanbanTask(
        id: 'demo-triage',
        title: 'Triagem de currículos',
        project: 'Triagem',
        company: companies[1],
        role: roles[1],
        assignee: assignees.first,
        start: day,
        end: day.add(const Duration(days: 3)),
        priority: TaskPriority.low,
        checklist: defaultChecklist,
      ),
      KanbanTask(
        id: 'demo-consulting',
        title: 'Consultoria — acompanhamento da equipe',
        project: 'Consultoria',
        company: companies[2],
        role: roles[2],
        assignee: assignees[2],
        start: day,
        end: day.add(const Duration(days: 4)),
        status: BoardStatus.inProgress,
      ),
      KanbanTask(
        id: 'demo-interview',
        title: 'Entrevistas — Desenvolvedor Sênior',
        project: 'Recrutamento',
        company: companies[1],
        role: roles[1],
        assignee: assignees[1],
        start: day,
        end: day.add(const Duration(days: 5)),
        status: BoardStatus.inProgress,
        stage: RecruitmentStage.interview,
        priority: TaskPriority.high,
        checklist: defaultChecklist,
      ),
    ];
  }
}
