import 'package:flutter/foundation.dart';

/// Etapas do funil cadastradas em Configurações. As barras de progresso e os
/// selos de etapa leem esta lista; a posição na lista identifica a etapa.
class FunnelStages extends ChangeNotifier {
  FunnelStages([List<String>? names]) : _names = List.of(names ?? defaults);

  /// Etapas iniciais, usadas até o usuário cadastrar as suas.
  static const defaults = ['Triagem', 'Entrevista', 'Retorno', 'Contratação'];

  List<String> _names;

  List<String> get names => List.unmodifiable(_names);
  int get length => _names.length;

  /// Limita [stage] à lista atual, caso ela tenha sido reduzida.
  int clamp(int stage) => stage < 0
      ? 0
      : stage >= _names.length
      ? _names.length - 1
      : stage;

  String label(int stage) => _names[clamp(stage)];

  /// Posições das etapas posteriores a [stage].
  List<int> following(int stage) => [
    for (var index = clamp(stage) + 1; index < _names.length; index++) index,
  ];

  void update(List<String> names) {
    if (names.isEmpty) throw ArgumentError('Informe ao menos uma etapa.');
    _names = List.of(names);
    notifyListeners();
  }
}
