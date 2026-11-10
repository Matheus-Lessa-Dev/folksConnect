import '../database.dart';
import '../dto/candidate_input.dart';
import '../dto/input.dart';
import '../dto/validation.dart';
import '../repositories/candidates_repository.dart';
import '../security/identity.dart';

class CandidateService {
  final Database db;
  final CandidateRepository repository = CandidateRepository();
  CandidateService(this.db);
  Future<Row> list(int vacancy, QueryInput query) async {
    if (!await repository.vacancyExists(db, vacancy)) missing('Vaga');
    final status = query.values['status'];
    if (status != null && !CandidateInput.statuses.contains(status)) {
      invalid('Status de candidato inválido.');
    }
    return repository.list(db, vacancy, query);
  }

  Future<Row> get(int vacancy, int id) async {
    final result = await repository.find(db, vacancy, id);
    if (result == null) missing('Candidato da vaga');
    return result;
  }

  Future<Row> create(int vacancy, JsonInput input, Identity user) async {
    user.require('C');
    final data = CandidateInput.parse(input);
    if (!await repository.vacancyExists(db, vacancy)) missing('Vaga');
    return (await repository
        .create(db, {...data.parameters, 'vaga': vacancy}))!;
  }

  Future<Row> update(
      int vacancy, int id, JsonInput input, Identity user) async {
    user.require('D');
    return db.transaction((tx) async {
      final current = await repository.find(tx, vacancy, id, lock: true);
      if (current == null) missing('Candidato da vaga');
      final data = CandidateInput.parse(input, current: current);
      return (await repository
          .update(tx, {...data.parameters, 'id': id, 'vaga': vacancy}))!;
    });
  }

  Future<void> delete(int vacancy, int id, Identity user) async {
    user.require('D');
    if (await repository.delete(db, vacancy, id) == null) {
      missing('Candidato da vaga');
    }
  }
}
