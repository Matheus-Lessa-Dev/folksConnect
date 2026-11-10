import '../database.dart';
import '../dto/input.dart';
import '../dto/validation.dart';
import '../security/identity.dart';
import 'shared_repository.dart';

class UserRepository {
  Future<void> clearPermissions(Database db, int id) async {
    await db.query(
        'DELETE FROM usuarios_has_permissoes WHERE usuarios_id_usuario = @id',
        {'id': id});
  }

  Future<Row> list(Database db, QueryInput query, Identity user) async {
    query.only({'busca', 'ativo', 'page', 'limit'});
    final active = query.values['ativo'] ?? 'true';
    if (!{'true', 'false'}.contains(active)) {
      invalid('ativo deve ser true ou false.');
    }
    if (active == 'false') user.require('F');
    final search = query.values['busca'] ?? '';
    if (search.length > 150) invalid('busca deve ter até 150 caracteres.');
    return page(
        db,
        query,
        'u.id_usuario AS id, u.nome, u.email, u.cargos_id_cargo AS "cargoId", c.nome AS cargo, u.ativo',
        'FROM usuarios u JOIN cargos c ON c.id_cargo = u.cargos_id_cargo',
        'u.ativo = @ativo AND (u.nome ILIKE @busca OR u.email ILIKE @busca)',
        {'ativo': active == 'true', 'busca': '%$search%'},
        'u.id_usuario');
  }

  Future<List<Row>> deleteRecovery(Database session,
          [Map<String, Object?> args = const {}]) =>
      session.query(
          'DELETE FROM recuperacoes_senha WHERE usuario_id = @id', args);

  Future<List<Row>> deleteSessions(Database session,
          [Map<String, Object?> args = const {}]) =>
      session.query('DELETE FROM sessoes WHERE usuario_id = @id', args);

  Future<List<Row>> deactivateUser(Database session,
          [Map<String, Object?> args = const {}]) =>
      session.query(
          'UPDATE usuarios SET ativo = FALSE WHERE id_usuario = @id', args);

  Future<Row?> lockActiveUser(Database session,
          [Map<String, Object?> args = const {}]) =>
      session.one(
          'SELECT administrador FROM usuarios WHERE id_usuario = @id AND ativo FOR UPDATE',
          args);

  Future<List<Row>> updateRole(Database session,
          [Map<String, Object?> args = const {}]) =>
      session.query(
          'UPDATE usuarios SET cargos_id_cargo = @role WHERE id_usuario = @id',
          args);

  Future<Row?> lockUser(Database session,
          [Map<String, Object?> args = const {}]) =>
      session.one(
          'SELECT administrador FROM usuarios WHERE id_usuario = @id AND ativo FOR UPDATE',
          args);

  Future<List<Row>> insertPermission(Database session,
          [Map<String, Object?> args = const {}]) =>
      session.query(
          'INSERT INTO usuarios_has_permissoes VALUES (@user, @permission)',
          args);

  Future<Row?> insertUser(Database session,
          [Map<String, Object?> args = const {}]) =>
      session.one(
          '''INSERT INTO usuarios (nome, email, senha_hash, cargos_id_cargo, projetos_id_projeto)
        VALUES (@nome, @email, @hash, @cargo, @projeto) RETURNING id_usuario''',
          args);

  Future<Row?> findPermission(Database session,
          [Map<String, Object?> args = const {}]) =>
      session.one(
          'SELECT chave FROM permissoes WHERE id_permissoes = @id', args);
}
