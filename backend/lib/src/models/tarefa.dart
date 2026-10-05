class Tarefa {
  int _idTarefa;
  int _idCargo;
  int _idUsuario;
  DateTime _prazoInicial;

  Tarefa({
    required int idTarefa,
    required int idCargo,
    required int idUsuario,
    required DateTime prazoInicial,
  }) : _idTarefa = idTarefa,
       _idCargo = idCargo,
       _idUsuario = idUsuario,
       _prazoInicial = prazoInicial;

  int get idTarefa => _idTarefa;
  set idTarefa(int value) => _idTarefa = value;

  int get idCargo => _idCargo;
  set idCargo(int value) => _idCargo = value;

  int get idUsuario => _idUsuario;
  set idUsuario(int value) => _idUsuario = value;

  DateTime get prazoInicial => _prazoInicial;
  set prazoInicial(DateTime value) => _prazoInicial = value;
}
