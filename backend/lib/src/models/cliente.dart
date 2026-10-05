class Cliente {
  int _idCliente;
  String _nome;
  String _cnpj;
  String _representante;

  Cliente({
    required int idCliente,
    required String nome,
    required String cnpj,
    required String representante,
  }) : _idCliente = idCliente,
       _nome = nome,
       _cnpj = cnpj,
       _representante = representante;

  int get idCliente => _idCliente;
  set idCliente(int value) => _idCliente = value;

  String get nome => _nome;
  set nome(String value) => _nome = value;

  String get cnpj => _cnpj;
  set cnpj(String value) => _cnpj = value;

  String get representante => _representante;
  set representante(String value) => _representante = value;
}
