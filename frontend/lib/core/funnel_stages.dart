import 'package:flutter/foundation.dart';

/// Etapas do funil cadastradas em Configurações. As barras de progresso e os
/// selos de etapa leem esta lista; a posição na lista identifica a etapa.
class FunnelStages extends ChangeNotifier {
  FunnelStages([List<String>? names]) : _names = List.of(names ?? defaults);

  /// Etapas iniciais, usadas até o usuário cadastrar as suas.
  static const defaults = ['Triagem', 'Entrevista', 'Retorno', 'Contratação'];

  List<String> _names;
  List<int>? _previousToCurrent;

  /// Disponível durante a notificação para preservar a etapa dos registros.
  int remapPrevious(int stage) {
    final mapping = _previousToCurrent;
    if (mapping == null || mapping.isEmpty) return clamp(stage);
    return mapping[stage.clamp(0, mapping.length - 1)];
  }

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

  void update(List<String> names, {List<int?>? previousIndices}) {
    if (names.isEmpty) throw ArgumentError('Informe ao menos uma etapa.');
    if (previousIndices != null && previousIndices.length != names.length) {
      throw ArgumentError('Mapeamento de etapas inválido.');
    }
    final oldNames = _names;
    _previousToCurrent = List.generate(oldNames.length, (oldIndex) {
      final newIndex = previousIndices == null
          ? names.indexWhere(
              (name) => name.toLowerCase() == oldNames[oldIndex].toLowerCase(),
            )
          : previousIndices.indexOf(oldIndex);
      return newIndex < 0 ? oldIndex.clamp(0, names.length - 1) : newIndex;
    });
    _names = List.of(names);
    try {
      notifyListeners();
    } finally {
      _previousToCurrent = null;
    }
  }
}
