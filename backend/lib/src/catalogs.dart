import 'package:shelf/shelf.dart';

import 'auth.dart';
import 'database.dart';
import 'http.dart';
import 'models/models.dart';
import 'security.dart';

Future<void> reference(Database db, String table, String column, int id,
    {bool active = false}) async {
  // Os identificadores vêm exclusivamente de constantes do código.
  final result = await db.one(
      'SELECT $column FROM $table WHERE $column = @id${active ? ' AND ativo' : ''} FOR SHARE',
      {'id': id});
  if (result == null) invalid('Referência inválida: $table/$id.');
}

void queryFields(Request request, Set<String> fields) {
  final extra = request.url.queryParameters.keys.toSet().difference(fields);
  if (extra.isNotEmpty) invalid('Filtros não permitidos: ${extra.join(', ')}.');
}

Future<Response> page(Database db, Request request, String select, String from,
    String where, Map<String, Object?> params, String order,
    {Row Function(Row)? map}) async {
  final current = queryInt(request, 'page', 1, max: 1000000);
  final limit = queryInt(request, 'limit', 20, max: 100);
  return db.transaction((tx) async {
    await tx.query('SET TRANSACTION ISOLATION LEVEL REPEATABLE READ');
    final count =
        await tx.one('SELECT count(*) AS total $from WHERE $where', params);
    final items = await tx.query(
        'SELECT $select $from WHERE $where ORDER BY $order LIMIT @limit OFFSET @offset',
        {...params, 'limit': limit, 'offset': (current - 1) * limit});
    return json({
      'items': map == null ? items : items.map(map).toList(),
      'total': count!['total'],
      'page': current,
      'limit': limit
    });
  });
}

class Catalogs {
  final Database db;
  Catalogs(this.db);

  Future<Response> list(Request request, String name) async {
    queryFields(request, {'busca', 'page', 'limit'});
    final specs = <String, (String, String)>{
      'cargos': ('cargos', 'id_cargo'),
      'projetos': ('projetos', 'id_projeto'),
      'prioridades': ('prioridades', 'id_prioridade'),
      'permissoes': ('permissoes', 'id_permissoes'),
      'clientes': ('clientes', 'id_cliente'),
      'divulgacoes': ('divulgacoes', 'id_divulgacao'),
    };
    final spec = specs[name]!;
    final search = request.url.queryParameters['busca'] ?? '';
    if (search.length > 150) invalid('busca deve ter até 150 caracteres.');
    return page(db, request, '*', 'FROM ${spec.$1}', 'nome ILIKE @search',
        {'search': '%$search%'}, spec.$2,
        map: (row) => serialize(name, row));
  }

  Row serialize(String name, Row row) {
    switch (name) {
      case 'cargos':
        final model = Cargo(
            idCargo: row['id_cargo'] as int,
            chave: row['chave'] as String,
            nome: row['nome'] as String);
        return {'id': model.idCargo, 'chave': model.chave, 'nome': model.nome};
      case 'projetos':
        final model = Projeto(
            idProjeto: row['id_projeto'] as int, nome: row['nome'] as String);
        return {'id': model.idProjeto, 'nome': model.nome};
      case 'prioridades':
        final model = Prioridade(
            idPrioridade: row['id_prioridade'] as int,
            nome: row['nome'] as String,
            valor: row['valor'] as int);
        return {
          'id': model.idPrioridade,
          'nome': model.nome,
          'valor': model.valor
        };
      case 'permissoes':
        final model = Permissao(
            idPermissoes: row['id_permissoes'] as int,
            nome: row['nome'] as String,
            chave: row['chave'] as String);
        return {
          'id': model.idPermissoes,
          'nome': model.nome,
          'chave': model.chave
        };
      case 'divulgacoes':
        final model = Divulgacao(
            idDivulgacao: row['id_divulgacao'] as int,
            nome: row['nome'] as String,
            chave: row['chave'] as String);
        return {
          'id': model.idDivulgacao,
          'nome': model.nome,
          'chave': model.chave
        };
      default:
        final model = Cliente(
            idCliente: row['id_cliente'] as int,
            nome: row['nome'] as String,
            cnpj: row['cnpj'] as String?,
            representante: row['representante'] as String?);
        return {
          'id': model.idCliente,
          'empresa': model.nome,
          'cnpj': model.cnpj,
          'representante': model.representante,
          'contato': row['contato'],
          'email': row['email']
        };
    }
  }

  Future<Response> createClient(Request request, Identity user) async {
    user.require('C');
    final data = await body(
        request, {'empresa', 'cnpj', 'representante', 'contato', 'email'});
    final company = string(data, 'empresa', max: 110);
    String? cnpj;
    if (data['cnpj'] != null) {
      cnpj = string(data, 'cnpj', max: 18).replaceAll(RegExp(r'[./-]'), '');
      if (!RegExp(r'^\d{14}$').hasMatch(cnpj)) {
        invalid('cnpj deve ter 14 dígitos.');
      }
    }
    final row = await db
        .one('''INSERT INTO clientes (nome, cnpj, representante, contato, email)
      VALUES (@nome, @cnpj, @representante, @contato, @email) RETURNING *''', {
      'nome': company,
      'cnpj': cnpj,
      'representante': data['representante'] == null
          ? null
          : string(data, 'representante', max: 100),
      'contato':
          data['contato'] == null ? null : string(data, 'contato', max: 100),
      'email': data['email'] == null ? null : email(data, 'email'),
    });
    return json(serialize('clientes', row!), status: 201);
  }

  Future<Response> createChannel(Request request, Identity user) async {
    user.require('C');
    final data = await body(request, {'nome', 'chave'});
    final key = string(data, 'chave', max: 60).toLowerCase();
    if (!RegExp(r'^[a-z0-9][a-z0-9_-]*$').hasMatch(key)) {
      invalid('chave deve usar letras minúsculas, números, _ ou -.');
    }
    final row = await db.one(
        'INSERT INTO divulgacoes (nome, chave) VALUES (@nome, @chave) RETURNING *',
        {'nome': string(data, 'nome', max: 60), 'chave': key});
    return json(serialize('divulgacoes', row!), status: 201);
  }
}

class Users {
  final Database db;
  final Auth auth;
  Users(this.db, this.auth);

  Future<Response> list(Request request, Identity user) async {
    queryFields(request, {'busca', 'ativo', 'page', 'limit'});
    final active = request.url.queryParameters['ativo'] ?? 'true';
    if (!{'true', 'false'}.contains(active)) {
      invalid('ativo deve ser true ou false.');
    }
    if (active == 'false') user.require('F');
    final search = request.url.queryParameters['busca'] ?? '';
    if (search.length > 150) invalid('busca deve ter até 150 caracteres.');
    return page(
        db,
        request,
        'u.id_usuario AS id, u.nome, u.email, u.cargos_id_cargo AS "cargoId", c.nome AS cargo, u.ativo',
        'FROM usuarios u JOIN cargos c ON c.id_cargo = u.cargos_id_cargo',
        'u.ativo = @ativo AND (u.nome ILIKE @busca OR u.email ILIKE @busca)',
        {'ativo': active == 'true', 'busca': '%$search%'},
        'u.id_usuario');
  }

  Future<Response> create(Request request, Identity actor) async {
    actor.require('E');
    final data = await body(request,
        {'nome', 'email', 'senha', 'cargoId', 'projetoId', 'permissoes'});
    final args = <String, Object?>{
      'nome': string(data, 'nome'),
      'email': email(data, 'email'),
      'cargo': integer(data['cargoId'], 'cargoId'),
      'projeto': data['projetoId'] == null
          ? null
          : integer(data['projetoId'], 'projetoId'),
      'hash': await hashPassword(password(data))
    };
    final permissions = ids(data['permissoes'] ?? <int>[], 'permissoes');
    final result = await db.transaction((tx) async {
      await reference(tx, 'cargos', 'id_cargo', args['cargo'] as int);
      if (args['projeto'] != null) {
        await reference(tx, 'projetos', 'id_projeto', args['projeto'] as int);
      }
      for (final id in permissions) {
        final p = await tx.one(
            'SELECT chave FROM permissoes WHERE id_permissoes = @id',
            {'id': id});
        if (p == null) invalid('Permissão inexistente: $id.');
        if (!actor.admin && !actor.permissions.contains(p['chave'])) {
          throw ApiError(403, 'acesso_negado',
              'Não pode conceder uma permissão que não possui.');
        }
      }
      final row = await tx.one(
          '''INSERT INTO usuarios (nome, email, senha_hash, cargos_id_cargo, projetos_id_projeto)
        VALUES (@nome, @email, @hash, @cargo, @projeto) RETURNING id_usuario''',
          args);
      final model = Usuario(
          idUsuario: row!['id_usuario'] as int,
          email: args['email'] as String,
          cargosIdCargo: args['cargo'] as int,
          projetosIdProjeto: args['projeto'] as int?);
      for (final id in permissions) {
        final link = UsuarioPermissao(
            usuariosIdUsuario: model.idUsuario, permissoesIdPermissoes: id);
        await tx.query(
            'INSERT INTO usuarios_has_permissoes VALUES (@user, @permission)', {
          'user': link.usuariosIdUsuario,
          'permission': link.permissoesIdPermissoes
        });
      }
      return auth.profile(model.idUsuario, tx);
    });
    return json(result, status: 201);
  }

  Future<Response> update(Request request, Identity user, int id) async {
    user.require('F');
    final data = await body(request, {'cargoId'});
    final role = integer(data['cargoId'], 'cargoId');
    await db.transaction((tx) async {
      final target = await tx.one(
          'SELECT administrador FROM usuarios WHERE id_usuario = @id AND ativo FOR UPDATE',
          {'id': id});
      if (target == null) missing('Usuário');
      if (target['administrador'] == true && !user.admin) {
        throw ApiError(
            403, 'acesso_negado', 'Não pode alterar um administrador.');
      }
      await reference(tx, 'cargos', 'id_cargo', role);
      await tx.query(
          'UPDATE usuarios SET cargos_id_cargo = @role WHERE id_usuario = @id',
          {'id': id, 'role': role});
    });
    return json(await auth.profile(id));
  }

  Future<Response> deactivate(Identity user, int id) async {
    user.require('F');
    if (id == user.id) conflict('Não é permitido desativar a própria conta.');
    await db.transaction((tx) async {
      final target = await tx.one(
          'SELECT administrador FROM usuarios WHERE id_usuario = @id AND ativo FOR UPDATE',
          {'id': id});
      if (target == null) missing('Usuário ativo');
      if (target['administrador'] == true) {
        conflict(
            'O administrador de bootstrap não pode ser desativado por esta rota.');
      }
      await tx.query('UPDATE usuarios SET ativo = FALSE WHERE id_usuario = @id',
          {'id': id});
      await tx.query('DELETE FROM sessoes WHERE usuario_id = @id', {'id': id});
      await tx.query(
          'DELETE FROM recuperacoes_senha WHERE usuario_id = @id', {'id': id});
    });
    return Response(204);
  }
}
