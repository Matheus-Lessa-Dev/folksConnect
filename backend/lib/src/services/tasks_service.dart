import '../repositories/tasks_repository.dart';
import '../dto/task_dto.dart';

import '../repositories/shared_repository.dart';
import '../database.dart';
import '../dto/input.dart';
import '../dto/validation.dart';
import '../security.dart';

class TaskService {
  final Database db;
  final TaskRepository repository = TaskRepository();
  TaskService(this.db);

  Future<Row> details(Database tx, int id) async {
    final row = await repository.findDetails(tx, {'id': id});
    if (row == null) missing('Tarefa');
    final result = serializeTask(row);
    result['checklist'] = await repository.checklist(tx, {'id': id});
    result['anexos'] = await repository.attachments(tx, {'id': id});
    result['avancos'] = await repository.advances(tx, {'id': id});
    return result;
  }

  Future<Row> get(int id) => db.transaction((tx) async {
        await repository.snapshot(tx);
        return await details(tx, id);
      });

  Future<Row> list(QueryInput query) => repository.list(db, query);

  Future<Row> create(JsonInput input, Identity user) async {
    user.require('B');
    final data = input.only({
      'titulo',
      'descricao',
      'projetoId',
      'clienteId',
      'cargo',
      'responsavelId',
      'prazoInicial',
      'prazoFinal',
      'prioridadeId'
    });
    final args = <String, Object?>{
      'titulo': string(data, 'titulo'),
      'descricao': description(data),
      'cargo': string(data, 'cargo', max: 80),
      'projeto': integer(data['projetoId'], 'projetoId'),
      'cliente': integer(data['clienteId'], 'clienteId'),
      'responsavel': integer(data['responsavelId'], 'responsavelId'),
      'prioridade': integer(data['prioridadeId'], 'prioridadeId'),
      'inicio': date(data, 'prazoInicial'),
      'fim': date(data, 'prazoFinal'),
    };
    dates(args['inicio'] as String, args['fim'] as String);
    return db.transaction((tx) async {
      await repository.lockConfiguration(tx);
      await reference(tx, 'projetos', 'id_projeto', args['projeto'] as int);
      await reference(tx, 'clientes', 'id_cliente', args['cliente'] as int);
      await reference(tx, 'usuarios', 'id_usuario', args['responsavel'] as int,
          active: true);
      await reference(
          tx, 'prioridades', 'id_prioridade', args['prioridade'] as int);
      final row = await repository.insertTask(tx, args);
      final id = row!['id_tarefa'] as int;
      await repository.copyChecklist(tx, {'id': id});
      return await details(tx, id);
    });
  }

  Future<void> lock(Database tx, int id) async {
    if (await repository.lockTask(tx, {'id': id}) == null) {
      missing('Tarefa');
    }
  }

  Future<Row> update(JsonInput input, Identity user, int id) async {
    user.require('B');
    final data = input.only({'responsavelId', 'prioridadeId', 'descricao'});
    if (data.isEmpty) invalid('Informe ao menos um campo editável.');
    return db.transaction((tx) async {
      await lock(tx, id);
      final args = <String, Object?>{'id': id};
      if (data.containsKey('responsavelId')) {
        final value = integer(data['responsavelId'], 'responsavelId');
        await reference(tx, 'usuarios', 'id_usuario', value, active: true);
        args['responsavel'] = value;
      }
      if (data.containsKey('prioridadeId')) {
        final value = integer(data['prioridadeId'], 'prioridadeId');
        await reference(tx, 'prioridades', 'id_prioridade', value);
        args['prioridade'] = value;
      }
      if (data.containsKey('descricao')) {
        if (data['descricao'] == null) invalid('descricao não pode ser nula.');
        args['descricao'] = description(data);
      }
      await repository.updateTask(tx, args);
      return await details(tx, id);
    });
  }

  Future<Row> move(JsonInput input, Identity user, int id) async {
    user.require('B');
    final data = input.only({'statusId'});
    final status = integer(data['statusId'], 'statusId');
    return db.transaction((tx) async {
      await repository.lockStatusConfiguration(tx);
      await lock(tx, id);
      await reference(tx, 'etapas_kanban', 'id', status);
      final current = (await repository.completionState(tx, id))!;
      if (current['status_id'] != status && current['final_id'] == status) {
        await repository.recordDelivery(tx, {
          'id': id,
          'responsavel': current['id_usuario'],
          'autor': user.id,
          'projeto': current['id_projeto']
        });
      }
      await repository.updateStatus(tx, {'id': id, 'status': status});
      return await details(tx, id);
    });
  }

  Future<Row> advance(JsonInput input, Identity user, int id) async {
    user.require('B');
    final data = input.only({'etapaId', 'responsavelId'});
    final stage = integer(data['etapaId'], 'etapaId');
    final responsible = integer(data['responsavelId'], 'responsavelId');
    return db.transaction((tx) async {
      await repository.lockAdvanceConfiguration(tx);
      await lock(tx, id);
      final current = await repository.findCurrentStage(tx, {'id': id});
      final next = await repository.findNextStage(tx, {'id': stage});
      if (next == null) invalid('Etapa inexistente.');
      if ((next['ordem'] as int) <= (current!['ordem'] as int)) {
        conflict('O avanço exige uma etapa posterior à atual.');
      }
      await reference(tx, 'usuarios', 'id_usuario', responsible, active: true);
      await repository.updateStage(
          tx, {'id': id, 'etapa': stage, 'responsavel': responsible});
      await repository.insertAdvance(tx, {
        'id': id,
        'anterior': current['etapa_id'],
        'etapa': stage,
        'responsavel': responsible,
        'autor': user.id
      });
      return await details(tx, id);
    });
  }

  Future<Row> addItem(JsonInput input, Identity user, int id) async {
    user.require('B');
    final data = input.only({'nome'});
    final name = string(data, 'nome');
    return db.transaction((tx) async {
      await lock(tx, id);
      final item =
          await repository.insertChecklistItem(tx, {'id': id, 'nome': name});
      return item!;
    });
  }

  Future<Row> checkItem(
      JsonInput input, Identity user, int id, int itemId) async {
    user.require('B');
    final data = input.only({'concluido'});
    final checked = data['concluido'];
    if (checked is! bool) invalid('concluido deve ser booleano.');
    final row = await repository
        .checkItem(db, {'id': id, 'item': itemId, 'checked': checked});
    if (row == null) missing('Item da tarefa');
    return row;
  }
}
