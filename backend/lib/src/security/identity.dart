import '../exceptions/api_error.dart';

class Identity {
  final int id;
  final bool admin;
  final Set<String> permissions;
  Identity(this.id, this.admin, this.permissions);
  void require(String permission) {
    if (!admin && !permissions.contains(permission)) {
      throw ApiError(403, 'acesso_negado', 'Permissão insuficiente.');
    }
  }
}
