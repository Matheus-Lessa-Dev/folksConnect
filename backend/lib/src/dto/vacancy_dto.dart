import '../database.dart';
import '../models/models.dart';
import 'task_dto.dart' show day;

Row serializeVacancy(Row row) {
  final model = Vaga(
      idVaga: row['id_vaga'] as int,
      cargo: row['cargo'] as String,
      perfilDeixado: row['perfil_deixado'] as String,
      prazoInicial: row['prazo_inicial'] as DateTime,
      prazoFinal: row['prazo_final'] as DateTime,
      idDivulgacao: row['id_divulgacao'] as int?,
      candInscritos: row['cand_inscritos'] as int?,
      candIdeias: row['cand_ideias'] as int?,
      erros: row['erros'] as int?,
      clientesIdCliente: row['clientes_id_cliente'] as int,
      usuariosIdUsuario: row['usuarios_id_usuario'] as int,
      usuariosCargosIdCargo: row['usuarios_cargos_id_cargo'] as int?);
  return {
    'id': model.idVaga,
    'cargo': model.cargo,
    'perfilDesejado': model.perfilDeixado,
    'clienteId': model.clientesIdCliente,
    'empresa': row['empresa'],
    'responsavelId': model.usuariosIdUsuario,
    'responsavel': row['responsavel'],
    'prazoInicial': day(model.prazoInicial),
    'prazoFinal': day(model.prazoFinal),
    'etapaId': row['etapa_id'],
    'etapa': row['etapa'],
    'canais': row['canais'],
    'indicadores': {
      'inscritos': row['inscritos'],
      'candidatosIdeais': row['ideais'],
      'erros': row['erros_reais'],
      'disponiveis': true
    }
  };
}
