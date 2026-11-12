import '../database.dart';
import '../dto/input.dart';
import '../dto/validation.dart';
import 'shared_repository.dart';
import '../dto/vacancy_dto.dart';

const vacancyFrom = '''FROM vagas v
  JOIN clientes c ON c.id_cliente = v.clientes_id_cliente
  JOIN usuarios u ON u.id_usuario = v.usuarios_id_usuario
  JOIN etapas_funil e ON e.id = v.etapa_id''';
const vacancySelect =
    '''v.*, c.nome AS empresa, u.nome AS responsavel, e.nome AS etapa,
  coalesce((SELECT jsonb_agg(jsonb_build_object('id', d.id_divulgacao, 'nome', d.nome, 'chave', d.chave) ORDER BY d.id_divulgacao)
    FROM divulgacoes_has_vagas dv JOIN divulgacoes d ON d.id_divulgacao = dv.divulgacoes_id_divulgacao
    WHERE dv.vagas_id_vaga = v.id_vaga), '[]'::jsonb) AS canais,
  (SELECT count(*) FROM candidatos_vaga cv WHERE cv.vaga_id = v.id_vaga) AS inscritos,
  (SELECT count(*) FROM candidatos_vaga cv WHERE cv.vaga_id = v.id_vaga AND cv.perfil_ideal) AS ideais,
  (SELECT count(*) FROM candidatos_vaga cv WHERE cv.vaga_id = v.id_vaga AND cv.status = 'erro') AS erros_reais''';

class VacancyRepository {
  Future<Row?> lock(Database db, int id) => db.one(
      'SELECT v.*, e.ordem FROM vagas v JOIN etapas_funil e ON e.id = v.etapa_id WHERE v.id_vaga = @id FOR UPDATE OF v',
      {'id': id});
  Future<Row?> stage(Database db, int id) =>
      db.one('SELECT ordem FROM etapas_funil WHERE id = @id', {'id': id});
  Future<void> update(Database db, Map<String, Object?> args) async {
    await db.query('''UPDATE vagas SET cargo = @cargo, perfil_deixado = @perfil,
      clientes_id_cliente = @cliente, usuarios_id_usuario = @responsavel,
      prazo_inicial = CAST(@inicio AS date), prazo_final = CAST(@fim AS date),
      id_divulgacao = @divulgacao, etapa_id = @etapa WHERE id_vaga = @id''',
        args);
  }

  Future<void> clearChannels(Database db, int id) async {
    await db.query(
        'DELETE FROM divulgacoes_has_vagas WHERE vagas_id_vaga = @id',
        {'id': id});
  }

  Future<Row> list(Database db, QueryInput query) async {
    query.only({
      'clienteId',
      'responsavelId',
      'etapaId',
      'canalId',
      'busca',
      'page',
      'limit'
    });
    final clauses = <String>['TRUE'];
    final args = <String, Object?>{};
    const filters = {
      'clienteId': 'v.clientes_id_cliente',
      'responsavelId': 'v.usuarios_id_usuario',
      'etapaId': 'v.etapa_id'
    };
    for (final entry in filters.entries) {
      final value = query.values[entry.key];
      if (value == null) continue;
      args[entry.key] = integer(int.tryParse(value), entry.key);
      clauses.add('${entry.value} = @${entry.key}');
    }
    final channel = query.values['canalId'];
    if (channel != null) {
      args['canal'] = integer(int.tryParse(channel), 'canalId');
      clauses.add(
          'EXISTS (SELECT 1 FROM divulgacoes_has_vagas dv WHERE dv.vagas_id_vaga = v.id_vaga AND dv.divulgacoes_id_divulgacao = @canal)');
    }
    final search = query.values['busca'];
    if (search != null) {
      if (search.length > 150) invalid('busca deve ter até 150 caracteres.');
      args['busca'] = '%$search%';
      clauses.add('(v.cargo ILIKE @busca OR c.nome ILIKE @busca)');
    }
    return page(db, query, vacancySelect, vacancyFrom, clauses.join(' AND '),
        args, 'v.id_vaga DESC',
        map: serializeVacancy);
  }

  Future<Row?> findDetails(Database session,
          [Map<String, Object?> args = const {}]) =>
      session.one(
          'SELECT $vacancySelect $vacancyFrom WHERE v.id_vaga = @id', args);

  Future<List<Row>> insertChannel(Database session,
          [Map<String, Object?> args = const {}]) =>
      session.query(
          'INSERT INTO divulgacoes_has_vagas VALUES (@canal, @vaga)', args);

  Future<Row?> insertVacancy(Database session,
          [Map<String, Object?> args = const {}]) =>
      session.one(
          '''INSERT INTO vagas (cargo, perfil_deixado, clientes_id_cliente, usuarios_id_usuario,
        prazo_inicial, prazo_final, id_divulgacao, etapa_id)
        VALUES (@cargo, @perfil, @cliente, @responsavel, CAST(@inicio AS date), CAST(@fim AS date), @divulgacao,
          (SELECT id FROM etapas_funil ORDER BY ordem, id LIMIT 1)) RETURNING id_vaga''',
          args);

  Future<List<Row>> lockConfiguration(Database session,
          [Map<String, Object?> args = const {}]) =>
      session.query('SELECT pg_advisory_xact_lock_shared(736289142)', args);
}
