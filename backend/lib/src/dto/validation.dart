import '../exceptions/api_error.dart';
import 'input.dart';

Never invalid(String message) => throw ApiError(400, 'validacao', message);
Never missing([String name = 'Registro']) =>
    throw ApiError(404, 'nao_encontrado', '$name não encontrado.');
Never conflict(String message) => throw ApiError(409, 'conflito', message);

String string(Map<String, dynamic> data, String key,
    {int max = 150, bool optional = false}) {
  final value = data[key];
  if (optional && value == null) return '';
  if (value is! String || value.trim().isEmpty || value.trim().length > max) {
    invalid('$key deve ser texto não vazio de até $max caracteres.');
  }
  return value.trim();
}

int integer(Object? value, String field, {int min = 1, int max = 2147483647}) {
  if (value is! int || value < min || value > max) {
    invalid('$field deve ser inteiro entre $min e $max.');
  }
  return value;
}

int routeId(String value) => integer(int.tryParse(value), 'id');
int queryInt(QueryInput query, String key, int fallback,
        {int max = 2147483647}) =>
    query.values.containsKey(key)
        ? integer(int.tryParse(query.values[key]!), key, max: max)
        : fallback;

List<int> ids(Object? value, String field) {
  if (value is! List || value.length > 100) {
    invalid('$field deve ser lista com até 100 IDs.');
  }
  final result = value.map((v) => integer(v, field)).toList();
  if (result.toSet().length != result.length) {
    invalid('$field contém IDs repetidos.');
  }
  return result;
}

String email(Map<String, dynamic> data, String key) {
  final value = string(data, key, max: 150).toLowerCase();
  if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value)) {
    invalid('E-mail inválido.');
  }
  return value;
}

String date(Map<String, dynamic> data, String key) {
  final value = string(data, key, max: 10);
  final parsed = DateTime.tryParse(value);
  if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value) ||
      parsed == null ||
      parsed.year < 1 ||
      parsed.toIso8601String().substring(0, 10) != value) {
    invalid('$key deve ser data válida YYYY-MM-DD.');
  }
  return value;
}

void dates(String start, String end) {
  if (end.compareTo(start) < 0) {
    invalid('prazoFinal deve ser igual ou posterior a prazoInicial.');
  }
}
