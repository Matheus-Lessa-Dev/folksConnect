import 'input.dart';
import 'validation.dart';

class VacancyInput {
  static const fields = {
    'cargo',
    'perfilDesejado',
    'clienteId',
    'responsavelId',
    'prazoInicial',
    'prazoFinal',
    'canais'
  };
  final Map<String, Object?> parameters;
  final List<int> channels;
  VacancyInput._(this.parameters, this.channels);
  factory VacancyInput.create(JsonInput input) {
    final data = input.only(fields);
    final args = <String, Object?>{
      'cargo': string(data, 'cargo', max: 80),
      'perfil': string(data, 'perfilDesejado', max: 255),
      'cliente': integer(data['clienteId'], 'clienteId'),
      'responsavel': integer(data['responsavelId'], 'responsavelId'),
      'inicio': date(data, 'prazoInicial'),
      'fim': date(data, 'prazoFinal'),
    };
    dates(args['inicio'] as String, args['fim'] as String);
    final channels = ids(data['canais'], 'canais');
    args['divulgacao'] = channels.isEmpty ? null : channels.first;
    return VacancyInput._(Map.unmodifiable(args), List.unmodifiable(channels));
  }
}
