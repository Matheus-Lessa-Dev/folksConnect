class Prioridade {
  int _idPrioridade;
  String _nome;
  int _valor;

  Prioridade({
    required int idPrioridade,
    required String nome,
    required int valor,
  }) : _idPrioridade = idPrioridade,
       _nome = nome,
       _valor = valor;

  int get idPrioridade => _idPrioridade;
  set idPrioridade(int value) => _idPrioridade = value;

  String get nome => _nome;
  set nome(String value) => _nome = value;

  int get valor => _valor;
  set valor(int value) => _valor = value;
}
