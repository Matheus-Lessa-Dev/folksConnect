class Usuario {
  int _idUsuario;
  String _email;
  int _cargosIdCargo;
  int _projetosIdProjeto;

  Usuario({
    required int idUsuario,
    required String email,
    required int cargosIdCargo,
    required int projetosIdProjeto,
  }) : _idUsuario = idUsuario,
       _email = email,
       _cargosIdCargo = cargosIdCargo,
       _projetosIdProjeto = projetosIdProjeto;

  int get idUsuario => _idUsuario;
  set idUsuario(int value) => _idUsuario = value;

  String get email => _email;
  set email(String value) => _email = value;

  int get cargosIdCargo => _cargosIdCargo;
  set cargosIdCargo(int value) => _cargosIdCargo = value;

  int get projetosIdProjeto => _projetosIdProjeto;
  set projetosIdProjeto(int value) => _projetosIdProjeto = value;
}
