import '../database.dart';
import '../dto/input.dart';
import '../dto/validation.dart';
import 'shared_repository.dart';
import '../dto/task_dto.dart';

const taskFrom = '''FROM tarefas t
  JOIN usuarios u ON u.id_usuario = t.id_usuario
  LEFT JOIN clientes c ON c.id_cliente = t.id_cliente
  LEFT JOIN projetos p ON p.id_projeto = t.id_projeto
  LEFT JOIN prioridades pr ON pr.id_prioridade = t.id_prioridade
  JOIN etapas_kanban k ON k.id = t.status_id
  JOIN etapas_funil f ON f.id = t.etapa_id''';
const taskSelect =
    '''t.*, u.nome AS responsavel, c.nome AS empresa, p.nome AS projeto,
  pr.nome AS prioridade, k.nome AS status, f.nome AS etapa''';

class TaskRepository {
  Future<Row?> completionState(Database db, int id) => db.one('''
    SELECT t.status_id, t.id_usuario, t.id_projeto,
      (SELECT id FROM etapas_kanban ORDER BY ordem DESC, id DESC LIMIT 1) AS final_id
    FROM tarefas t WHERE t.id_tarefa = @id''', {'id': id});
  Future<void> recordDelivery(Database db, Map<String, Object?> args) async {
    await db.query(
        '''INSERT INTO entregas_tarefa (tarefa_id, responsavel_id, autor_id, projeto_id)
      VALUES (@id, @responsavel, @autor, @projeto)''', args);
  }

  Future<Row> list(Database db, QueryInput query) async {
    const filters = {
      'projetoId': 't.id_projeto',
      'statusId': 't.status_id',
      'etapaId': 't.etapa_id',
      'responsavelId': 't.id_usuario',
      'prioridadeId': 't.id_prioridade',
      'clienteId': 't.id_cliente'
    };
    query.only({
      ...filters.keys,
      'busca',
      'prazoInicial',
      'prazoFinal',
      'page',
      'limit'
    });
    final where = <String>['TRUE'];
    final params = <String, Object?>{};
    for (final filter in filters.entries) {
      final value = query.values[filter.key];
      if (value == null) continue;
      params[filter.key] = integer(int.tryParse(value), filter.key);
      where.add('${filter.value} = @${filter.key}');
    }
    final search = query.values['busca'];
    if (search != null) {
      if (search.length > 150) invalid('busca deve ter até 150 caracteres.');
      params['busca'] = '%$search%';
      where.add(
          '(t.titulo ILIKE @busca OR t.descricao ILIKE @busca OR t.cargo ILIKE @busca)');
    }
    for (final key in ['prazoInicial', 'prazoFinal']) {
      if (query.values.containsKey(key)) {
        params[key] = date(query.values, key);
        where.add(
            '${key == 'prazoInicial' ? 't.prazo_inicial >=' : 't.prazo_final <='} CAST(@$key AS date)');
      }
    }
    if (params.containsKey('prazoInicial') &&
        params.containsKey('prazoFinal')) {
      dates(params['prazoInicial'] as String, params['prazoFinal'] as String);
    }
    return page(db, query, taskSelect, taskFrom, where.join(' AND '), params,
        't.id_tarefa DESC',
        map: serializeTask);
  }

  Future<Row?> checkItem(Database session,
          [Map<String, Object?> args = const {}]) =>
      session.one('''UPDATE itens_checklist_tarefa SET concluido = @checked
      WHERE id = @item AND tarefa_id = @id RETURNING id, nome, concluido, ordem''',
          args);

  Future<Row?> insertChecklistItem(Database session,
          [Map<String, Object?> args = const {}]) =>
      session.one('''INSERT INTO itens_checklist_tarefa (tarefa_id, nome, ordem)
        VALUES (@id, @nome, (SELECT coalesce(max(ordem), -1) + 1 FROM itens_checklist_tarefa WHERE tarefa_id = @id))
        RETURNING id, nome, concluido, ordem''', args);

  Future<List<Row>> insertAdvance(Database session,
          [Map<String, Object?> args = const {}]) =>
      session.query(
          '''INSERT INTO avancos_tarefa (tarefa_id, etapa_anterior_id, etapa_id, responsavel_id, autor_id)
        VALUES (@id, @anterior, @etapa, @responsavel, @autor)''', args);

  Future<List<Row>> updateStage(Database session,
          [Map<String, Object?> args = const {}]) =>
      session.query(
          'UPDATE tarefas SET etapa_id = @etapa, id_usuario = @responsavel WHERE id_tarefa = @id',
          args);

  Future<Row?> findNextStage(Database session,
          [Map<String, Object?> args = const {}]) =>
      session.one('SELECT ordem FROM etapas_funil WHERE id = @id', args);

  Future<Row?> findCurrentStage(Database session,
          [Map<String, Object?> args = const {}]) =>
      session.one('''SELECT t.etapa_id, e.ordem FROM tarefas t
        JOIN etapas_funil e ON e.id = t.etapa_id WHERE t.id_tarefa = @id''',
          args);

  Future<List<Row>> lockAdvanceConfiguration(Database session,
          [Map<String, Object?> args = const {}]) =>
      session.query('SELECT pg_advisory_xact_lock_shared(736289142)', args);

  Future<List<Row>> updateStatus(Database session,
          [Map<String, Object?> args = const {}]) =>
      session.query(
          'UPDATE tarefas SET status_id = @status WHERE id_tarefa = @id', args);

  Future<List<Row>> lockStatusConfiguration(Database session,
          [Map<String, Object?> args = const {}]) =>
      session.query('SELECT pg_advisory_xact_lock_shared(736289142)', args);

  Future<List<Row>> updateTask(Database session, Map<String, Object?> args) {
    const columns = {
      'responsavel': 'id_usuario',
      'prioridade': 'id_prioridade',
      'descricao': 'descricao'
    };
    final fields = [
      for (final entry in columns.entries)
        if (args.containsKey(entry.key)) '${entry.value} = @${entry.key}'
    ];
    return session.query(
        'UPDATE tarefas SET ${fields.join(', ')} WHERE id_tarefa = @id', args);
  }

  Future<Row?> lockTask(Database session,
          [Map<String, Object?> args = const {}]) =>
      session.one(
          'SELECT id_tarefa FROM tarefas WHERE id_tarefa = @id FOR UPDATE',
          args);

  Future<List<Row>> copyChecklist(Database session,
          [Map<String, Object?> args = const {}]) =>
      session.query(
          '''INSERT INTO itens_checklist_tarefa (tarefa_id, modelo_id, nome, ordem)
        SELECT @id, id_checklist, nome, ordem FROM checklists ORDER BY ordem, id_checklist''',
          args);

  Future<Row?> insertTask(Database session,
          [Map<String, Object?> args = const {}]) =>
      session.one('''INSERT INTO tarefas
        (titulo, descricao, cargo, id_projeto, id_cliente, id_usuario, id_prioridade, prazo_inicial, prazo_final, status_id, etapa_id)
        VALUES (@titulo, @descricao, @cargo, @projeto, @cliente, @responsavel, @prioridade, CAST(@inicio AS date), CAST(@fim AS date),
          (SELECT id FROM etapas_kanban ORDER BY ordem, id LIMIT 1), (SELECT id FROM etapas_funil ORDER BY ordem, id LIMIT 1))
        RETURNING id_tarefa''', args);

  Future<List<Row>> lockConfiguration(Database session,
          [Map<String, Object?> args = const {}]) =>
      session.query('SELECT pg_advisory_xact_lock_shared(736289142)', args);

  Future<List<Row>> snapshot(Database session,
          [Map<String, Object?> args = const {}]) =>
      session.query('SET TRANSACTION ISOLATION LEVEL REPEATABLE READ', args);

  Future<List<Row>> advances(Database session,
          [Map<String, Object?> args = const {}]) =>
      session.query(
          '''SELECT id, etapa_anterior_id AS "etapaAnteriorId", etapa_id AS "etapaId",
      responsavel_id AS "responsavelId", autor_id AS "autorId", criado_em AS "criadoEm"
      FROM avancos_tarefa WHERE tarefa_id = @id ORDER BY id''', args);

  Future<List<Row>> attachments(Database session,
          [Map<String, Object?> args = const {}]) =>
      session.query(
          '''SELECT id, nome, content_type AS "contentType", tamanho, criado_em AS "criadoEm"
      FROM anexos WHERE tarefa_id = @id ORDER BY id''', args);

  Future<List<Row>> checklist(Database session,
          [Map<String, Object?> args = const {}]) =>
      session.query(
          '''SELECT id, modelo_id AS "modeloId", nome, concluido, ordem
      FROM itens_checklist_tarefa WHERE tarefa_id = @id ORDER BY ordem, id''',
          args);

  Future<Row?> findDetails(Database session,
          [Map<String, Object?> args = const {}]) =>
      session.one('SELECT $taskSelect $taskFrom WHERE t.id_tarefa = @id', args);
}
