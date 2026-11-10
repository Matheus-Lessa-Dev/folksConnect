import '../repositories/users_repository.dart';
import '../repositories/shared_repository.dart';

import 'auth_service.dart';
import '../database.dart';
import '../dto/input.dart';
import '../dto/validation.dart';
import '../exceptions/api_error.dart';
import '../models/models.dart';
import '../security.dart';

class UserService {
  final Database db;
  final UserRepository repository = UserRepository();
  final AuthService auth;
  UserService(this.db, this.auth);

  Future<Row> list(QueryInput query, Identity user) =>
      repository.list(db, query, user);

  Future<Row> create(JsonInput input, Identity actor) async {
    actor.require('E');
    final data = input
        .only({'nome', 'email', 'senha', 'cargoId', 'projetoId', 'permissoes'});
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
        final p = await repository.findPermission(tx, {'id': id});
        if (p == null) invalid('Permissão inexistente: $id.');
        if (!actor.admin && !actor.permissions.contains(p['chave'])) {
          throw ApiError(403, 'acesso_negado',
              'Não pode conceder uma permissão que não possui.');
        }
      }
      final row = await repository.insertUser(tx, args);
      final model = Usuario(
          idUsuario: row!['id_usuario'] as int,
          email: args['email'] as String,
          cargosIdCargo: args['cargo'] as int,
          projetosIdProjeto: args['projeto'] as int?);
      for (final id in permissions) {
        final link = UsuarioPermissao(
            usuariosIdUsuario: model.idUsuario, permissoesIdPermissoes: id);
        await repository.insertPermission(tx, {
          'user': link.usuariosIdUsuario,
          'permission': link.permissoesIdPermissoes
        });
      }
      return auth.profile(model.idUsuario, tx);
    });
    return result;
  }

  Future<Row> update(JsonInput input, Identity user, int id) async {
    user.require('F');
    final data = input.only({'cargoId', 'permissoes'});
    if (data.isEmpty) invalid('Informe cargoId ou permissoes.');
    final role = data.containsKey('cargoId')
        ? integer(data['cargoId'], 'cargoId')
        : null;
    final permissions = data.containsKey('permissoes')
        ? ids(data['permissoes'], 'permissoes')
        : null;
    await db.transaction((tx) async {
      final target = await repository.lockUser(tx, {'id': id});
      if (target == null) missing('Usuário');
      if (target['administrador'] == true && !user.admin) {
        throw ApiError(
            403, 'acesso_negado', 'Não pode alterar um administrador.');
      }
      if (role != null) {
        await reference(tx, 'cargos', 'id_cargo', role);
        await repository.updateRole(tx, {'id': id, 'role': role});
      }
      if (permissions != null) {
        for (final permission in permissions) {
          final found = await repository.findPermission(tx, {'id': permission});
          if (found == null) invalid('Permissão inexistente: $permission.');
          if (!user.admin && !user.permissions.contains(found['chave'])) {
            throw ApiError(403, 'acesso_negado',
                'Não pode conceder uma permissão que não possui.');
          }
        }
        await repository.clearPermissions(tx, id);
        for (final permission in permissions) {
          await repository
              .insertPermission(tx, {'user': id, 'permission': permission});
        }
      }
    });
    return await auth.profile(id);
  }

  Future<void> deactivate(Identity user, int id) async {
    user.require('F');
    if (id == user.id) conflict('Não é permitido desativar a própria conta.');
    await db.transaction((tx) async {
      final target = await repository.lockActiveUser(tx, {'id': id});
      if (target == null) missing('Usuário ativo');
      if (target['administrador'] == true) {
        conflict(
            'O administrador de bootstrap não pode ser desativado por esta rota.');
      }
      await repository.deactivateUser(tx, {'id': id});
      await repository.deleteSessions(tx, {'id': id});
      await repository.deleteRecovery(tx, {'id': id});
    });
    return;
  }
}
