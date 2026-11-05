import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:shelf/shelf.dart';

import 'database.dart';
import 'http.dart';
import 'security.dart';

class Auth {
  final Database db;
  final Map<String, String> env;
  late final Future<String> dummyHash = hashPassword(randomToken());
  Auth(this.db, this.env);

  Future<void> seedDevelopment() async {
    if (env['DEV_SEED'] != 'true') return;
    if (env['APP_ENV'] != 'development') {
      throw StateError('DEV_SEED exige APP_ENV=development.');
    }
    final address = email({'email': env['DEV_ADMIN_EMAIL']}, 'email');
    final hash =
        await hashPassword(password({'senha': env['DEV_ADMIN_PASSWORD']}));
    await db.transaction((tx) async {
      await tx.query('SELECT pg_advisory_xact_lock(736289141)');
      if (await tx.one('SELECT 1 FROM usuarios WHERE lower(email) = @email',
              {'email': address}) !=
          null) {
        return;
      }
      final project = await tx.one(
          "INSERT INTO projetos (nome) VALUES ('Desenvolvimento') RETURNING id_projeto");
      await tx.query(
          '''INSERT INTO usuarios (nome, email, senha_hash, cargos_id_cargo, projetos_id_projeto, administrador)
        VALUES ('Administrador de desenvolvimento', @email, @hash,
        (SELECT id_cargo FROM cargos WHERE chave = 'gerente'), @project, TRUE)''',
          {'email': address, 'hash': hash, 'project': project!['id_projeto']});
    });
  }

  String bearer(Request request) {
    final header = request.headers['authorization'] ?? '';
    if (!header.startsWith('Bearer ') || header.length > 200) {
      throw ApiError(401, 'nao_autenticado', 'Informe um token Bearer válido.');
    }
    return header.substring(7);
  }

  Future<Identity> authenticate(Request request) async {
    final user = await db.one(
        '''SELECT u.id_usuario, u.administrador FROM sessoes s
      JOIN usuarios u ON u.id_usuario = s.usuario_id
      WHERE s.token_hash = @hash AND s.expira_em > now() AND u.ativo''',
        {'hash': tokenHash(bearer(request))});
    if (user == null) {
      throw ApiError(401, 'sessao_invalida', 'Sessão inválida ou expirada.');
    }
    final permissions = await db.query(
        '''SELECT p.chave FROM permissoes p JOIN usuarios_has_permissoes up
      ON up.permissoes_id_permissoes = p.id_permissoes WHERE up.usuarios_id_usuario = @id''',
        {'id': user['id_usuario']});
    return Identity(user['id_usuario'] as int, user['administrador'] as bool,
        permissions.map((p) => p['chave'] as String).toSet());
  }

  Future<void> throttle(String key, {int limit = 10}) async {
    final row = await db
        .one('''INSERT INTO limites_auth (chave, tentativas) VALUES (@key, 1)
      ON CONFLICT (chave) DO UPDATE SET
        tentativas = CASE WHEN limites_auth.janela < now() - interval '15 minutes' THEN 1 ELSE limites_auth.tentativas + 1 END,
        janela = CASE WHEN limites_auth.janela < now() - interval '15 minutes' THEN now() ELSE limites_auth.janela END
      RETURNING tentativas''', {'key': tokenHash(key)});
    if ((row!['tentativas'] as int) > limit) {
      throw ApiError(
          429, 'muitas_tentativas', 'Tente novamente após 15 minutos.');
    }
  }

  Future<Response> login(Request request) async {
    final data = await body(request, {'email', 'senha'});
    final address = email(data, 'email');
    final secret = data['senha'];
    if (secret is! String || secret.isEmpty || secret.length > 128) {
      invalid('senha deve ser texto de até 128 caracteres.');
    }
    await throttle('login:$address');
    final user = await db.one(
        'SELECT * FROM usuarios WHERE lower(email) = @email',
        {'email': address});
    final hash = user?['senha_hash'] as String? ?? await dummyHash;
    final valid = await verifyPassword(secret, hash);
    if (!valid ||
        user == null ||
        user['ativo'] != true ||
        user['senha_hash'] == null) {
      throw ApiError(
          401, 'credenciais_invalidas', 'E-mail ou senha inválidos.');
    }
    final token = randomToken();
    final session = await db.transaction((tx) async {
      final current = await tx.one(
          'SELECT senha_hash, ativo FROM usuarios WHERE id_usuario = @id FOR UPDATE',
          {'id': user['id_usuario']});
      if (current!['senha_hash'] != hash || current['ativo'] != true) {
        throw ApiError(
            401, 'credenciais_invalidas', 'E-mail ou senha inválidos.');
      }
      await tx.query('DELETE FROM sessoes WHERE expira_em <= now()');
      await tx.query(
          "DELETE FROM limites_auth WHERE janela < now() - interval '1 day'");
      return tx.one('''INSERT INTO sessoes (token_hash, usuario_id, expira_em)
        VALUES (@hash, @id, now() + interval '12 hours') RETURNING expira_em''',
          {'hash': tokenHash(token), 'id': user['id_usuario']});
    });
    return json({
      'token': token,
      'tipo': 'Bearer',
      'expiraEm': session!['expira_em'],
      'usuario': await profile(user['id_usuario'] as int)
    });
  }

  Future<Response> logout(Request request) async {
    await db.query('DELETE FROM sessoes WHERE token_hash = @hash',
        {'hash': tokenHash(bearer(request))});
    return Response(204);
  }

  Future<Row> profile(int id, [Database? tx]) async {
    final database = tx ?? db;
    final user =
        await database.one('''SELECT u.id_usuario AS id, u.nome, u.email,
      u.cargos_id_cargo AS "cargoId", c.nome AS cargo, u.projetos_id_projeto AS "projetoId",
      u.ativo, u.administrador FROM usuarios u JOIN cargos c ON c.id_cargo = u.cargos_id_cargo
      WHERE u.id_usuario = @id''', {'id': id});
    if (user == null) missing('Usuário');
    user['permissoes'] = await database.query(
        '''SELECT p.id_permissoes AS id, p.chave, p.nome FROM permissoes p
      JOIN usuarios_has_permissoes up ON up.permissoes_id_permissoes = p.id_permissoes
      WHERE up.usuarios_id_usuario = @id ORDER BY p.id_permissoes''',
        {'id': id});
    return user;
  }

  Future<Response> updateProfile(Request request, Identity user) async {
    final data = await body(request, {'nome', 'email'});
    if (data.isEmpty) invalid('Informe nome ou email.');
    final args = <String, Object?>{'id': user.id};
    final fields = <String>[];
    if (data.containsKey('nome')) {
      args['nome'] = string(data, 'nome');
      fields.add('nome = @nome');
    }
    if (data.containsKey('email')) {
      args['email'] = email(data, 'email');
      fields.add('email = @email');
    }
    await db.transaction((tx) async {
      await tx.query(
          'SELECT id_usuario FROM usuarios WHERE id_usuario = @id FOR UPDATE',
          {'id': user.id});
      await tx.query(
          'UPDATE usuarios SET ${fields.join(', ')} WHERE id_usuario = @id',
          args);
      if (data.containsKey('email')) {
        await tx.query('DELETE FROM recuperacoes_senha WHERE usuario_id = @id',
            {'id': user.id});
      }
    });
    return json(await profile(user.id));
  }

  Future<Response> recover(Request request) async {
    final data = await body(request, {'email'});
    final address = email(data, 'email');
    if ((env['SMTP_HOST'] ?? '').isEmpty || (env['SMTP_FROM'] ?? '').isEmpty) {
      throw ApiError(503, 'email_indisponivel',
          'O envio de recuperação não foi configurado.');
    }
    await throttle('recovery:$address', limit: 3);
    final user = await db.one(
        'SELECT id_usuario FROM usuarios WHERE lower(email) = @email AND ativo',
        {'email': address});
    if (user != null) {
      final token = randomToken();
      final hash = tokenHash(token);
      final eligible = await db.transaction((tx) async {
        final current = await tx.one(
            'SELECT id_usuario FROM usuarios WHERE id_usuario = @id AND lower(email) = @email AND ativo FOR UPDATE',
            {'id': user['id_usuario'], 'email': address});
        if (current == null) return false;
        await tx.query(
            'DELETE FROM recuperacoes_senha WHERE usuario_id = @id OR expira_em <= now()',
            {'id': user['id_usuario']});
        await tx.query(
            "INSERT INTO recuperacoes_senha VALUES (@hash, @id, now() + interval '30 minutes')",
            {'hash': hash, 'id': user['id_usuario']});
        return true;
      });
      if (!eligible) {
        return json({
          'mensagem':
              'Se houver uma conta ativa, as instruções serão enviadas por e-mail.'
        }, status: 202);
      }
      try {
        final server = SmtpServer(env['SMTP_HOST']!,
            port: int.parse(env['SMTP_PORT'] ?? '587'),
            username: (env['SMTP_USER'] ?? '').isEmpty ? null : env['SMTP_USER'],
            password: (env['SMTP_PASSWORD'] ?? '').isEmpty ? null : env['SMTP_PASSWORD'],
            ssl: env['SMTP_SSL'] == 'true',
            allowInsecure: env['APP_ENV'] == 'development' &&
                env['SMTP_ALLOW_INSECURE'] == 'true');
        final message = Message()
          ..from = Address(env['SMTP_FROM']!)
          ..recipients.add(address)
          ..subject = 'Folks Connect - recuperação de senha'
          ..text =
              'Use este token em POST /api/auth/redefinir-senha. Expira em 30 minutos e só pode ser usado uma vez.\n\n$token';
        await send(message, server, timeout: const Duration(seconds: 15));
      } catch (_) {
        await db.query(
            'DELETE FROM recuperacoes_senha WHERE token_hash = @hash',
            {'hash': hash});
        throw ApiError(503, 'email_indisponivel',
            'Não foi possível enviar a recuperação.');
      }
    }
    return json({
      'mensagem':
          'Se houver uma conta ativa, as instruções serão enviadas por e-mail.'
    }, status: 202);
  }

  Future<Response> reset(Request request) async {
    final data = await body(request, {'token', 'senha'});
    final hash = tokenHash(string(data, 'token', max: 100));
    await throttle('reset:$hash');
    final secret = password(data);
    final exists = await db.one(
        '''SELECT 1 FROM recuperacoes_senha r JOIN usuarios u ON u.id_usuario = r.usuario_id
      WHERE r.token_hash = @hash AND r.expira_em > now() AND u.ativo''',
        {'hash': hash});
    if (exists == null) invalid('Token de recuperação inválido ou expirado.');
    final newHash = await hashPassword(secret);
    await db.transaction((tx) async {
      final user = await tx.one('''SELECT u.id_usuario FROM recuperacoes_senha r
        JOIN usuarios u ON u.id_usuario = r.usuario_id WHERE r.token_hash = @hash
        AND r.expira_em > now() AND u.ativo FOR UPDATE OF u''', {'hash': hash});
      if (user == null) invalid('Token de recuperação inválido ou expirado.');
      final consumed = await tx.query(
          'DELETE FROM recuperacoes_senha WHERE token_hash = @hash AND expira_em > now() RETURNING usuario_id',
          {'hash': hash});
      if (consumed.isEmpty) {
        invalid('Token de recuperação inválido ou expirado.');
      }
      await tx.query(
          'UPDATE usuarios SET senha_hash = @hash WHERE id_usuario = @id',
          {'id': user['id_usuario'], 'hash': newHash});
      await tx.query('DELETE FROM recuperacoes_senha WHERE usuario_id = @id',
          {'id': user['id_usuario']});
      await tx.query('DELETE FROM sessoes WHERE usuario_id = @id',
          {'id': user['id_usuario']});
    });
    return Response(204);
  }
}
