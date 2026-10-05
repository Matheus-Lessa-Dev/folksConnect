class UsuarioPermissao {
  int _usuariosIdUsuario;
  int _permissoesIdPermissoes;

  UsuarioPermissao({
    required int usuariosIdUsuario,
    required int permissoesIdPermissoes,
  }) : _usuariosIdUsuario = usuariosIdUsuario,
       _permissoesIdPermissoes = permissoesIdPermissoes;

  int get usuariosIdUsuario => _usuariosIdUsuario;
  set usuariosIdUsuario(int value) => _usuariosIdUsuario = value;

  int get permissoesIdPermissoes => _permissoesIdPermissoes;
  set permissoesIdPermissoes(int value) => _permissoesIdPermissoes = value;
}
