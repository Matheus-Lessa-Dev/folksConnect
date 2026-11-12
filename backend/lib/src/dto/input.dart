import 'validation.dart';

/// Decoded JSON; each command explicitly whitelists its accepted fields.
class JsonInput {
  final Map<String, dynamic> values;
  JsonInput(Map<String, dynamic> values) : values = Map.unmodifiable(values);
  Map<String, dynamic> only(Set<String> allowed) {
    final extra = values.keys.toSet().difference(allowed);
    if (extra.isNotEmpty) {
      invalid('Campos não permitidos: ${extra.join(', ')}.');
    }
    return values;
  }
}

class QueryInput {
  final Map<String, String> values;
  QueryInput(Map<String, String> values) : values = Map.unmodifiable(values);
  void only(Set<String> allowed) {
    final extra = values.keys.toSet().difference(allowed);
    if (extra.isNotEmpty) {
      invalid('Filtros não permitidos: ${extra.join(', ')}.');
    }
  }

  int get page => queryInt(this, 'page', 1, max: 1000000);
  int get limit => queryInt(this, 'limit', 20, max: 100);
}
