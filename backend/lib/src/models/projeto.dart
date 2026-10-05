class Projeto {
  int _idProjeto;
  String _nome;

  Projeto({required int idProjeto, required String nome})
    : _idProjeto = idProjeto,
      _nome = nome;

  int get idProjeto => _idProjeto;
  set idProjeto(int value) => _idProjeto = value;

  String get nome => _nome;
  set nome(String value) => _nome = value;
}
