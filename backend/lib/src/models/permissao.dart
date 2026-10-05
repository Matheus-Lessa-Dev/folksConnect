class Permissao {
  int _idPermissoes;
  String _nome;
  String _chave;

  Permissao({
    required int idPermissoes,
    required String nome,
    required String chave,
  }) : _idPermissoes = idPermissoes,
       _nome = nome,
       _chave = chave;

  int get idPermissoes => _idPermissoes;
  set idPermissoes(int value) => _idPermissoes = value;

  String get nome => _nome;
  set nome(String value) => _nome = value;

  String get chave => _chave;
  set chave(String value) => _chave = value;
}
