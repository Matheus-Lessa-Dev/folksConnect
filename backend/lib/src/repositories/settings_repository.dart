import '../database.dart';

class SettingsRepository {
  Future<List<Row>> updateSectionItem(
          Database session, String table, String key,
          [Map<String, Object?> args = const {}]) =>
      session.query(
          'UPDATE $table SET nome = @nome, ordem = @ordem WHERE $key = @id',
          args);

  Future<List<Row>> insertSectionItem(Database session, String table,
          [Map<String, Object?> args = const {}]) =>
      session.query(
          'INSERT INTO $table (nome, ordem) VALUES (@nome, @ordem)', args);

  Future<List<Row>> temporaryName(Database session, String table, String key,
          [Map<String, Object?> args = const {}]) =>
      session.query('UPDATE $table SET nome = @nome WHERE $key = @id', args);

  Future<List<Row>> deleteSectionItem(
          Database session, String table, String key,
          [Map<String, Object?> args = const {}]) =>
      session.query('DELETE FROM $table WHERE $key = @id', args);

  Future<List<Row>> lockConfiguration(Database session,
          [Map<String, Object?> args = const {}]) =>
      session.query('SELECT pg_advisory_xact_lock(736289142)', args);

  Future<List<Row>> snapshot(Database session,
          [Map<String, Object?> args = const {}]) =>
      session.query('SET TRANSACTION ISOLATION LEVEL REPEATABLE READ', args);

  Future<List<Row>> readSection(Database session, String table, String key,
          [Map<String, Object?> args = const {}]) =>
      session.query(
          'SELECT $key AS id, nome, ordem FROM $table ORDER BY ordem, $key',
          args);
}
