import 'package:flutter/foundation.dart';

import '../vacancy_funnel/vacancy.dart';
import '../vacancy_funnel/vacancy_funnel_controller.dart';
import 'task.dart';

/// Estado de demonstracao. A API existente ainda so expoe health check.
/// O controller nao grava nem simula gravacao no backend.
class KanbanController extends ChangeNotifier {
  KanbanController({
    List<KanbanTask>? tasks,
    this.funnel,
  })  : _tasks = List.of(tasks ?? demoTasks()),
        _companies = List.of(defaultCompanies),
        _roles = List.of(defaultRoles) {
    if (funnel != null) {
      funnel!.onVacancyAdded = addVacancyTask;
      funnel!.addListener(_onFunnelChanged);
    }
  }

  final VacancyFunnelController? funnel;
  final List<String> _companies;
  final List<String> _roles;

  static const defaultCompanies = ['Faculdade Donaduzzi', 'Meta', 'Spotty'];
  static const defaultRoles = [
    'Analista Financeiro Jr.',
    'Desenvolvedor Sênior',
    'HelpDesk',
  ];
  static const projects = [
    'Recrutamento',
    'Triagem',
    'Consultoria',
    'Financeiro',
    'Mentoria',
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

  List<String> get companies {
    final list = <String>[..._companies];
    if (funnel != null) {
      for (final client in funnel!.clients) {
        if (!list.any((c) => c.toLowerCase() == client.company.toLowerCase())) {
          list.add(client.company);
        }
      }
      for (final vacancy in funnel!.vacancies) {
        if (!list.any((c) => c.toLowerCase() == vacancy.company.toLowerCase())) {
          list.add(vacancy.company);
        }
      }
    }
    for (final task in _tasks) {
      if (!list.any((c) => c.toLowerCase() == task.company.toLowerCase())) {
        list.add(task.company);
      }
    }
    return List.unmodifiable(list);
  }

  List<String> get roles {
    final list = <String>[..._roles];
    if (funnel != null) {
      for (final vacancy in funnel!.vacancies) {
        if (!list.any((r) => r.toLowerCase() == vacancy.role.toLowerCase())) {
          list.add(vacancy.role);
        }
      }
    }
    for (final task in _tasks) {
      if (!list.any((r) => r.toLowerCase() == task.role.toLowerCase())) {
        list.add(task.role);
      }
    }
    return List.unmodifiable(list);
  }

  FunnelVacancy? findVacancy({String? role, String? company}) {
    if (funnel == null) return null;
    if (role != null && company != null) {
      return funnel!.vacancies
          .where((v) =>
              v.role.toLowerCase() == role.toLowerCase() &&
              v.company.toLowerCase() == company.toLowerCase())
          .firstOrNull;
    }
    if (role != null) {
      return funnel!.vacancies
          .where((v) => v.role.toLowerCase() == role.toLowerCase())
          .firstOrNull;
    }
    if (company != null) {
      return funnel!.vacancies
          .where((v) => v.company.toLowerCase() == company.toLowerCase())
          .firstOrNull;
    }
    return null;
  }

  void addVacancyTask(FunnelVacancy vacancy) {
    if (!_companies
        .any((c) => c.toLowerCase() == vacancy.company.toLowerCase())) {
      _companies.add(vacancy.company);
    }
    if (!_roles.any((r) => r.toLowerCase() == vacancy.role.toLowerCase())) {
      _roles.add(vacancy.role);
    }
    final title = vacancy.role.toLowerCase().startsWith('triagem')
        ? vacancy.role
        : 'Triagem — ${vacancy.role}';
    final task = KanbanTask(
      id: nextId(),
      title: title,
      project: 'Recrutamento',
      company: vacancy.company,
      role: vacancy.role,
      assignee: normalizeAssignee(vacancy.assignee),
      start: vacancy.start,
      end: vacancy.end,
      priority: TaskPriority.medium,
      status: BoardStatus.todo,
      stage: RecruitmentStage.screening,
      description: vacancy.profile,
      checklist: defaultChecklist,
    );
    add(task);
  }

  static String normalizeAssignee(String value) {
    for (final a in assignees) {
      if (a.toLowerCase() == value.toLowerCase() ||
          a.replaceAll('—', '-').trim().toLowerCase() ==
              value.replaceAll('—', '-').trim().toLowerCase()) {
        return a;
      }
    }
    return value;
  }

  void _onFunnelChanged() {
    notifyListeners();
  }

  @override
  void dispose() {
    funnel?.removeListener(_onFunnelChanged);
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
        company: defaultCompanies.first,
        role: defaultRoles.first,
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
        company: defaultCompanies[1],
        role: defaultRoles[1],
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
        company: defaultCompanies[2],
        role: defaultRoles[2],
        assignee: assignees[2],
        start: day,
        end: day.add(const Duration(days: 4)),
        status: BoardStatus.inProgress,
      ),
      KanbanTask(
        id: 'demo-interview',
        title: 'Entrevistas — Desenvolvedor Sênior',
        project: 'Recrutamento',
        company: defaultCompanies[1],
        role: defaultRoles[1],
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
