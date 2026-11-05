import 'package:shelf/shelf.dart';

import 'catalogs.dart';
import 'database.dart';
import 'http.dart';
import 'models/tarefa.dart';
import 'security.dart';

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

String day(DateTime value) => value.toIso8601String().substring(0, 10);
String description(Map<String, dynamic> data) {
  final value = data['descricao'] ?? '';
  if (value is! String || value.length > 10000) {
    invalid('descricao deve ser texto de até 10000 caracteres.');
  }
  return value.trim();
}

class Tasks {
  final Database db;
  Tasks(this.db);

  Row serialize(Row row) {
    final model = Tarefa(
        idTarefa: row['id_tarefa'] as int,
        idCargo: row['id_cargo'] as int?,
        idUsuario: row['id_usuario'] as int,
        prazoInicial: row['prazo_inicial'] as DateTime);
    return {
      'id': model.idTarefa,
      'titulo': row['titulo'],
      'descricao': row['descricao'],
      'cargo': row['cargo'],
      'responsavelId': model.idUsuario,
      'responsavel': row['responsavel'],
      'clienteId': row['id_cliente'],
      'empresa': row['empresa'],
      'projetoId': row['id_projeto'],
      'projeto': row['projeto'],
      'prioridadeId': row['id_prioridade'],
      'prioridade': row['prioridade'],
      'prazoInicial': day(model.prazoInicial),
      'prazoFinal': row['prazo_final'] == null
          ? null
          : day(row['prazo_final'] as DateTime),
      'statusId': row['status_id'],
      'status': row['status'],
      'etapaId': row['etapa_id'],
      'etapa': row['etapa']
    };
  }

  Future<Row> details(Database tx, int id) async {
    final row = await tx.one(
        'SELECT $taskSelect $taskFrom WHERE t.id_tarefa = @id', {'id': id});
    if (row == null) missing('Tarefa');
    final result = serialize(row);
    result['checklist'] = await tx.query(
        '''SELECT id, modelo_id AS "modeloId", nome, concluido, ordem
      FROM itens_checklist_tarefa WHERE tarefa_id = @id ORDER BY ordem, id''',
        {'id': id});
    result['anexos'] = await tx.query(
        '''SELECT id, nome, content_type AS "contentType", tamanho, criado_em AS "criadoEm"
      FROM anexos WHERE tarefa_id = @id ORDER BY id''', {'id': id});
    result['avancos'] = await tx.query(
        '''SELECT id, etapa_anterior_id AS "etapaAnteriorId", etapa_id AS "etapaId",
      responsavel_id AS "responsavelId", autor_id AS "autorId", criado_em AS "criadoEm"
      FROM avancos_tarefa WHERE tarefa_id = @id ORDER BY id''', {'id': id});
    return result;
  }

  Future<Response> get(int id) => db.transaction((tx) async {
        await tx.query('SET TRANSACTION ISOLATION LEVEL REPEATABLE READ');
        return json(await details(tx, id));
      });

  Future<Response> list(Request request) async {
    const filters = {
      'projetoId': 't.id_projeto',
      'statusId': 't.status_id',
      'etapaId': 't.etapa_id',
      'responsavelId': 't.id_usuario',
      'prioridadeId': 't.id_prioridade',
      'clienteId': 't.id_cliente'
    };
    queryFields(request, {
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
      final value = request.url.queryParameters[filter.key];
      if (value == null) continue;
      params[filter.key] = integer(int.tryParse(value), filter.key);
      where.add('${filter.value} = @${filter.key}');
    }
    final search = request.url.queryParameters['busca'];
    if (search != null) {
      if (search.length > 150) invalid('busca deve ter até 150 caracteres.');
      params['busca'] = '%$search%';
      where.add(
          '(t.titulo ILIKE @busca OR t.descricao ILIKE @busca OR t.cargo ILIKE @busca)');
    }
    for (final key in ['prazoInicial', 'prazoFinal']) {
      if (request.url.queryParameters.containsKey(key)) {
        params[key] = date(request.url.queryParameters, key);
        where.add(
            '${key == 'prazoInicial' ? 't.prazo_inicial >=' : 't.prazo_final <='} CAST(@$key AS date)');
      }
    }
    if (params.containsKey('prazoInicial') &&
        params.containsKey('prazoFinal')) {
      dates(params['prazoInicial'] as String, params['prazoFinal'] as String);
    }
    return page(db, request, taskSelect, taskFrom, where.join(' AND '), params,
        't.id_tarefa DESC',
        map: serialize);
  }

  Future<Response> create(Request request, Identity user) async {
    user.require('B');
    final data = await body(request, {
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
      await tx.query('SELECT pg_advisory_xact_lock_shared(736289142)');
      await reference(tx, 'projetos', 'id_projeto', args['projeto'] as int);
      await reference(tx, 'clientes', 'id_cliente', args['cliente'] as int);
      await reference(tx, 'usuarios', 'id_usuario', args['responsavel'] as int,
          active: true);
      await reference(
          tx, 'prioridades', 'id_prioridade', args['prioridade'] as int);
      final row = await tx.one('''INSERT INTO tarefas
        (titulo, descricao, cargo, id_projeto, id_cliente, id_usuario, id_prioridade, prazo_inicial, prazo_final, status_id, etapa_id)
        VALUES (@titulo, @descricao, @cargo, @projeto, @cliente, @responsavel, @prioridade, CAST(@inicio AS date), CAST(@fim AS date),
          (SELECT id FROM etapas_kanban ORDER BY ordem, id LIMIT 1), (SELECT id FROM etapas_funil ORDER BY ordem, id LIMIT 1))
        RETURNING id_tarefa''', args);
      final id = row!['id_tarefa'] as int;
      await tx.query(
          '''INSERT INTO itens_checklist_tarefa (tarefa_id, modelo_id, nome, ordem)
        SELECT @id, id_checklist, nome, ordem FROM checklists ORDER BY ordem, id_checklist''',
          {'id': id});
      return json(await details(tx, id), status: 201);
    });
  }

  Future<void> lock(Database tx, int id) async {
    if (await tx.one(
            'SELECT id_tarefa FROM tarefas WHERE id_tarefa = @id FOR UPDATE',
            {'id': id}) ==
        null) {
      missing('Tarefa');
    }
  }

  Future<Response> update(Request request, Identity user, int id) async {
    user.require('B');
    final data =
        await body(request, {'responsavelId', 'prioridadeId', 'descricao'});
    if (data.isEmpty) invalid('Informe ao menos um campo editável.');
    return db.transaction((tx) async {
      await lock(tx, id);
      final args = <String, Object?>{'id': id};
      final fields = <String>[];
      if (data.containsKey('responsavelId')) {
        final value = integer(data['responsavelId'], 'responsavelId');
        await reference(tx, 'usuarios', 'id_usuario', value, active: true);
        args['responsavel'] = value;
        fields.add('id_usuario = @responsavel');
      }
      if (data.containsKey('prioridadeId')) {
        final value = integer(data['prioridadeId'], 'prioridadeId');
        await reference(tx, 'prioridades', 'id_prioridade', value);
        args['prioridade'] = value;
        fields.add('id_prioridade = @prioridade');
      }
      if (data.containsKey('descricao')) {
        if (data['descricao'] == null) invalid('descricao não pode ser nula.');
        args['descricao'] = description(data);
        fields.add('descricao = @descricao');
      }
      await tx.query(
          'UPDATE tarefas SET ${fields.join(', ')} WHERE id_tarefa = @id',
          args);
      return json(await details(tx, id));
    });
  }

  Future<Response> move(Request request, Identity user, int id) async {
    user.require('B');
    final data = await body(request, {'statusId'});
    final status = integer(data['statusId'], 'statusId');
    return db.transaction((tx) async {
      await tx.query('SELECT pg_advisory_xact_lock_shared(736289142)');
      await lock(tx, id);
      await reference(tx, 'etapas_kanban', 'id', status);
      await tx.query(
          'UPDATE tarefas SET status_id = @status WHERE id_tarefa = @id',
          {'id': id, 'status': status});
      return json(await details(tx, id));
    });
  }

  Future<Response> advance(Request request, Identity user, int id) async {
    user.require('B');
    final data = await body(request, {'etapaId', 'responsavelId'});
    final stage = integer(data['etapaId'], 'etapaId');
    final responsible = integer(data['responsavelId'], 'responsavelId');
    return db.transaction((tx) async {
      await tx.query('SELECT pg_advisory_xact_lock_shared(736289142)');
      await lock(tx, id);
      final current = await tx.one('''SELECT t.etapa_id, e.ordem FROM tarefas t
        JOIN etapas_funil e ON e.id = t.etapa_id WHERE t.id_tarefa = @id''',
          {'id': id});
      final next = await tx
          .one('SELECT ordem FROM etapas_funil WHERE id = @id', {'id': stage});
      if (next == null) invalid('Etapa inexistente.');
      if ((next['ordem'] as int) <= (current!['ordem'] as int)) {
        conflict('O avanço exige uma etapa posterior à atual.');
      }
      await reference(tx, 'usuarios', 'id_usuario', responsible, active: true);
      await tx.query(
          'UPDATE tarefas SET etapa_id = @etapa, id_usuario = @responsavel WHERE id_tarefa = @id',
          {'id': id, 'etapa': stage, 'responsavel': responsible});
      await tx.query(
          '''INSERT INTO avancos_tarefa (tarefa_id, etapa_anterior_id, etapa_id, responsavel_id, autor_id)
        VALUES (@id, @anterior, @etapa, @responsavel, @autor)''',
          {
            'id': id,
            'anterior': current['etapa_id'],
            'etapa': stage,
            'responsavel': responsible,
            'autor': user.id
          });
      return json(await details(tx, id), status: 201);
    });
  }

  Future<Response> addItem(Request request, Identity user, int id) async {
    user.require('B');
    final data = await body(request, {'nome'});
    final name = string(data, 'nome');
    return db.transaction((tx) async {
      await lock(tx, id);
      final item = await tx
          .one('''INSERT INTO itens_checklist_tarefa (tarefa_id, nome, ordem)
        VALUES (@id, @nome, (SELECT coalesce(max(ordem), -1) + 1 FROM itens_checklist_tarefa WHERE tarefa_id = @id))
        RETURNING id, nome, concluido, ordem''', {'id': id, 'nome': name});
      return json(item, status: 201);
    });
  }

  Future<Response> checkItem(
      Request request, Identity user, int id, int itemId) async {
    user.require('B');
    final data = await body(request, {'concluido'});
    final checked = data['concluido'];
    if (checked is! bool) invalid('concluido deve ser booleano.');
    final row = await db.one(
        '''UPDATE itens_checklist_tarefa SET concluido = @checked
      WHERE id = @item AND tarefa_id = @id RETURNING id, nome, concluido, ordem''',
        {'id': id, 'item': itemId, 'checked': checked});
    if (row == null) missing('Item da tarefa');
    return json(row);
  }
}
