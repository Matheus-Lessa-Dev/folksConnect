import 'dart:io';

import 'package:folks_connect_backend/src/database.dart';
import 'package:postgres/postgres.dart';
import 'package:test/test.dart';

void main() {
  test('upgrade do schema 001 preserva dados e vínculos legados', () async {
    final env = Platform.environment;
    if (!(env['DATABASE_NAME'] ?? '').endsWith('_test')) {
      throw StateError('Use banco exclusivo *_test.');
    }
    final connection = await Connection.open(
        Endpoint(
          host: env['DATABASE_HOST'] ?? 'localhost',
          port: int.parse(env['DATABASE_PORT'] ?? '5432'),
          database: env['DATABASE_NAME']!,
          username: env['DATABASE_USER'] ?? 'folks_connect',
          password: env['DATABASE_PASSWORD'] ?? 'folks_connect_dev',
        ),
        settings: const ConnectionSettings(sslMode: SslMode.disable));
    final schema = 'migration_probe_${DateTime.now().microsecondsSinceEpoch}';
    final directory = await Directory.systemTemp.createTemp('folks-migration-');
    try {
      await connection.execute('CREATE SCHEMA $schema');
      await connection.execute('SET search_path TO $schema');
      final db = Database(connection);
      await File('database/migrations/001_initial_schema.sql')
          .copy('${directory.path}/001_initial_schema.sql');
      await db.migrate(directory.path);
      await connection.execute('''
        INSERT INTO cargos (chave, nome) VALUES ('legado', 'Cargo legado');
        INSERT INTO projetos (nome) VALUES ('Projeto legado');
        INSERT INTO clientes (nome, cnpj, representante) VALUES ('Cliente legado', '12345678000100', 'Representante');
        INSERT INTO divulgacoes (chave, nome) VALUES ('legado', 'Canal legado');
        INSERT INTO prioridades (nome, valor) VALUES ('Prioridade legada', 5);
        INSERT INTO checklists (nome) VALUES ('Modelo A'), ('Modelo B');
        INSERT INTO usuarios (email, cargos_id_cargo, projetos_id_projeto) VALUES ('legado@folks.test', 1, 1);
        INSERT INTO tarefas (id_cargo, id_usuario, prazo_inicial, id_cliente, id_projeto, id_prioridade)
          VALUES (1, 1, '2026-11-03', 1, 1, 1);
        INSERT INTO checklists_has_tarefas VALUES (1, 1);
        INSERT INTO vagas (cargo, perfil_deixado, prazo_inicial, prazo_final, id_divulgacao,
          cand_inscritos, cand_ideias, erros, clientes_id_cliente, usuarios_id_usuario, usuarios_cargos_id_cargo)
          VALUES ('Cargo oportunidade', 'Perfil legado', '2026-11-03', '2026-12-03', 1, 6, 2, 1, 1, 1, 1);
      ''', queryMode: QueryMode.simple);
      await db.migrate('database/migrations');
      expect(
          (await db.one(
              'SELECT email FROM usuarios WHERE id_usuario = 1'))!['email'],
          'legado@folks.test');
      final task = await db.one('SELECT * FROM tarefas WHERE id_tarefa = 1');
      expect(task!['id_cargo'], 1);
      expect(task['id_usuario'], 1);
      expect(task['status_id'], isNotNull);
      expect(task['etapa_id'], isNotNull);
      expect(
          (await db.one(
                  'SELECT nome FROM itens_checklist_tarefa WHERE tarefa_id = 1'))![
              'nome'],
          'Modelo A');
      expect(
          (await db.query('SELECT ordem FROM checklists ORDER BY ordem'))
              .map((r) => r['ordem']),
          [0, 1]);
      expect(
          (await db.one('SELECT cand_inscritos FROM vagas WHERE id_vaga = 1'))![
              'cand_inscritos'],
          6);
      expect(
          (await db.one(
                  'SELECT divulgacoes_id_divulgacao FROM divulgacoes_has_vagas WHERE vagas_id_vaga = 1'))![
              'divulgacoes_id_divulgacao'],
          1);
      await db.query(
          "UPDATE usuarios SET cargos_id_cargo = (SELECT id_cargo FROM cargos WHERE chave = 'analista') WHERE id_usuario = 1");
      expect(
          (await db.one(
                  'SELECT usuarios_id_usuario FROM vagas WHERE id_vaga = 1'))![
              'usuarios_id_usuario'],
          1);
      await db.migrate('database/migrations');
      final migration = File('${directory.path}/001_initial_schema.sql');
      await migration.writeAsString(
          '${await migration.readAsString()}\n-- alteração indevida de teste\n');
      await expectLater(db.migrate(directory.path), throwsStateError);
    } finally {
      if (!RegExp(r'^migration_probe_[0-9]+$').hasMatch(schema)) {
        throw StateError('Schema de teste inválido.');
      }
      await connection.execute('DROP SCHEMA IF EXISTS $schema CASCADE');
      await connection.close();
      await directory.delete(recursive: true);
    }
  },
      skip: Platform.environment['RUN_DB_TESTS'] != 'true'
          ? 'Requer PostgreSQL isolado *_test.'
          : false);
}
