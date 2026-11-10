import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../database.dart';
import '../dto/csv_import.dart';
import '../dto/validation.dart';
import '../exceptions/api_error.dart';
import '../repositories/imports_repository.dart';
import '../security/identity.dart';
import 'vacancies_service.dart';

class ImportService {
  final Database db;
  final VacancyService vacancies;
  final ImportRepository repository = ImportRepository();
  ImportService(this.db, this.vacancies);
  Future<Row> get(int id, Identity user) async {
    user.require('A');
    final row = await repository.details(db, id, user.id, user.admin);
    if (row == null) missing('Importação');
    return row;
  }

  Future<(Row, bool)> create(String csv, String key, Identity user) async {
    user.require('A');
    user.require('C');
    if (!RegExp(r'^[A-Za-z0-9_-]{1,100}$').hasMatch(key)) {
      invalid('X-Idempotency-Key deve ter de 1 a 100 letras, números, _ ou -.');
    }
    final rows = CsvImport.vacancies(csv);
    final checksum = sha256.convert(utf8.encode(csv)).toString();
    return db.transaction((tx) async {
      await repository.lock(tx, user.id, key);
      final existing = await repository.findByKey(tx, user.id, key);
      if (existing != null) {
        if (existing['checksum'] != checksum) {
          conflict('Chave de importação já usada para outro arquivo.');
        }
        return (
          (await repository.details(
              tx, existing['id'] as int, user.id, user.admin))!,
          false
        );
      }
      final batch = (await repository.create(tx, {
        'autor': user.id,
        'chave': key,
        'checksum': checksum,
        'quantidade': rows.length
      }))!['id'] as int;
      for (var i = 0; i < rows.length; i++) {
        try {
          final vacancy = await vacancies.insert(tx, rows[i]);
          await repository.link(tx, batch, vacancy['id'] as int);
        } on ApiError catch (e) {
          throw ApiError(e.status, e.code, 'Registro ${i + 2}: ${e.message}');
        }
      }
      return (
        (await repository.details(tx, batch, user.id, user.admin))!,
        true
      );
    });
  }
}
