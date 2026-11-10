import 'input.dart';
import 'vacancy_input.dart';
import 'validation.dart';

/// CSV UTF-8: comma or semicolon, escaped quotes and multiline quoted values.
class CsvImport {
  static List<List<String>> parse(String source) {
    if (source.startsWith('\uFEFF')) source = source.substring(1);
    final firstLine = source.split(RegExp(r'[\r\n]')).first;
    final separator = firstLine.contains(';') ? ';' : ',';
    final rows = <List<String>>[];
    var row = <String>[];
    var value = StringBuffer();
    var quoted = false;
    var closed = false;
    void field() {
      row.add(value.toString());
      value = StringBuffer();
      closed = false;
    }

    void record() {
      field();
      rows.add(row);
      row = <String>[];
      if (rows.length > 1001) {
        invalid('Importe no máximo 1000 vagas por arquivo.');
      }
    }

    for (var i = 0; i < source.length; i++) {
      final char = source[i];
      if (quoted) {
        if (char == '"') {
          if (i + 1 < source.length && source[i + 1] == '"') {
            value.write('"');
            i++;
          } else {
            quoted = false;
            closed = true;
          }
        } else {
          value.write(char);
        }
      } else if (char == separator) {
        field();
      } else if (char == '\r' || char == '\n') {
        if (char == '\r' && i + 1 < source.length && source[i + 1] == '\n') i++;
        record();
      } else if (char == '"') {
        if (closed || value.isNotEmpty) invalid('Aspas inválidas no CSV.');
        quoted = true;
      } else {
        if (closed) invalid('Texto depois do fechamento de aspas no CSV.');
        value.write(char);
      }
    }
    if (quoted) invalid('CSV com aspas sem fechamento.');
    if (row.isNotEmpty || value.isNotEmpty || closed) record();
    return rows;
  }

  static List<VacancyInput> vacancies(String source) {
    final rows = parse(source);
    if (rows.length < 2) {
      invalid('CSV deve conter cabeçalho e ao menos uma vaga.');
    }
    final headers = rows.first.map((h) => h.trim()).toList();
    if (headers.length != VacancyInput.fields.length ||
        headers.toSet().length != headers.length ||
        !headers.toSet().containsAll(VacancyInput.fields)) {
      invalid('Cabeçalho deve conter: ${VacancyInput.fields.join(',')}.');
    }
    final seen = <String>{};
    return [
      for (var i = 1; i < rows.length; i++)
        _vacancy(rows[i], headers, i + 1, seen)
    ];
  }

  static VacancyInput _vacancy(
      List<String> row, List<String> headers, int line, Set<String> seen) {
    if (row.length != headers.length) {
      invalid('Registro $line: quantidade de colunas inválida.');
    }
    final data = <String, dynamic>{
      for (var i = 0; i < headers.length; i++) headers[i]: row[i].trim()
    };
    // Length prefixes avoid ambiguous duplicate keys when quoted fields contain delimiters.
    final fingerprint = row.map((v) => '${v.trim().length}:${v.trim()}').join();
    if (!seen.add(fingerprint)) {
      invalid('Registro $line: vaga duplicada no arquivo.');
    }
    for (final field in ['clienteId', 'responsavelId']) {
      data[field] = integer(
          int.tryParse(data[field] as String), 'Registro $line: $field');
    }
    final channels = data['canais'] as String;
    data['canais'] = channels.isEmpty
        ? <int>[]
        : channels
            .split('|')
            .map((v) =>
                integer(int.tryParse(v.trim()), 'Registro $line: canais'))
            .toList();
    return VacancyInput.create(JsonInput(data));
  }
}
