import '../kanban/task.dart';

/// Modelo de apresentação; não representa o contrato do banco ou da API.
class FunnelVacancy {
  const FunnelVacancy({
    required this.id,
    required this.role,
    required this.company,
    required this.profile,
    required this.assignee,
    required this.start,
    required this.end,
    this.channels = const [],
    this.stage = RecruitmentStage.screening,
    this.applicants = 0,
    this.idealPercentage = 0,
    this.screeningErrors = 0,
  });

  final String id;
  final String role;
  final String company;
  final String profile;
  final String assignee;
  final DateTime start;
  final DateTime end;
  final List<String> channels;
  final RecruitmentStage stage;
  final int applicants;
  final int idealPercentage;
  final int screeningErrors;

  int daysOpen(DateTime now) => _day(now).difference(_day(start)).inDays;

  VacancyDeadline deadline(DateTime now) {
    final remaining = _day(end).difference(_day(now)).inDays;
    if (remaining < 0) return VacancyDeadline.overdue;
    if (remaining <= 3) return VacancyDeadline.closing;
    return VacancyDeadline.onTime;
  }

  static DateTime _day(DateTime value) =>
      DateTime(value.year, value.month, value.day);
}

enum VacancyDeadline {
  overdue('Atrasado'),
  onTime('Em dia'),
  closing('Perto de Fechar');

  const VacancyDeadline(this.label);
  final String label;
}

class VacancyClient {
  const VacancyClient({
    required this.company,
    this.cnpj = '',
    this.representative = '',
    this.contact = '',
    this.email = '',
  });

  final String company;
  final String cnpj;
  final String representative;
  final String contact;
  final String email;
}
