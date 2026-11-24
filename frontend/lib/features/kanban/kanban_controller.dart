import 'package:flutter/foundation.dart';

import 'task.dart';
import '../../core/funnel_stages.dart';
import '../settings/settings_controller.dart';

/// Estado de demonstracao. A API existente ainda so expoe health check.
/// O controller nao grava nem simula gravacao no backend.
class KanbanController extends ChangeNotifier {
  KanbanController({
    List<KanbanTask>? tasks,
    DateTime Function()? now,
    FunnelStages? stages,
    this.settings,
  }) : stages = stages ?? FunnelStages(),
       _tasks = List.of(tasks ?? demoTasks()),
       _now = now ?? DateTime.now {
    this.stages.addListener(_stagesChanged);
    settings?.addListener(_configurationChanged);
  }

  /// Etapas do funil cadastradas em Configurações.
  final FunnelStages stages;
  final SettingsController? settings;

  List<ChecklistItem> get configuredChecklist => settings == null
      ? defaultChecklist
      : settings!.checklist.map(ChecklistItem.new).toList();

  void _stagesChanged() {
    for (var index = 0; index < _tasks.length; index++) {
      final task = _tasks[index];
      _tasks[index] = task.copyWith(stage: stages.remapPrevious(task.stage));
    }
    notifyListeners();
  }

  List<BoardStatus> get boardStatuses => settings == null
      ? BoardStatus.values
      : settings!.kanbanStages.map(BoardStatus.new).toList(growable: false);

  void _configurationChanged() {
    final statuses = boardStatuses;
    for (var index = 0; index < _tasks.length; index++) {
      final task = _tasks[index];
      final items = task.checklist.indexed.toList();
      final order = settings!.checklist;
      items.sort((a, b) {
        final ai = order.indexOf(a.$2.title);
        final bi = order.indexOf(b.$2.title);
        final comparison = (ai < 0 ? order.length : ai).compareTo(
          bi < 0 ? order.length : bi,
        );
        return comparison == 0 ? a.$1.compareTo(b.$1) : comparison;
      });
      _tasks[index] = task.copyWith(
        status: statuses.contains(task.status) ? task.status : statuses.first,
        checklist: items.map((item) => item.$2).toList(),
      );
    }
    notifyListeners();
  }

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
  final DateTime Function() _now;
  String _filter = 'Todos';
  bool _listView = false;
  int _sequence = 0;

  String get filter => _filter;
  bool get listView => _listView;
  List<KanbanTask> get tasks => List.unmodifiable(_tasks);
  List<KanbanTask> get visibleTasks => _tasks
      .where((task) => _filter == 'Todos' || task.project == _filter)
      .toList(growable: false);

  @override
  void dispose() {
    stages.removeListener(_stagesChanged);
    settings?.removeListener(_configurationChanged);
    super.dispose();
  }

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
    if (!boardStatuses.contains(task.status)) {
      task = task.copyWith(status: boardStatuses.first);
    }
    _tasks.add(
      task.status == BoardStatus.done && task.completedAt == null
          ? task.copyWith(completedAt: _now())
          : task,
    );
    // A tarefa recem-criada deve continuar visivel, mesmo sob outro filtro.
    if (_filter != 'Todos' && _filter != task.project) _filter = task.project;
    notifyListeners();
  }

  void update(KanbanTask task) {
    final index = _tasks.indexWhere((item) => item.id == task.id);
    if (index < 0) return;
    final previous = _tasks[index];
    _tasks[index] = task.status == BoardStatus.done
        ? task.copyWith(
            completedAt: previous.status == BoardStatus.done
                ? previous.completedAt ?? _now()
                : _now(),
          )
        : task.copyWith();
    notifyListeners();
  }

  void advance(String id, int stage, String assignee) {
    final task = _tasks.firstWhere((item) => item.id == id);
    if (!stages.following(task.stage).contains(stage)) {
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
        stage: 1,
        priority: TaskPriority.high,
        checklist: defaultChecklist,
      ),
    ];
  }
}
