import '../database.dart';

class ImportRepository {
  Future<void> lock(Database db, int author, String key) async {
    await db.query('SELECT pg_advisory_xact_lock(hashtextextended(@chave, 0))',
        {'chave': 'import:$author:$key'});
  }

  Future<Row?> findByKey(Database db, int author, String key) => db.one(
      'SELECT id, checksum, quantidade FROM importacoes WHERE autor_id = @autor AND chave = @chave',
      {'autor': author, 'chave': key});
  Future<Row?> create(Database db, Map<String, Object?> args) => db.one('''
    INSERT INTO importacoes (autor_id, chave, checksum, quantidade)
    VALUES (@autor, @chave, @checksum, @quantidade) RETURNING id''', args);
  Future<void> link(Database db, int batch, int vacancy) async {
    await db.query('INSERT INTO importacoes_vagas VALUES (@lote, @vaga)',
        {'lote': batch, 'vaga': vacancy});
  }

  Future<Row?> details(Database db, int id, int author, bool admin) => db.one(
      '''
    SELECT i.id, i.quantidade, i.criado_em AS "criadoEm",
      (SELECT jsonb_agg(vaga_id ORDER BY vaga_id) FROM importacoes_vagas WHERE importacao_id = i.id) AS vagas
    FROM importacoes i WHERE i.id = @id AND (i.autor_id = @autor OR @admin)''',
      {'id': id, 'autor': author, 'admin': admin});
}
