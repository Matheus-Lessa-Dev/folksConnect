import '../database.dart';
import '../models/models.dart';
import 'validation.dart';

String day(DateTime value) => value.toIso8601String().substring(0, 10);
String description(Map<String, dynamic> data) {
  final value = data['descricao'] ?? '';
  if (value is! String || value.length > 10000) {
    invalid('descricao deve ser texto de até 10000 caracteres.');
  }
  return value.trim();
}

Row serializeTask(Row row) {
  final model = Tarefa(
      idTarefa: row['id_tarefa'] as int,
      idCargo: row['id_cargo'] as int?,
      idUsuario: row['id_usuario'] as int,
      prazoInicial: row['prazo_inicial'] as DateTime);
  return {
    'id': model.idTarefa,
    'titulo': row['titulo'],
    'descricao': row['descricao'],
    'cargo': row['cargo'],
    'responsavelId': model.idUsuario,
    'responsavel': row['responsavel'],
    'clienteId': row['id_cliente'],
    'empresa': row['empresa'],
    'projetoId': row['id_projeto'],
    'projeto': row['projeto'],
    'prioridadeId': row['id_prioridade'],
    'prioridade': row['prioridade'],
    'prazoInicial': day(model.prazoInicial),
    'prazoFinal':
        row['prazo_final'] == null ? null : day(row['prazo_final'] as DateTime),
    'statusId': row['status_id'],
    'status': row['status'],
    'etapaId': row['etapa_id'],
    'etapa': row['etapa']
  };
}
