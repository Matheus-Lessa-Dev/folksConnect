import '../database.dart';

class AuthRepository {
  Future<List<Row>> deleteUserSessions(Database session,
          [Map<String, Object?> args = const {}]) =>
      session.query('DELETE FROM sessoes WHERE usuario_id = @id', args);

  Future<List<Row>> deleteUserRecovery(Database session,
          [Map<String, Object?> args = const {}]) =>
      session.query(
          'DELETE FROM recuperacoes_senha WHERE usuario_id = @id', args);

  Future<List<Row>> updatePassword(Database session,
          [Map<String, Object?> args = const {}]) =>
      session.query(
          'UPDATE usuarios SET senha_hash = @hash WHERE id_usuario = @id',
          args);

  Future<List<Row>> consumeResetToken(Database session,
          [Map<String, Object?> args = const {}]) =>
      session.query(
          'DELETE FROM recuperacoes_senha WHERE token_hash = @hash AND expira_em > now() RETURNING usuario_id',
          args);

  Future<Row?> lockResetUser(Database session,
          [Map<String, Object?> args = const {}]) =>
      session.one('''SELECT u.id_usuario FROM recuperacoes_senha r
        JOIN usuarios u ON u.id_usuario = r.usuario_id WHERE r.token_hash = @hash
        AND r.expira_em > now() AND u.ativo FOR UPDATE OF u''', args);

  Future<Row?> findResetToken(Database session,
          [Map<String, Object?> args = const {}]) =>
      session.one(
          '''SELECT 1 FROM recuperacoes_senha r JOIN usuarios u ON u.id_usuario = r.usuario_id
      WHERE r.token_hash = @hash AND r.expira_em > now() AND u.ativo''', args);

  Future<List<Row>> deleteFailedRecovery(Database session,
          [Map<String, Object?> args = const {}]) =>
      session.query(
          'DELETE FROM recuperacoes_senha WHERE token_hash = @hash', args);

  Future<List<Row>> insertRecovery(Database session,
          [Map<String, Object?> args = const {}]) =>
      session.query(
          "INSERT INTO recuperacoes_senha VALUES (@hash, @id, now() + interval '30 minutes')",
          args);

  Future<List<Row>> deleteOldRecovery(Database session,
          [Map<String, Object?> args = const {}]) =>
      session.query(
          'DELETE FROM recuperacoes_senha WHERE usuario_id = @id OR expira_em <= now()',
          args);

  Future<Row?> lockRecoveryUser(Database session,
          [Map<String, Object?> args = const {}]) =>
      session.one(
          'SELECT id_usuario FROM usuarios WHERE id_usuario = @id AND lower(email) = @email AND ativo FOR UPDATE',
          args);

  Future<Row?> findRecoveryUser(Database session,
          [Map<String, Object?> args = const {}]) =>
      session.one(
          'SELECT id_usuario FROM usuarios WHERE lower(email) = @email AND ativo',
          args);

  Future<List<Row>> deleteProfileRecovery(Database session,
          [Map<String, Object?> args = const {}]) =>
      session.query(
          'DELETE FROM recuperacoes_senha WHERE usuario_id = @id', args);

  Future<List<Row>> updateProfile(Database session, Map<String, Object?> args) {
    final fields = [
      for (final key in ['nome', 'email'])
        if (args.containsKey(key)) '$key = @$key'
    ];
    return session.query(
        'UPDATE usuarios SET ${fields.join(', ')} WHERE id_usuario = @id',
        args);
  }

  Future<List<Row>> lockProfile(Database session,
          [Map<String, Object?> args = const {}]) =>
      session.query(
          'SELECT id_usuario FROM usuarios WHERE id_usuario = @id FOR UPDATE',
          args);

  Future<List<Row>> profilePermissions(Database session,
          [Map<String, Object?> args = const {}]) =>
      session.query(
          '''SELECT p.id_permissoes AS id, p.chave, p.nome FROM permissoes p
      JOIN usuarios_has_permissoes up ON up.permissoes_id_permissoes = p.id_permissoes
      WHERE up.usuarios_id_usuario = @id ORDER BY p.id_permissoes''', args);

  Future<Row?> findProfile(Database session,
          [Map<String, Object?> args = const {}]) =>
      session.one('''SELECT u.id_usuario AS id, u.nome, u.email,
      u.cargos_id_cargo AS "cargoId", c.nome AS cargo, u.projetos_id_projeto AS "projetoId",
      u.ativo, u.administrador FROM usuarios u JOIN cargos c ON c.id_cargo = u.cargos_id_cargo
      WHERE u.id_usuario = @id''', args);

  Future<List<Row>> deleteSession(Database session,
          [Map<String, Object?> args = const {}]) =>
      session.query('DELETE FROM sessoes WHERE token_hash = @hash', args);

  Future<Row?> insertSession(Database session,
          [Map<String, Object?> args = const {}]) =>
      session.one('''INSERT INTO sessoes (token_hash, usuario_id, expira_em)
        VALUES (@hash, @id, now() + interval '12 hours') RETURNING expira_em''',
          args);

  Future<List<Row>> deleteOldLimits(Database session,
          [Map<String, Object?> args = const {}]) =>
      session.query(
          "DELETE FROM limites_auth WHERE janela < now() - interval '1 day'",
          args);

  Future<List<Row>> deleteExpiredSessions(Database session,
          [Map<String, Object?> args = const {}]) =>
      session.query('DELETE FROM sessoes WHERE expira_em <= now()', args);

  Future<Row?> lockLoginUser(Database session,
          [Map<String, Object?> args = const {}]) =>
      session.one(
          'SELECT senha_hash, ativo FROM usuarios WHERE id_usuario = @id FOR UPDATE',
          args);

  Future<Row?> findLoginUser(Database session,
          [Map<String, Object?> args = const {}]) =>
      session.one('SELECT * FROM usuarios WHERE lower(email) = @email', args);

  Future<Row?> recordAttempt(Database session,
          [Map<String, Object?> args = const {}]) =>
      session
          .one('''INSERT INTO limites_auth (chave, tentativas) VALUES (@key, 1)
      ON CONFLICT (chave) DO UPDATE SET
        tentativas = CASE WHEN limites_auth.janela < now() - interval '15 minutes' THEN 1 ELSE limites_auth.tentativas + 1 END,
        janela = CASE WHEN limites_auth.janela < now() - interval '15 minutes' THEN now() ELSE limites_auth.janela END
      RETURNING tentativas''', args);

  Future<List<Row>> permissions(Database session,
          [Map<String, Object?> args = const {}]) =>
      session.query(
          '''SELECT p.chave FROM permissoes p JOIN usuarios_has_permissoes up
      ON up.permissoes_id_permissoes = p.id_permissoes WHERE up.usuarios_id_usuario = @id''',
          args);

  Future<Row?> findSessionUser(Database session,
          [Map<String, Object?> args = const {}]) =>
      session.one('''SELECT u.id_usuario, u.administrador FROM sessoes s
      JOIN usuarios u ON u.id_usuario = s.usuario_id
      WHERE s.token_hash = @hash AND s.expira_em > now() AND u.ativo''', args);

  Future<List<Row>> insertSeedUser(Database session,
          [Map<String, Object?> args = const {}]) =>
      session.query(
          '''INSERT INTO usuarios (nome, email, senha_hash, cargos_id_cargo, projetos_id_projeto, administrador)
        VALUES ('Administrador de desenvolvimento', @email, @hash,
        (SELECT id_cargo FROM cargos WHERE chave = 'gerente'), @project, TRUE)''',
          args);

  Future<Row?> insertSeedProject(Database session,
          [Map<String, Object?> args = const {}]) =>
      session.one(
          "INSERT INTO projetos (nome) VALUES ('Desenvolvimento') RETURNING id_projeto",
          args);

  Future<Row?> findSeedUser(Database session,
          [Map<String, Object?> args = const {}]) =>
      session.one('SELECT 1 FROM usuarios WHERE lower(email) = @email', args);

  Future<List<Row>> seedLock(Database session,
          [Map<String, Object?> args = const {}]) =>
      session.query('SELECT pg_advisory_xact_lock(736289141)', args);
}
