import '../repositories/vacancies_repository.dart';
import '../dto/vacancy_input.dart';
import '../dto/vacancy_dto.dart';

import '../repositories/shared_repository.dart';
import '../database.dart';
import '../dto/input.dart';
import '../dto/validation.dart';
import '../security.dart';

class VacancyService {
  final Database db;
  final VacancyRepository repository = VacancyRepository();
  VacancyService(this.db);

  Future<Row> list(QueryInput query) => repository.list(db, query);

  Future<Row> get(int id) async {
    final row = await repository.findDetails(db, {'id': id});
    if (row == null) missing('Vaga');
    return serializeVacancy(row);
  }

  Future<Row> update(int id, JsonInput input, Identity user) async {
    user.require('D');
    final patch = input.only({...VacancyInput.fields, 'etapaId'});
    if (patch.isEmpty) invalid('Informe ao menos um campo editável.');
    return db.transaction((tx) async {
      await repository.lockConfiguration(tx);
      final current = await repository.lock(tx, id);
      if (current == null) missing('Vaga');
      final details =
          serializeVacancy((await repository.findDetails(tx, {'id': id}))!);
      final data = VacancyInput.create(JsonInput({
        for (final key in VacancyInput.fields) key: details[key],
        'canais': (details['canais'] as List).map((c) => c['id']).toList(),
        for (final entry in patch.entries)
          if (entry.key != 'etapaId') entry.key: entry.value,
      }));
      final stage = patch.containsKey('etapaId')
          ? integer(patch['etapaId'], 'etapaId')
          : current['etapa_id'] as int;
      final next = await repository.stage(tx, stage);
      if (next == null) invalid('Etapa inexistente.');
      if ((next['ordem'] as int) < (current['ordem'] as int)) {
        conflict('A vaga só pode avançar para uma etapa posterior.');
      }
      await validateReferences(tx, data);
      await repository
          .update(tx, {...data.parameters, 'id': id, 'etapa': stage});
      await repository.clearChannels(tx, id);
      for (final channel in data.channels) {
        await repository.insertChannel(tx, {'canal': channel, 'vaga': id});
      }
      return serializeVacancy((await repository.findDetails(tx, {'id': id}))!);
    });
  }

  Future<void> validateReferences(Database tx, VacancyInput data) async {
    await reference(
        tx, 'clientes', 'id_cliente', data.parameters['cliente'] as int);
    await reference(
        tx, 'usuarios', 'id_usuario', data.parameters['responsavel'] as int,
        active: true);
    for (final channel in data.channels) {
      await reference(tx, 'divulgacoes', 'id_divulgacao', channel);
    }
  }

  /// Reused by the CSV import inside its enclosing transaction.
  Future<Row> insert(Database tx, VacancyInput data) async {
    await repository.lockConfiguration(tx);
    await validateReferences(tx, data);
    final row = (await repository.insertVacancy(tx, data.parameters))!;
    final id = row['id_vaga'] as int;
    for (final channel in data.channels) {
      await repository.insertChannel(tx, {'canal': channel, 'vaga': id});
    }
    return serializeVacancy((await repository.findDetails(tx, {'id': id}))!);
  }

  Future<Row> create(JsonInput input, Identity user) async {
    user.require('C');
    final data = VacancyInput.create(input);
    return db.transaction((tx) => insert(tx, data));
  }
}
