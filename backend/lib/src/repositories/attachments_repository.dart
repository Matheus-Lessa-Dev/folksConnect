import '../database.dart';

class AttachmentRepository {
  Future<List<Row>> deleteAttachment(Database session,
          [Map<String, Object?> args = const {}]) =>
      session.query(
          'DELETE FROM anexos WHERE id = @id AND tarefa_id = @tarefa RETURNING id',
          args);

  Future<Row?> findDownload(Database session,
          [Map<String, Object?> args = const {}]) =>
      session.one(
          'SELECT nome, content_type, conteudo FROM anexos WHERE id = @id AND tarefa_id = @tarefa',
          args);

  Future<Row?> insertAttachment(Database session,
          [Map<String, Object?> args = const {}]) =>
      session.one(
          '''INSERT INTO anexos (tarefa_id, nome, content_type, tamanho, conteudo)
          VALUES (@tarefa, @nome, @tipo, @tamanho, @conteudo)
          RETURNING id, nome, content_type AS "contentType", tamanho, criado_em AS "criadoEm"''',
          args);

  Future<Row?> findTask(Database session,
          [Map<String, Object?> args = const {}]) =>
      session.one('SELECT id_tarefa FROM tarefas WHERE id_tarefa = @id', args);
}
