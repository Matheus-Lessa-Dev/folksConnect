import 'package:flutter/foundation.dart';

import '../kanban/task.dart';
import 'vacancy.dart';

/// Dados de demonstração, mantidos somente em memória durante a sessão.
class VacancyFunnelController extends ChangeNotifier {
  VacancyFunnelController({List<FunnelVacancy>? vacancies, DateTime? now})
    : _vacancies = List.of(vacancies ?? demoVacancies(now ?? DateTime.now()));

  final List<FunnelVacancy> _vacancies;
  final List<VacancyClient> _clients = [
    const VacancyClient(company: 'Faculdade Donaduzzi'),
    const VacancyClient(company: 'Meta'),
    const VacancyClient(company: 'Spotfy'),
  ];
  int _sequence = 0;

  static const assignees = [
    'Eduarda - Analista',
    'Ana Munaro - Assistente',
    'Joabe - Analista',
    'Matheus - Gerente',
  ];

  List<FunnelVacancy> get vacancies => List.unmodifiable(_vacancies);
  List<VacancyClient> get clients => List.unmodifiable(_clients);

  void addClient(VacancyClient client) {
    if (client.company.trim().isEmpty) {
      throw ArgumentError('Informe a empresa.');
    }
    if (_clients.any(
      (item) => item.company.toLowerCase() == client.company.toLowerCase(),
    )) {
      throw ArgumentError('Este cliente já está cadastrado.');
    }
    _clients.add(client);
    notifyListeners();
  }

  void add({
    required String role,
    required String company,
    required String profile,
    required String assignee,
    required DateTime start,
    required DateTime end,
    required List<String> channels,
  }) {
    if (role.trim().isEmpty || profile.trim().isEmpty) {
      throw ArgumentError('Informe o cargo e o perfil desejado.');
    }
    if (!_clients.any((client) => client.company == company) ||
        !assignees.contains(assignee)) {
      throw ArgumentError('Selecione um cliente e um responsável válidos.');
    }
    if (end.isBefore(start)) {
      throw ArgumentError('O fim deve ser igual ou posterior ao início.');
    }
    if (channels.isEmpty || channels.any((channel) => channel.trim().isEmpty)) {
      throw ArgumentError('Selecione ao menos um canal de divulgação.');
    }
    _vacancies.add(
      FunnelVacancy(
        id: 'vacancy-${DateTime.now().microsecondsSinceEpoch}-${_sequence++}',
        role: role.trim(),
        company: company,
        profile: profile.trim(),
        assignee: assignee,
        start: start,
        end: end,
        channels: List.unmodifiable(channels),
      ),
    );
    notifyListeners();
  }

  static List<FunnelVacancy> demoVacancies(DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    return [
      FunnelVacancy(
        id: 'demo-financial',
        role: 'Analista Financeiro Jr.',
        company: 'Faculdade Donaduzzi',
        profile: 'Análise financeira e organização de indicadores.',
        assignee: assignees.first,
        start: today.subtract(const Duration(days: 9)),
        end: today.subtract(const Duration(days: 1)),
        stage: RecruitmentStage.interview,
        applicants: 26,
        idealPercentage: 58,
      ),
      FunnelVacancy(
        id: 'demo-developer',
        role: 'Desenvolvedor Sênior',
        company: 'Meta',
        profile: 'Desenvolvimento e manutenção de sistemas.',
        assignee: assignees.first,
        start: today.subtract(const Duration(days: 3)),
        end: today.add(const Duration(days: 12)),
        stage: RecruitmentStage.interview,
        applicants: 50,
        idealPercentage: 25,
      ),
      FunnelVacancy(
        id: 'demo-helpdesk',
        role: 'HelpDesk',
        company: 'Spotfy',
        profile: 'Suporte técnico e atendimento ao usuário.',
        assignee: assignees.first,
        start: today.subtract(const Duration(days: 4)),
        end: today.add(const Duration(days: 2)),
        stage: RecruitmentStage.feedback,
        applicants: 38,
        idealPercentage: 41,
      ),
    ];
  }
}
