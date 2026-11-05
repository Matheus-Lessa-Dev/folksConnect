import 'dart:io';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:postgres/postgres.dart';

typedef Row = Map<String, dynamic>;

class Database {
  final Session session;
  Database(this.session);

  static Pool connect(Map<String, String> env) => Pool.withEndpoints(
        [
          Endpoint(
            host: env['DATABASE_HOST'] ?? 'localhost',
            port: int.parse(env['DATABASE_PORT'] ?? '5432'),
            database: env['DATABASE_NAME'] ?? 'folks_connect',
            username: env['DATABASE_USER'] ?? 'folks_connect',
            password: env['DATABASE_PASSWORD'] ?? 'folks_connect_dev',
          )
        ],
        settings: PoolSettings(
          maxConnectionCount: 10,
          sslMode: env['DATABASE_SSL'] == 'require'
              ? SslMode.require
              : SslMode.disable,
          queryTimeout: const Duration(seconds: 30),
        ),
      );

  Future<List<Row>> query(String sql,
      [Map<String, Object?> args = const {}]) async {
    final result = await session.execute(Sql.named(sql), parameters: args);
    return result.map((row) => row.toColumnMap()).toList();
  }

  Future<Row?> one(String sql, [Map<String, Object?> args = const {}]) async {
    final rows = await query(sql, args);
    return rows.isEmpty ? null : rows.first;
  }

  Future<T> transaction<T>(Future<T> Function(Database) action) async {
    final current = session;
    if (current is TxSession) return action(this);
    return (current as SessionExecutor).runTx((tx) => action(Database(tx)));
  }

  Future<void> migrate(String path) async {
    final files = await Directory(path)
        .list()
        .where((f) => f.path.endsWith('.sql'))
        .cast<File>()
        .toList();
    files.sort((a, b) => a.path.compareTo(b.path));
    if (files.isEmpty) throw StateError('Nenhuma migration em $path');
    await transaction((db) async {
      await db.query('SELECT pg_advisory_xact_lock(736289140)');
      await db.query(
          'CREATE TABLE IF NOT EXISTS schema_migrations (nome TEXT PRIMARY KEY, checksum TEXT NOT NULL, aplicado_em TIMESTAMPTZ NOT NULL DEFAULT now())');
      for (final file in files) {
        final name = file.uri.pathSegments.last;
        final bytes = await file.readAsBytes();
        final sql = utf8.decode(bytes).replaceAll('\r\n', '\n');
        final checksum = sha256.convert(utf8.encode(sql)).toString();
        final windowsChecksum = sha256
            .convert(utf8.encode(sql.replaceAll('\n', '\r\n')))
            .toString();
        final applied = await db.one(
            'SELECT checksum FROM schema_migrations WHERE nome = @nome',
            {'nome': name});
        if (applied != null) {
          if (applied['checksum'] != checksum &&
              applied['checksum'] != windowsChecksum) {
            throw StateError('Migration já aplicada foi alterada: $name');
          }
          continue;
        }
        // SQL versionado do repositório, nunca entrada HTTP.
        await db.session.execute(sql, queryMode: QueryMode.simple);
        await db.query(
            'INSERT INTO schema_migrations (nome, checksum) VALUES (@nome, @checksum)',
            {'nome': name, 'checksum': checksum});
        stdout.writeln('Migration aplicada: $name');
      }
    });
  }
}
