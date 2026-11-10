import 'package:folks_connect_backend/src/dto/csv_import.dart';
import 'package:folks_connect_backend/src/exceptions/api_error.dart';
import 'package:test/test.dart';

void main() {
  test('CSV preserva aspas, separadores, BOM e quebras dentro de campos', () {
    expect(
        CsvImport.parse('\uFEFFa;b\r\n"um;dois";"linha\ncom ""aspas"""\r\n'), [
      ['a', 'b'],
      ['um;dois', 'linha\ncom "aspas"'],
    ]);
  });
  test('CSV rejeita aspas quebradas e conteúdo depois de fechar campo', () {
    for (final source in ['a,b\n"ab', 'a,b\n"ab"c,d', 'a,b\na"b,c']) {
      expect(() => CsvImport.parse(source), throwsA(isA<ApiError>()));
    }
  });
  test('CSV recusa campos desconhecidos, duplicados e limite de registros', () {
    expect(() => CsvImport.vacancies('cargo,cargo\na,b'),
        throwsA(isA<ApiError>()));
    expect(() => CsvImport.parse('a\n${List.filled(1001, 'b').join('\n')}'),
        throwsA(isA<ApiError>()));
  });
}
