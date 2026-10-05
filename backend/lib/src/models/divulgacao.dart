class Divulgacao {
  int _idDivulgacao;
  String _chave;
  String _nome;

  Divulgacao({
    required int idDivulgacao,
    required String chave,
    required String nome,
  }) : _idDivulgacao = idDivulgacao,
       _chave = chave,
       _nome = nome;

  int get idDivulgacao => _idDivulgacao;
  set idDivulgacao(int value) => _idDivulgacao = value;

  String get chave => _chave;
  set chave(String value) => _chave = value;

  String get nome => _nome;
  set nome(String value) => _nome = value;
}
