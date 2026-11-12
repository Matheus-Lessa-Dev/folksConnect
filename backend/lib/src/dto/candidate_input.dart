import 'input.dart';
import 'validation.dart';

class CandidateInput {
  static const statuses = {
    'inscrito',
    'em_analise',
    'aprovado',
    'reprovado',
    'erro'
  };
  final Map<String, Object?> parameters;
  CandidateInput._(this.parameters);
  factory CandidateInput.parse(JsonInput input,
      {Map<String, dynamic>? current}) {
    final data = input.only(
        {'nome', 'email', 'telefone', 'perfilIdeal', 'status', 'motivoErro'});
    if (current != null && data.isEmpty) {
      invalid('Informe ao menos um campo editável.');
    }
    final values = <String, dynamic>{
      'status': 'inscrito',
      'perfilIdeal': false,
      if (current != null) ...current,
      ...data,
    };
    final status = string(values, 'status', max: 20);
    if (!statuses.contains(status)) invalid('Status de candidato inválido.');
    if (values['perfilIdeal'] is! bool) {
      invalid('perfilIdeal deve ser booleano.');
    }
    if (status != 'erro' && data['motivoErro'] != null) {
      invalid('motivoErro só é permitido no status erro.');
    }
    return CandidateInput._({
      'nome': string(values, 'nome'),
      'email': email(values, 'email'),
      'telefone': values['telefone'] == null
          ? null
          : string(values, 'telefone', max: 40),
      'ideal': values['perfilIdeal'],
      'status': status,
      'erro': status == 'erro' ? string(values, 'motivoErro', max: 500) : null,
    });
  }
}
