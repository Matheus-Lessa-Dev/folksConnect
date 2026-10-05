class Vaga {
  int _idVaga;
  String _cargo;
  String _perfilDeixado;
  DateTime _prazoInicial;
  DateTime _prazoFinal;
  int _idDivulgacao;
  int _candInscritos;
  int _candIdeias;
  int _erros;
  int _clientesIdCliente;
  int _usuariosIdUsuario;
  int _usuariosCargosIdCargo;

  Vaga({
    required int idVaga,
    required String cargo,
    required String perfilDeixado,
    required DateTime prazoInicial,
    required DateTime prazoFinal,
    required int idDivulgacao,
    required int candInscritos,
    required int candIdeias,
    required int erros,
    required int clientesIdCliente,
    required int usuariosIdUsuario,
    required int usuariosCargosIdCargo,
  }) : _idVaga = idVaga,
       _cargo = cargo,
       _perfilDeixado = perfilDeixado,
       _prazoInicial = prazoInicial,
       _prazoFinal = prazoFinal,
       _idDivulgacao = idDivulgacao,
       _candInscritos = candInscritos,
       _candIdeias = candIdeias,
       _erros = erros,
       _clientesIdCliente = clientesIdCliente,
       _usuariosIdUsuario = usuariosIdUsuario,
       _usuariosCargosIdCargo = usuariosCargosIdCargo;

  int get idVaga => _idVaga;
  set idVaga(int value) => _idVaga = value;

  String get cargo => _cargo;
  set cargo(String value) => _cargo = value;

  String get perfilDeixado => _perfilDeixado;
  set perfilDeixado(String value) => _perfilDeixado = value;

  DateTime get prazoInicial => _prazoInicial;
  set prazoInicial(DateTime value) => _prazoInicial = value;

  DateTime get prazoFinal => _prazoFinal;
  set prazoFinal(DateTime value) => _prazoFinal = value;

  int get idDivulgacao => _idDivulgacao;
  set idDivulgacao(int value) => _idDivulgacao = value;

  int get candInscritos => _candInscritos;
  set candInscritos(int value) => _candInscritos = value;

  int get candIdeias => _candIdeias;
  set candIdeias(int value) => _candIdeias = value;

  int get erros => _erros;
  set erros(int value) => _erros = value;

  int get clientesIdCliente => _clientesIdCliente;
  set clientesIdCliente(int value) => _clientesIdCliente = value;

  int get usuariosIdUsuario => _usuariosIdUsuario;
  set usuariosIdUsuario(int value) => _usuariosIdUsuario = value;

  int get usuariosCargosIdCargo => _usuariosCargosIdCargo;
  set usuariosCargosIdCargo(int value) => _usuariosCargosIdCargo = value;
}
