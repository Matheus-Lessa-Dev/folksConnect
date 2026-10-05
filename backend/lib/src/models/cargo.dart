class Cargo {
  int _idCargo;
  String _chave;
  String _nome;

  Cargo({required int idCargo, required String chave, required String nome})
    : _idCargo = idCargo,
      _chave = chave,
      _nome = nome;

  int get idCargo => _idCargo;
  set idCargo(int value) => _idCargo = value;

  String get chave => _chave;
  set chave(String value) => _chave = value;

  String get nome => _nome;
  set nome(String value) => _nome = value;
}
