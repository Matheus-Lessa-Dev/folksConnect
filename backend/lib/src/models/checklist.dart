class Checklist {
  int _idChecklist;
  String _nome;

  Checklist({required int idChecklist, required String nome})
    : _idChecklist = idChecklist,
      _nome = nome;

  int get idChecklist => _idChecklist;
  set idChecklist(int value) => _idChecklist = value;

  String get nome => _nome;
  set nome(String value) => _nome = value;
}
