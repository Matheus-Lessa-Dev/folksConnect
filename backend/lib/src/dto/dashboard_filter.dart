import 'input.dart';
import 'validation.dart';

class DashboardFilter {
  final String start;
  final String end;
  final int? responsible;
  final int? project;
  DashboardFilter(this.start, this.end, this.responsible, this.project);
  factory DashboardFilter.parse(QueryInput query) {
    query.only({'dataInicial', 'dataFinal', 'responsavelId', 'projetoId'});
    final now = DateTime.now().toUtc();
    final today = DateTime.utc(now.year, now.month, now.day);
    final start = query.values.containsKey('dataInicial')
        ? date(query.values, 'dataInicial')
        : today
            .subtract(const Duration(days: 29))
            .toIso8601String()
            .substring(0, 10);
    final end = query.values.containsKey('dataFinal')
        ? date(query.values, 'dataFinal')
        : today.toIso8601String().substring(0, 10);
    dates(start, end);
    if (DateTime.parse(end).difference(DateTime.parse(start)).inDays > 366) {
      invalid('Consulte no máximo 367 dias por vez.');
    }
    int? id(String field) => query.values.containsKey(field)
        ? integer(int.tryParse(query.values[field]!), field)
        : null;
    return DashboardFilter(start, end, id('responsavelId'), id('projetoId'));
  }
  Map<String, Object?> get parameters => {
        'inicio': start,
        'fim': end,
        'responsavel': responsible,
        'projeto': project
      };
  Map<String, Object?> get json => {
        'dataInicial': start,
        'dataFinal': end,
        'responsavelId': responsible,
        'projetoId': project
      };
}
