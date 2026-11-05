import 'package:shelf/shelf.dart';

import 'catalogs.dart';
import 'database.dart';
import 'http.dart';
import 'models/models.dart';
import 'security.dart';
import 'tasks.dart' show day;

const vacancyFrom = '''FROM vagas v
  JOIN clientes c ON c.id_cliente = v.clientes_id_cliente
  JOIN usuarios u ON u.id_usuario = v.usuarios_id_usuario
  JOIN etapas_funil e ON e.id = v.etapa_id''';
const vacancySelect =
    '''v.*, c.nome AS empresa, u.nome AS responsavel, e.nome AS etapa,
  coalesce((SELECT jsonb_agg(jsonb_build_object('id', d.id_divulgacao, 'nome', d.nome, 'chave', d.chave) ORDER BY d.id_divulgacao)
    FROM divulgacoes_has_vagas dv JOIN divulgacoes d ON d.id_divulgacao = dv.divulgacoes_id_divulgacao
    WHERE dv.vagas_id_vaga = v.id_vaga), '[]'::jsonb) AS canais''';

class Vacancies {
  final Database db;
  Vacancies(this.db);

  Row serialize(Row row) {
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
        'inscritos': null,
        'candidatosIdeais': null,
        'erros': null,
        'disponiveis': false
      }
    };
  }

  Future<Response> list(Request request) async {
    queryFields(request, {
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
      final value = request.url.queryParameters[entry.key];
      if (value == null) continue;
      args[entry.key] = integer(int.tryParse(value), entry.key);
      clauses.add('${entry.value} = @${entry.key}');
    }
    final channel = request.url.queryParameters['canalId'];
    if (channel != null) {
      args['canal'] = integer(int.tryParse(channel), 'canalId');
      clauses.add(
          'EXISTS (SELECT 1 FROM divulgacoes_has_vagas dv WHERE dv.vagas_id_vaga = v.id_vaga AND dv.divulgacoes_id_divulgacao = @canal)');
    }
    final search = request.url.queryParameters['busca'];
    if (search != null) {
      if (search.length > 150) invalid('busca deve ter até 150 caracteres.');
      args['busca'] = '%$search%';
      clauses.add('(v.cargo ILIKE @busca OR c.nome ILIKE @busca)');
    }
    return page(db, request, vacancySelect, vacancyFrom, clauses.join(' AND '),
        args, 'v.id_vaga DESC',
        map: serialize);
  }

  Future<Response> create(Request request, Identity user) async {
    user.require('C');
    final data = await body(request, {
      'cargo',
      'perfilDesejado',
      'clienteId',
      'responsavelId',
      'prazoInicial',
      'prazoFinal',
      'canais'
    });
    final args = <String, Object?>{
      'cargo': string(data, 'cargo', max: 80),
      'perfil': string(data, 'perfilDesejado', max: 255),
      'cliente': integer(data['clienteId'], 'clienteId'),
      'responsavel': integer(data['responsavelId'], 'responsavelId'),
      'inicio': date(data, 'prazoInicial'),
      'fim': date(data, 'prazoFinal')
    };
    dates(args['inicio'] as String, args['fim'] as String);
    final channels = ids(data['canais'], 'canais');
    args['divulgacao'] = channels.isEmpty ? null : channels.first;
    return db.transaction((tx) async {
      await tx.query('SELECT pg_advisory_xact_lock_shared(736289142)');
      await reference(tx, 'clientes', 'id_cliente', args['cliente'] as int);
      await reference(tx, 'usuarios', 'id_usuario', args['responsavel'] as int,
          active: true);
      for (final id in channels) {
        await reference(tx, 'divulgacoes', 'id_divulgacao', id);
      }
      final row = await tx.one(
          '''INSERT INTO vagas (cargo, perfil_deixado, clientes_id_cliente, usuarios_id_usuario,
        prazo_inicial, prazo_final, id_divulgacao, etapa_id)
        VALUES (@cargo, @perfil, @cliente, @responsavel, CAST(@inicio AS date), CAST(@fim AS date), @divulgacao,
          (SELECT id FROM etapas_funil ORDER BY ordem, id LIMIT 1)) RETURNING id_vaga''',
          args);
      final id = row!['id_vaga'] as int;
      for (final channel in channels) {
        final link =
            DivulgacaoVaga(divulgacoesIdDivulgacao: channel, vagasIdVaga: id);
        await tx.query(
            'INSERT INTO divulgacoes_has_vagas VALUES (@canal, @vaga)',
            {'canal': link.divulgacoesIdDivulgacao, 'vaga': link.vagasIdVaga});
      }
      return json(
          serialize((await tx.one(
              'SELECT $vacancySelect $vacancyFrom WHERE v.id_vaga = @id',
              {'id': id}))!),
          status: 201);
    });
  }
}
