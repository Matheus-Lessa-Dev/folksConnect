import '../database.dart';
import '../dto/input.dart';
import '../dto/validation.dart';
import 'shared_repository.dart';

const candidateColumns = '''id, vaga_id AS "vagaId", nome, email, telefone,
  perfil_ideal AS "perfilIdeal", status, motivo_erro AS "motivoErro",
  criado_em AS "criadoEm", atualizado_em AS "atualizadoEm"''';

class CandidateRepository {
  Future<bool> vacancyExists(Database db, int id) async =>
      await db.one('SELECT 1 FROM vagas WHERE id_vaga = @id', {'id': id}) !=
      null;
  Future<Row> list(Database db, int vacancy, QueryInput query) {
    query.only({'busca', 'status', 'page', 'limit'});
    final search = query.values['busca'] ?? '';
    if (search.length > 150) invalid('busca deve ter até 150 caracteres.');
    final status = query.values['status'];
    return page(
        db,
        query,
        candidateColumns,
        'FROM candidatos_vaga',
        'vaga_id = @vaga AND (nome ILIKE @busca OR email ILIKE @busca)${status == null ? '' : ' AND status = @status'}',
        {
          'vaga': vacancy,
          'busca': '%$search%',
          if (status != null) 'status': status
        },
        'id');
  }

  Future<Row?> find(Database db, int vacancy, int id, {bool lock = false}) =>
      db.one(
          'SELECT $candidateColumns FROM candidatos_vaga WHERE id = @id AND vaga_id = @vaga${lock ? ' FOR UPDATE' : ''}',
          {'id': id, 'vaga': vacancy});
  Future<Row?> create(Database db, Map<String, Object?> args) => db.one('''
    INSERT INTO candidatos_vaga (vaga_id, nome, email, telefone, perfil_ideal, status, motivo_erro)
    VALUES (@vaga, @nome, @email, @telefone, @ideal, @status, @erro) RETURNING $candidateColumns''',
      args);
  Future<Row?> update(Database db, Map<String, Object?> args) => db.one('''
    UPDATE candidatos_vaga SET nome = @nome, email = @email, telefone = @telefone,
      perfil_ideal = @ideal, status = @status, motivo_erro = @erro, atualizado_em = now()
    WHERE id = @id AND vaga_id = @vaga RETURNING $candidateColumns''', args);
  Future<Row?> delete(Database db, int vacancy, int id) => db.one(
      'DELETE FROM candidatos_vaga WHERE id = @id AND vaga_id = @vaga RETURNING id',
      {'id': id, 'vaga': vacancy});
}
