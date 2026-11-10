import '../repositories/auth_repository.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

import '../database.dart';
import '../dto/input.dart';
import '../dto/validation.dart';
import '../exceptions/api_error.dart';
import '../security.dart';

class AuthService {
  final Database db;
  final AuthRepository repository = AuthRepository();
  final Map<String, String> env;
  late final Future<String> dummyHash = hashPassword(randomToken());
  AuthService(this.db, this.env);

  Future<void> seedDevelopment() async {
    if (env['DEV_SEED'] != 'true') return;
    if (env['APP_ENV'] != 'development') {
      throw StateError('DEV_SEED exige APP_ENV=development.');
    }
    final address = email({'email': env['DEV_ADMIN_EMAIL']}, 'email');
    final hash =
        await hashPassword(password({'senha': env['DEV_ADMIN_PASSWORD']}));
    await db.transaction((tx) async {
      await repository.seedLock(tx);
      if (await repository.findSeedUser(tx, {'email': address}) != null) {
        return;
      }
      final project = await repository.insertSeedProject(tx);
      await repository.insertSeedUser(tx,
          {'email': address, 'hash': hash, 'project': project!['id_projeto']});
    });
  }

  Future<Identity> authenticate(String token) async {
    final user =
        await repository.findSessionUser(db, {'hash': tokenHash(token)});
    if (user == null) {
      throw ApiError(401, 'sessao_invalida', 'Sessão inválida ou expirada.');
    }
    final permissions =
        await repository.permissions(db, {'id': user['id_usuario']});
    return Identity(user['id_usuario'] as int, user['administrador'] as bool,
        permissions.map((p) => p['chave'] as String).toSet());
  }

  Future<void> throttle(String key, {int limit = 10}) async {
    final row = await repository.recordAttempt(db, {'key': tokenHash(key)});
    if ((row!['tentativas'] as int) > limit) {
      throw ApiError(
          429, 'muitas_tentativas', 'Tente novamente após 15 minutos.');
    }
  }

  Future<Row> login(JsonInput input) async {
    final data = input.only({'email', 'senha'});
    final address = email(data, 'email');
    final secret = data['senha'];
    if (secret is! String || secret.isEmpty || secret.length > 128) {
      invalid('senha deve ser texto de até 128 caracteres.');
    }
    await throttle('login:$address');
    final user = await repository.findLoginUser(db, {'email': address});
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
      final current =
          await repository.lockLoginUser(tx, {'id': user['id_usuario']});
      if (current!['senha_hash'] != hash || current['ativo'] != true) {
        throw ApiError(
            401, 'credenciais_invalidas', 'E-mail ou senha inválidos.');
      }
      await repository.deleteExpiredSessions(tx);
      await repository.deleteOldLimits(tx);
      return repository.insertSession(
          tx, {'hash': tokenHash(token), 'id': user['id_usuario']});
    });
    return {
      'token': token,
      'tipo': 'Bearer',
      'expiraEm': session!['expira_em'],
      'usuario': await profile(user['id_usuario'] as int)
    };
  }

  Future<void> logout(String token) async {
    await repository.deleteSession(db, {'hash': tokenHash(token)});
    return;
  }

  Future<Row> profile(int id, [Database? tx]) async {
    final database = tx ?? db;
    final user = await repository.findProfile(database, {'id': id});
    if (user == null) missing('Usuário');
    user['permissoes'] =
        await repository.profilePermissions(database, {'id': id});
    return user;
  }

  Future<Row> updateProfile(JsonInput input, Identity user) async {
    final data = input.only({'nome', 'email'});
    if (data.isEmpty) invalid('Informe nome ou email.');
    final args = <String, Object?>{'id': user.id};
    if (data.containsKey('nome')) {
      args['nome'] = string(data, 'nome');
    }
    if (data.containsKey('email')) {
      args['email'] = email(data, 'email');
    }
    await db.transaction((tx) async {
      await repository.lockProfile(tx, {'id': user.id});
      await repository.updateProfile(tx, args);
      if (data.containsKey('email')) {
        await repository.deleteProfileRecovery(tx, {'id': user.id});
      }
    });
    return await profile(user.id);
  }

  Future<Row> recover(JsonInput input) async {
    final data = input.only({'email'});
    final address = email(data, 'email');
    if ((env['SMTP_HOST'] ?? '').isEmpty || (env['SMTP_FROM'] ?? '').isEmpty) {
      throw ApiError(503, 'email_indisponivel',
          'O envio de recuperação não foi configurado.');
    }
    await throttle('recovery:$address', limit: 3);
    final user = await repository.findRecoveryUser(db, {'email': address});
    if (user != null) {
      final token = randomToken();
      final hash = tokenHash(token);
      final eligible = await db.transaction((tx) async {
        final current = await repository
            .lockRecoveryUser(tx, {'id': user['id_usuario'], 'email': address});
        if (current == null) return false;
        await repository.deleteOldRecovery(tx, {'id': user['id_usuario']});
        await repository
            .insertRecovery(tx, {'hash': hash, 'id': user['id_usuario']});
        return true;
      });
      if (!eligible) {
        return {
          'mensagem':
              'Se houver uma conta ativa, as instruções serão enviadas por e-mail.'
        };
      }
      try {
        final server = SmtpServer(env['SMTP_HOST']!,
            port: int.parse(env['SMTP_PORT'] ?? '587'),
            username:
                (env['SMTP_USER'] ?? '').isEmpty ? null : env['SMTP_USER'],
            password: (env['SMTP_PASSWORD'] ?? '').isEmpty
                ? null
                : env['SMTP_PASSWORD'],
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
        await repository.deleteFailedRecovery(db, {'hash': hash});
        throw ApiError(503, 'email_indisponivel',
            'Não foi possível enviar a recuperação.');
      }
    }
    return {
      'mensagem':
          'Se houver uma conta ativa, as instruções serão enviadas por e-mail.'
    };
  }

  Future<void> reset(JsonInput input) async {
    final data = input.only({'token', 'senha'});
    final hash = tokenHash(string(data, 'token', max: 100));
    await throttle('reset:$hash');
    final secret = password(data);
    final exists = await repository.findResetToken(db, {'hash': hash});
    if (exists == null) invalid('Token de recuperação inválido ou expirado.');
    final newHash = await hashPassword(secret);
    await db.transaction((tx) async {
      final user = await repository.lockResetUser(tx, {'hash': hash});
      if (user == null) invalid('Token de recuperação inválido ou expirado.');
      final consumed = await repository.consumeResetToken(tx, {'hash': hash});
      if (consumed.isEmpty) {
        invalid('Token de recuperação inválido ou expirado.');
      }
      await repository
          .updatePassword(tx, {'id': user['id_usuario'], 'hash': newHash});
      await repository.deleteUserRecovery(tx, {'id': user['id_usuario']});
      await repository.deleteUserSessions(tx, {'id': user['id_usuario']});
    });
    return;
  }
}
