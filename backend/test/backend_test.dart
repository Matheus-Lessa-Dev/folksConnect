import 'dart:convert';
import 'dart:io';

import 'package:folks_connect_backend/src/application.dart';
import 'package:folks_connect_backend/src/database.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:test/test.dart';
import 'package:folks_connect_backend/src/security.dart';

import 'smtp_capture.dart';

void main() {
  final enabled = Platform.environment['RUN_DB_TESTS'] == 'true';
  group('backend integrado', () {
    late dynamic pool;
    late Database db;
    HttpServer? server;
    late Uri base;
    final client = HttpClient();
    var token = '';
    var taskId = 0;
    final env = {
      ...Platform.environment,
      'APP_ENV': 'development',
      'DEV_SEED': 'true',
      'DEV_ADMIN_EMAIL': 'admin@folks.test',
      'DEV_ADMIN_PASSWORD': 'FolksTest!2026'
    };

    Future<(int, dynamic)> call(String method, String path,
        {Object? data, String? authorization}) async {
      final request = await client.openUrl(method, base.resolve(path));
      if (authorization != null) {
        request.headers.set('authorization', 'Bearer $authorization');
      }
      if (data != null) {
        request.headers.contentType = ContentType.json;
        request.write(jsonEncode(data));
      }
      final response = await request.close();
      final text = await utf8.decoder.bind(response).join();
      return (response.statusCode, text.isEmpty ? null : jsonDecode(text));
    }

    setUpAll(() async {
      if (!(env['DATABASE_NAME'] ?? '').endsWith('_test')) {
        throw StateError(
            'DATABASE_NAME deve terminar em _test e ser exclusivo dos testes.');
      }
      pool = Database.connect(env);
      db = Database(pool);
      await db.migrate('database/migrations');
      await db.query(
          'TRUNCATE usuarios, clientes, divulgacoes, projetos, limites_auth RESTART IDENTITY CASCADE');
      final app = Application(db, env);
      await app.auth.seedDevelopment();
      server = await shelf_io.serve(app.call, '127.0.0.1', 0);
      base = Uri.parse('http://127.0.0.1:${server!.port}');
    });
    tearDownAll(() async {
      client.close(force: true);
      await server?.close(force: true);
      await pool.close();
    });

    test('migrations são idempotentes, health verifica o banco', () async {
      await db.migrate('database/migrations');
      expect((await db.query('SELECT * FROM schema_migrations')).length, 4);
      expect((await call('GET', '/api/health')).$1, 200);
      expect((await call('GET', '/api/usuarios/me')).$1, 401);
    });
    test('login, perfil e bloqueio de elevação de acesso', () async {
      expect(
          (await call('POST', '/api/auth/login',
                  data: {'email': env['DEV_ADMIN_EMAIL'], 'senha': 'errada'}))
              .$1,
          401);
      final login = await call('POST', '/api/auth/login', data: {
        'email': env['DEV_ADMIN_EMAIL'],
        'senha': env['DEV_ADMIN_PASSWORD']
      });
      expect(login.$1, 200);
      token = login.$2['token'] as String;
      expect(
          (await call('GET', '/api/usuarios/me', authorization: token))
              .$2['email'],
          env['DEV_ADMIN_EMAIL']);
      expect(
          (await call('PATCH', '/api/usuarios/me',
                  authorization: token, data: {'administrador': true}))
              .$1,
          400);
      expect(
          (await call('PATCH', '/api/usuarios/me',
                  authorization: token, data: {'nome': 'Admin Teste'}))
              .$2['nome'],
          'Admin Teste');
      expect((await db.one('SELECT token_hash FROM sessoes'))!['token_hash'],
          isNot(token));
    });
    test('logout revoga sessão persistida', () async {
      expect((await call('POST', '/api/auth/logout', authorization: token)).$1,
          204);
      expect((await call('GET', '/api/usuarios/me', authorization: token)).$1,
          401);
    });
    test('usuários, catálogos, autorização e desativação', () async {
      final admin = await call('POST', '/api/auth/login', data: {
        'email': env['DEV_ADMIN_EMAIL'],
        'senha': env['DEV_ADMIN_PASSWORD']
      });
      token = admin.$2['token'] as String;
      final roles = (await call('GET', '/api/cargos', authorization: token))
          .$2['items'] as List;
      final permissions =
          (await call('GET', '/api/permissoes', authorization: token))
              .$2['items'] as List;
      expect(permissions.length, 12);
      final created =
          await call('POST', '/api/usuarios', authorization: token, data: {
        'nome': 'Analista',
        'email': 'analista@folks.test',
        'senha': 'AnalistaTest!2026',
        'cargoId': roles.last['id'],
        'permissoes': <int>[]
      });
      expect(created.$1, 201);
      final id = created.$2['id'];
      final login = await call('POST', '/api/auth/login',
          data: {'email': 'analista@folks.test', 'senha': 'AnalistaTest!2026'});
      final restricted = login.$2['token'] as String;
      for (final (method, path) in <(String, String)>[
        ('POST', '/usuarios'),
        ('DELETE', '/usuarios/1'),
        ('POST', '/divulgacoes'),
        ('POST', '/vagas'),
        ('POST', '/tarefas'),
        ('PATCH', '/tarefas/1'),
        ('PATCH', '/tarefas/1/status'),
        ('POST', '/tarefas/1/avancos'),
        ('POST', '/tarefas/1/checklist/itens'),
        ('PATCH', '/tarefas/1/checklist/itens/1'),
        ('POST', '/tarefas/1/anexos'),
        ('DELETE', '/tarefas/1/anexos/1'),
      ]) {
        expect((await call(method, '/api$path', authorization: restricted)).$1,
            403,
            reason: '$method $path');
      }
      final restrictedConfig =
          (await call('GET', '/api/configuracoes', authorization: restricted))
              .$2;
      restrictedConfig['kanban'][0]['nome'] = 'Alteração sem permissão';
      expect(
          (await call('PUT', '/api/configuracoes',
                  authorization: restricted, data: restrictedConfig))
              .$1,
          403);
      expect(
          (await call('GET', '/api/usuarios', authorization: restricted))
              .$2['total'],
          2);
      expect(
          (await call('POST', '/api/clientes',
                  authorization: restricted, data: {'empresa': 'Empresa'}))
              .$1,
          403);
      expect(
          (await call('PATCH', '/api/usuarios/$id',
                  authorization: restricted,
                  data: {'cargoId': roles.first['id']}))
              .$1,
          403);
      expect(
          (await call('POST', '/api/clientes',
                  authorization: token, data: {'empresa': 'Empresa'}))
              .$1,
          201);
      expect(
          (await call('POST', '/api/clientes',
                  authorization: token,
                  data: {'empresa': 'Empresa', 'email': 'invalido'}))
              .$1,
          400);
      expect(
          (await call('POST', '/api/divulgacoes',
                  authorization: token,
                  data: {'nome': 'Canal', 'chave': 'canal-teste'}))
              .$1,
          201);
      expect(
          (await call('POST', '/api/divulgacoes',
                  authorization: token,
                  data: {'nome': 'Canal', 'chave': 'canal-teste'}))
              .$1,
          409);
      expect(
          (await call('PATCH', '/api/usuarios/$id',
                  authorization: token, data: {'cargoId': roles.first['id']}))
              .$1,
          200);
      expect(
          (await call('DELETE', '/api/usuarios/$id', authorization: token)).$1,
          204);
      expect(
          (await call('GET', '/api/usuarios/me', authorization: restricted)).$1,
          401);
      expect(
          (await call('POST', '/api/auth/login', data: {
            'email': 'analista@folks.test',
            'senha': 'AnalistaTest!2026'
          }))
              .$1,
          401);
      expect(
          (await call('GET', '/api/projetos?limit=0', authorization: token)).$1,
          400);
      expect(
          (await call('GET', '/api/prioridades?limit=100',
                  authorization: token))
              .$2['total'],
          greaterThanOrEqualTo(3));
    });
    test('recuperação informa SMTP ausente, sem simular envio', () async {
      expect(
          (await call('POST', '/api/auth/recuperar-senha',
                  data: {'email': env['DEV_ADMIN_EMAIL']}))
              .$1,
          503);
    });
    test(
        'cargo não promove administrador e criação não permite conceder acesso próprio',
        () async {
      final roles = (await call('GET', '/api/cargos', authorization: token))
          .$2['items'] as List;
      final permissions =
          (await call('GET', '/api/permissoes', authorization: token))
              .$2['items'] as List;
      final creator =
          await call('POST', '/api/usuarios', authorization: token, data: {
        'nome': 'Operador de usuários',
        'email': 'operador@folks.test',
        'senha': 'OperadorTest!2026',
        'cargoId': roles.first['id'],
        'permissoes': [permissions.singleWhere((p) => p['chave'] == 'E')['id']]
      });
      expect(creator.$1, 201);
      expect(creator.$2['administrador'], false);
      final login = await call('POST', '/api/auth/login',
          data: {'email': 'operador@folks.test', 'senha': 'OperadorTest!2026'});
      final limited = login.$2['token'] as String;
      expect(
          (await call('POST', '/api/vagas', authorization: limited)).$1, 403);
      final escalation =
          await call('POST', '/api/usuarios', authorization: limited, data: {
        'nome': 'Não deve existir',
        'email': 'escalacao@folks.test',
        'senha': 'EscalacaoTest!2026',
        'cargoId': roles.last['id'],
        'permissoes': [permissions.singleWhere((p) => p['chave'] == 'B')['id']]
      });
      expect(escalation.$1, 403);
      expect(
          (await call('GET', '/api/usuarios?busca=escalacao',
                  authorization: token))
              .$2['total'],
          0);
      final production =
          Application(db, {'APP_ENV': 'production', 'DEV_SEED': 'true'});
      await expectLater(production.auth.seedDevelopment(), throwsStateError);
    });
    test('configurações integrais, IDs estáveis, troca de nomes e rollback',
        () async {
      final original =
          (await call('GET', '/api/configuracoes', authorization: token)).$2;
      final desired = jsonDecode(jsonEncode(original)) as Map<String, dynamic>;
      desired['kanban'][0]['nome'] = original['kanban'][1]['nome'];
      desired['kanban'][1]['nome'] = original['kanban'][0]['nome'];
      desired['funil'].add({'nome': 'Etapa teste', 'ordem': 50});
      final saved = await call('PUT', '/api/configuracoes',
          authorization: token, data: desired);
      expect(saved.$1, 200);
      expect(saved.$2['kanban'][0]['id'], original['kanban'][0]['id']);
      expect(saved.$2['funil'].length, original['funil'].length + 1);
      final invalid = jsonDecode(jsonEncode(saved.$2));
      invalid['kanban'][0]['nome'] = 'Não deve persistir';
      invalid['checklist'] = [];
      expect(
          (await call('PUT', '/api/configuracoes',
                  authorization: token, data: invalid))
              .$1,
          400);
      expect((await call('GET', '/api/configuracoes', authorization: token)).$2,
          saved.$2);
      expect(
          (await call('PUT', '/api/configuracoes',
                  authorization: token, data: original))
              .$1,
          200);
    });
    test(
        'tarefa completa: filtros, edição, status independente, avanço e checklist',
        () async {
      final config =
          (await call('GET', '/api/configuracoes', authorization: token)).$2;
      final projects =
          (await call('GET', '/api/projetos', authorization: token))
              .$2['items'];
      final clients = (await call('GET', '/api/clientes', authorization: token))
          .$2['items'];
      final priorities =
          (await call('GET', '/api/prioridades', authorization: token))
              .$2['items'];
      final me =
          (await call('GET', '/api/usuarios/me', authorization: token)).$2;
      final input = {
        'titulo': 'Recrutamento integração',
        'descricao': 'Descrição inicial',
        'cargo': 'Desenvolvedor',
        'projetoId': projects[0]['id'],
        'clienteId': clients[0]['id'],
        'prioridadeId': priorities[0]['id'],
        'responsavelId': me['id'],
        'prazoInicial': '2026-11-03',
        'prazoFinal': '2026-11-30'
      };
      final created =
          await call('POST', '/api/tarefas', authorization: token, data: input);
      expect(created.$1, 201);
      taskId = created.$2['id'] as int;
      expect(created.$2['checklist'].length, config['checklist'].length);
      final stage = created.$2['etapaId'];
      expect(
          (await call('PATCH', '/api/tarefas/$taskId',
                  authorization: token,
                  data: {
                'descricao': '',
                'prioridadeId': priorities.last['id']
              }))
              .$1,
          200);
      final moved = await call('PATCH', '/api/tarefas/$taskId/status',
          authorization: token, data: {'statusId': config['kanban'][1]['id']});
      expect(moved.$1, 200);
      expect(moved.$2['etapaId'], stage);
      final filter = await call('GET',
          '/api/tarefas?projetoId=${projects[0]['id']}&statusId=${config['kanban'][1]['id']}&page=1&limit=1',
          authorization: token);
      expect(filter.$2['total'], 1);
      expect(filter.$2['items'].length, 1);
      expect(
          (await call('GET', '/api/tarefas?statusId=9999',
                  authorization: token))
              .$2['total'],
          0);
      expect(
          (await call('POST', '/api/tarefas/$taskId/avancos',
                  authorization: token,
                  data: {
                'etapaId': config['funil'][1]['id'],
                'responsavelId': 99999
              }))
              .$1,
          400);
      expect(
          (await call('GET', '/api/tarefas/$taskId', authorization: token))
              .$2['etapaId'],
          stage);
      final results = await Future.wait(List.generate(
          2,
          (_) => call('POST', '/api/tarefas/$taskId/avancos',
                  authorization: token,
                  data: {
                    'etapaId': config['funil'][1]['id'],
                    'responsavelId': me['id']
                  })));
      expect(results.map((r) => r.$1), unorderedEquals([201, 409]));
      final advanced =
          (await call('GET', '/api/tarefas/$taskId', authorization: token)).$2;
      expect(advanced['statusId'], config['kanban'][1]['id']);
      expect(advanced['avancos'].length, 1);
      final added = await call('POST', '/api/tarefas/$taskId/checklist/itens',
          authorization: token, data: {'nome': 'Conferir documento'});
      expect(added.$1, 201);
      final itemId = added.$2['id'];
      expect(
          (await call('PATCH', '/api/tarefas/$taskId/checklist/itens/$itemId',
                  authorization: token, data: {'concluido': true}))
              .$2['concluido'],
          true);
      expect(
          (await call('PATCH', '/api/tarefas/$taskId/checklist/itens/$itemId',
                  authorization: token, data: {'concluido': false}))
              .$2['concluido'],
          false);
      final second = await call('POST', '/api/tarefas',
          authorization: token, data: {...input, 'titulo': 'Outra tarefa'});
      expect(
          (await call('PATCH',
                  '/api/tarefas/${second.$2['id']}/checklist/itens/$itemId',
                  authorization: token, data: {'concluido': true}))
              .$1,
          404);
      final changed = jsonDecode(jsonEncode(config));
      changed['checklist'][0]['nome'] = 'Novo padrão';
      expect(
          (await call('PUT', '/api/configuracoes',
                  authorization: token, data: changed))
              .$1,
          200);
      expect(
          (await call('GET', '/api/tarefas/$taskId', authorization: token))
              .$2['checklist'][0]['nome'],
          config['checklist'][0]['nome']);
      final blocked = jsonDecode(jsonEncode(changed));
      blocked['kanban'][0]['nome'] = 'Nome que será revertido';
      blocked['funil'].removeAt(1);
      expect(
          (await call('PUT', '/api/configuracoes',
                  authorization: token, data: blocked))
              .$1,
          409);
      expect((await call('GET', '/api/configuracoes', authorization: token)).$2,
          changed);
      expect(
          (await call('PUT', '/api/configuracoes',
                  authorization: token, data: config))
              .$1,
          200);
    });
    test('anexos binários e multipart: conteúdo, limite, isolamento e remoção',
        () async {
      Future<(int, dynamic)> sendFile(List<int> bytes,
          {String name = 'documento.txt', String? type}) async {
        final request =
            await client.postUrl(base.resolve('/api/tarefas/$taskId/anexos'));
        request.headers.set('authorization', 'Bearer $token');
        request.headers.set('content-type', type ?? 'application/octet-stream');
        request.headers.set('x-file-name', name);
        request.add(bytes);
        final response = await request.close();
        final text = await utf8.decoder.bind(response).join();
        return (response.statusCode, jsonDecode(text));
      }

      final content = [0, 1, 2, 127, 128, 255];
      final sent = await sendFile(content);
      expect(sent.$1, 201);
      final id = sent.$2['items'][0]['id'];
      final request =
          await client.getUrl(base.resolve('/api/tarefas/$taskId/anexos/$id'));
      request.headers.set('authorization', 'Bearer $token');
      final response = await request.close();
      expect(response.statusCode, 200);
      expect(response.headers.value('content-disposition'),
          contains('attachment'));
      expect(
          await response.fold<List<int>>([], (a, b) => a..addAll(b)), content);
      expect(
          (await call('GET', '/api/tarefas/99999/anexos/$id',
                  authorization: token))
              .$1,
          404);
      expect((await sendFile([1], name: '../fora.txt')).$1, 400);
      expect((await sendFile([])).$1, 400);
      expect((await sendFile(List.filled(10485761, 1))).$1, 413);
      final exactLimit = await sendFile(List.filled(10485760, 0));
      expect(exactLimit.$1, 201);
      expect(
          (await call('DELETE',
                  '/api/tarefas/$taskId/anexos/${exactLimit.$2['items'][0]['id']}',
                  authorization: token))
              .$1,
          204);
      final multipart =
          '--folks-boundary\r\nContent-Disposition: form-data; name="arquivos"; filename="currículo.txt"\r\nContent-Type: text/plain\r\n\r\nprimeiro\r\n'
          '--folks-boundary\r\nContent-Disposition: form-data; name="arquivos"; filename="segundo.txt"\r\nContent-Type: text/plain\r\n\r\nsegundo\r\n--folks-boundary--\r\n';
      final multiple = await sendFile(utf8.encode(multipart),
          type: 'multipart/form-data; boundary=folks-boundary');
      expect(multiple.$1, 201);
      expect(multiple.$2['items'].length, 2);
      expect(multiple.$2['items'][0]['nome'], 'currículo.txt');
      final unknownField =
          multipart.replaceFirst('name="arquivos"', 'name="outro"');
      expect(
          (await sendFile(utf8.encode(unknownField),
                  type: 'multipart/form-data; boundary=folks-boundary'))
              .$1,
          400);
      final oversizedMultipart = <int>[
        ...utf8.encode(
            '--folks-boundary\r\nContent-Disposition: form-data; name="arquivo"; filename="grande.bin"\r\n\r\n'),
        ...List.filled(10485761, 0),
        ...utf8.encode('\r\n--folks-boundary--\r\n')
      ];
      expect(
          (await sendFile(oversizedMultipart,
                  type: 'multipart/form-data; boundary=folks-boundary'))
              .$1,
          413);
      final invalidBatch = multipart.replaceFirst(
          'filename="segundo.txt"', 'filename="../segundo.txt"');
      expect(
          (await sendFile(utf8.encode(invalidBatch),
                  type: 'multipart/form-data; boundary=folks-boundary'))
              .$1,
          400);
      final truncated = multipart.replaceFirst('--folks-boundary--\r\n', '');
      expect(
          (await sendFile(utf8.encode(truncated),
                  type: 'multipart/form-data; boundary=folks-boundary'))
              .$1,
          400);
      expect(
          (await call('GET', '/api/tarefas/$taskId', authorization: token))
              .$2['anexos']
              .length,
          3);
      expect(
          (await call('DELETE', '/api/tarefas/$taskId/anexos/$id',
                  authorization: token))
              .$1,
          204);
      expect(
          (await call('GET', '/api/tarefas/$taskId/anexos/$id',
                  authorization: token))
              .$1,
          404);
    });
    test(
        'vaga com múltiplos canais, filtros, rollback e indicadores reais vazios',
        () async {
      final channel = await call('POST', '/api/divulgacoes',
          authorization: token,
          data: {'nome': 'Segundo canal', 'chave': 'segundo-canal'});
      final channels =
          (await call('GET', '/api/divulgacoes', authorization: token))
              .$2['items'];
      final me =
          (await call('GET', '/api/usuarios/me', authorization: token)).$2;
      final clients = (await call('GET', '/api/clientes', authorization: token))
          .$2['items'];
      final input = {
        'cargo': 'Analista de sistemas',
        'perfilDesejado': 'Experiência em Dart',
        'responsavelId': me['id'],
        'clienteId': clients[0]['id'],
        'prazoInicial': '2026-11-03',
        'prazoFinal': '2026-12-03',
        'canais': [channels[0]['id'], channel.$2['id']]
      };
      final created =
          await call('POST', '/api/vagas', authorization: token, data: input);
      expect(created.$1, 201);
      expect(created.$2['canais'].length, 2);
      expect(created.$2['indicadores'], {
        'inscritos': 0,
        'candidatosIdeais': 0,
        'erros': 0,
        'disponiveis': true
      });
      final listed = await call(
          'GET', '/api/vagas?canalId=${channel.$2['id']}&limit=1',
          authorization: token);
      expect(listed.$2['total'], 1);
      expect(listed.$2['items'][0]['id'], created.$2['id']);
      expect(
          (await call('POST', '/api/vagas', authorization: token, data: {
            ...input,
            'canais': [channels[0]['id'], 999999]
          }))
              .$1,
          400);
      expect(
          (await call('GET', '/api/vagas', authorization: token)).$2['total'],
          1);
      final roles =
          (await call('GET', '/api/cargos', authorization: token)).$2['items'];
      expect(
          (await call('PATCH', '/api/usuarios/${me['id']}',
                  authorization: token, data: {'cargoId': roles.last['id']}))
              .$1,
          200);
      expect(
          (await call('GET', '/api/vagas', authorization: token)).$2['items'][0]
              ['responsavelId'],
          me['id']);
    });
    test('edição de vaga valida canais, datas, avanço e rollback', () async {
      final vacancy = (await call('GET', '/api/vagas', authorization: token))
          .$2['items'][0];
      final id = vacancy['id'];
      final stages =
          (await call('GET', '/api/configuracoes', authorization: token))
              .$2['funil'] as List;
      final lastStage = stages.last['id'];
      final updated = await call('PATCH', '/api/vagas/$id',
          authorization: token,
          data: {
            'cargo': 'Cargo atualizado',
            'etapaId': lastStage,
            'canais': []
          });
      expect(updated.$1, 200);
      expect(updated.$2['cargo'], 'Cargo atualizado');
      expect(updated.$2['etapaId'], lastStage);
      expect(updated.$2['canais'], isEmpty);
      expect(
          (await call('PATCH', '/api/vagas/$id',
                  authorization: token, data: {'etapaId': stages.first['id']}))
              .$1,
          409);
      expect(
          (await call('PATCH', '/api/vagas/$id', authorization: token, data: {
            'cargo': 'Não deve gravar',
            'canais': [999999]
          }))
              .$1,
          400);
      expect(
          (await call('GET', '/api/vagas/$id', authorization: token))
              .$2['cargo'],
          'Cargo atualizado');
      expect(
          (await call('PATCH', '/api/vagas/$id',
                  authorization: token, data: {'prazoFinal': '2020-01-01'}))
              .$1,
          400);
      expect(
          (await call('PATCH', '/api/vagas/999999',
                  authorization: token, data: {'cargo': 'Inexistente'}))
              .$1,
          404);
    });

    test('candidatos: vínculos, duplicidade, indicadores e remoção', () async {
      final vacancy = (await call('GET', '/api/vagas', authorization: token))
          .$2['items'][0]['id'];
      final path = '/api/vagas/$vacancy/candidatos';
      final created = await call('POST', path, authorization: token, data: {
        'nome': 'Pessoa candidata',
        'email': 'pessoa@folks.test',
        'perfilIdeal': true
      });
      expect(created.$1, 201);
      final id = created.$2['id'];
      expect(
          (await call('POST', path,
                  authorization: token,
                  data: {'nome': 'Repetido', 'email': 'PESSOA@folks.test'}))
              .$1,
          409);
      expect(
          (await call('POST', path, authorization: token, data: {
            'nome': 'Erro sem motivo',
            'email': 'erro@folks.test',
            'status': 'erro'
          }))
              .$1,
          400);
      final error = await call('POST', path, authorization: token, data: {
        'nome': 'Cadastro incompleto',
        'email': 'erro@folks.test',
        'status': 'erro',
        'motivoErro': 'Documento inválido'
      });
      expect(error.$1, 201);
      final indicators =
          (await call('GET', '/api/vagas/$vacancy', authorization: token))
              .$2['indicadores'];
      expect(indicators, {
        'inscritos': 2,
        'candidatosIdeais': 1,
        'erros': 1,
        'disponiveis': true
      });
      expect(
          (await call('GET', '/api/vagas/999999/candidatos/$id',
                  authorization: token))
              .$1,
          404);
      expect(
          (await call('PATCH', '/api/vagas/999999/candidatos/$id',
                  authorization: token, data: {'nome': 'Outro'}))
              .$1,
          404);
      final updated = await call('PATCH', '$path/${error.$2['id']}',
          authorization: token, data: {'status': 'em_analise'});
      expect(updated.$1, 200);
      expect(updated.$2['motivoErro'], isNull);
      expect(
          (await call('GET', '$path?status=em_analise', authorization: token))
              .$2['total'],
          1);
      expect(
          (await call('GET', '$path?status=invalido', authorization: token)).$1,
          400);
      expect((await call('DELETE', '$path/$id', authorization: token)).$1, 204);
      expect((await call('GET', '$path/$id', authorization: token)).$1, 404);
      expect(
          (await call('GET', '/api/vagas/$vacancy', authorization: token))
              .$2['indicadores']['candidatosIdeais'],
          0);
    });

    test('importação CSV atômica, idempotência e autorização', () async {
      Future<(int, dynamic)> csv(String source, String key,
          {String? auth}) async {
        final request = await client.postUrl(base.resolve('/api/importacoes'));
        request.headers.set('authorization', 'Bearer ${auth ?? token}');
        request.headers.set('content-type', 'text/csv; charset=utf-8');
        request.headers.set('x-idempotency-key', key);
        request.add(utf8.encode(source));
        final response = await request.close();
        return (
          response.statusCode,
          jsonDecode(await utf8.decoder.bind(response).join())
        );
      }

      final vacancy = (await call('GET', '/api/vagas', authorization: token))
          .$2['items'][0];
      const header =
          'cargo,perfilDesejado,clienteId,responsavelId,prazoInicial,prazoFinal,canais\n';
      final row =
          '"Cargo, CSV","Perfil com ""aspas""",${vacancy['clienteId']},${vacancy['responsavelId']},2026-11-01,2026-12-01,\n';
      final before = (await call('GET', '/api/vagas', authorization: token))
          .$2['total'] as int;
      final created = await csv('$header$row', 'teste-importacao');
      expect(created.$1, 201);
      expect(created.$2['quantidade'], 1);
      final batch = created.$2['id'];
      expect((await csv('$header$row', 'teste-importacao')).$1, 200);
      expect(
          (await call('GET', '/api/vagas', authorization: token)).$2['total'],
          before + 1);
      expect(
          (await call('GET', '/api/importacoes/$batch', authorization: token))
              .$2['vagas'],
          created.$2['vagas']);
      expect(
          (await csv('$header${row.replaceFirst('Cargo, CSV', 'Outro cargo')}',
                  'teste-importacao'))
              .$1,
          409);
      final invalid =
          'Falha,Perfil,999999,${vacancy['responsavelId']},2026-11-01,2026-12-01,\n';
      expect((await csv('$header$row$invalid', 'rollback')).$1, 400);
      expect(
          (await call('GET', '/api/vagas', authorization: token)).$2['total'],
          before + 1);
      expect(
          (await db.one(
                  "SELECT count(*) AS total FROM importacoes WHERE chave = 'rollback'"))![
              'total'],
          0);
      expect((await csv('$header$row$row', 'duplicada')).$1, 400);
      final roles =
          (await call('GET', '/api/cargos', authorization: token)).$2['items'];
      final account =
          await call('POST', '/api/usuarios', authorization: token, data: {
        'nome': 'Leitura',
        'email': 'leitura@folks.test',
        'senha': 'SomenteLeitura!2026',
        'cargoId': roles.first['id']
      });
      expect(account.$1, 201);
      final login = await call('POST', '/api/auth/login', data: {
        'email': 'leitura@folks.test',
        'senha': 'SomenteLeitura!2026'
      });
      final reader = login.$2['token'] as String;
      expect((await csv('$header$row', 'proibida', auth: reader)).$1, 403);
      expect(
          (await call('PATCH', '/api/vagas/${vacancy['id']}',
                  authorization: reader, data: {'cargo': 'Proibido'}))
              .$1,
          403);
      expect(
          (await call('POST', '/api/vagas/${vacancy['id']}/candidatos',
                  authorization: reader,
                  data: {'nome': 'Proibido', 'email': 'negado@folks.test'}))
              .$1,
          403);
      expect(
          (await call('GET', '/api/importacoes/$batch', authorization: reader))
              .$1,
          403);
      final permissions =
          (await call('GET', '/api/permissoes', authorization: token))
              .$2['items'] as List;
      int permission(String key) =>
          permissions.singleWhere((p) => p['chave'] == key)['id'] as int;
      await call('PATCH', '/api/usuarios/${account.$2['id']}',
          authorization: token,
          data: {
            'permissoes': [permission('A')]
          });
      expect((await csv('$header$row', 'sem-cadastro', auth: reader)).$1, 403);
      expect(
          (await call('GET', '/api/importacoes/$batch', authorization: reader))
              .$1,
          404);
      final concurrent = await Future.wait([
        csv('$header$row', 'concorrente'),
        csv('$header$row', 'concorrente'),
      ]);
      expect(concurrent.map((r) => r.$1).toList()..sort(), [200, 201]);
      expect(concurrent[0].$2['id'], concurrent[1].$2['id']);
      expect(
          (await call('GET', '/api/vagas', authorization: token)).$2['total'],
          before + 2);
      await call('PATCH', '/api/usuarios/${account.$2['id']}',
          authorization: token, data: {'permissoes': []});
    });

    test('dashboards e entregas: conclusão idempotente e novo ciclo', () async {
      final source =
          (await call('GET', '/api/tarefas/$taskId', authorization: token)).$2;
      final created =
          await call('POST', '/api/tarefas', authorization: token, data: {
        for (final key in [
          'titulo',
          'descricao',
          'projetoId',
          'clienteId',
          'cargo',
          'responsavelId',
          'prazoInicial',
          'prazoFinal',
          'prioridadeId'
        ])
          key: source[key],
        'titulo': 'Entrega de teste',
      });
      expect(created.$1, 201);
      final id = created.$2['id'];
      final today = DateTime.now().toUtc().toIso8601String().substring(0, 10);
      final filter =
          '?dataInicial=$today&dataFinal=$today&projetoId=${source['projetoId']}';
      final before = (await call('GET', '/api/dashboard/entregas$filter',
              authorization: token))
          .$2['total'] as int;
      final config =
          (await call('GET', '/api/configuracoes', authorization: token)).$2;
      final statuses = config['kanban'] as List;
      final last = statuses.last['id'];
      final completions = await Future.wait([
        call('PATCH', '/api/tarefas/$id/status',
            authorization: token, data: {'statusId': last}),
        call('PATCH', '/api/tarefas/$id/status',
            authorization: token, data: {'statusId': last}),
      ]);
      expect(completions.map((r) => r.$1).toList(), [200, 200]);
      expect(
          (await call('GET', '/api/dashboard/entregas$filter',
                  authorization: token))
              .$2['total'],
          before + 1);
      await call('PATCH', '/api/tarefas/$id/status',
          authorization: token, data: {'statusId': statuses.first['id']});
      await call('PATCH', '/api/tarefas/$id/status',
          authorization: token, data: {'statusId': last});
      final delivery = await call('GET', '/api/dashboard/entregas$filter',
          authorization: token);
      expect(delivery.$2['total'], before + 2);
      expect(delivery.$2['porDia'], isNotEmpty);
      expect(delivery.$2['porResponsavel'], isNotEmpty);
      final activities = await call('GET',
          '/api/dashboard/atividades?dataInicial=2026-01-01&dataFinal=2026-12-31',
          authorization: token);
      expect(activities.$1, 200);
      expect(activities.$2['total'], greaterThan(0));
      expect(
          (activities.$2['porEtapa'] as List)
              .fold<int>(0, (sum, r) => sum + (r['total'] as int)),
          activities.$2['total']);
      expect(
          (await call('GET',
                  '/api/dashboard/entregas?dataInicial=2026-12-01&dataFinal=2026-11-01',
                  authorization: token))
              .$1,
          400);
      expect(
          (await call('GET', '/api/dashboard/atividades?desconhecido=1',
                  authorization: token))
              .$1,
          400);
    });

    test('edição de permissões aplica acesso sem elevar o operador', () async {
      final permissions =
          (await call('GET', '/api/permissoes', authorization: token))
              .$2['items'] as List;
      int permission(String key) =>
          permissions.singleWhere((p) => p['chave'] == key)['id'] as int;
      final roles =
          (await call('GET', '/api/cargos', authorization: token)).$2['items'];
      final operator =
          await call('POST', '/api/usuarios', authorization: token, data: {
        'nome': 'Editor restrito',
        'email': 'editor@folks.test',
        'senha': 'EditorTest!2026',
        'cargoId': roles.first['id'],
        'permissoes': [permission('F')],
      });
      final login = await call('POST', '/api/auth/login',
          data: {'email': 'editor@folks.test', 'senha': 'EditorTest!2026'});
      final editorToken = login.$2['token'] as String;
      final target = (await call('GET', '/api/usuarios?busca=leitura',
              authorization: token))
          .$2['items'][0]['id'];
      expect(
          (await call('PATCH', '/api/usuarios/$target',
                  authorization: editorToken,
                  data: {
                'cargoId': roles.last['id'],
                'permissoes': [permission('C')]
              }))
              .$1,
          403);
      expect(
          (await call('GET', '/api/usuarios?busca=leitura',
                  authorization: token))
              .$2['items'][0]['cargoId'],
          roles.first['id']);
      expect(
          (await call('PATCH', '/api/usuarios/${operator.$2['id']}',
                  authorization: editorToken,
                  data: {
                'permissoes': [permission('C')]
              }))
              .$1,
          403);
      expect(
          (await call('PATCH', '/api/usuarios/$target',
                  authorization: token,
                  data: {
                'permissoes': [permission('C')]
              }))
              .$1,
          200);
      final reader = await call('POST', '/api/auth/login', data: {
        'email': 'leitura@folks.test',
        'senha': 'SomenteLeitura!2026'
      });
      final readerToken = reader.$2['token'] as String;
      expect(
          (await call('POST', '/api/clientes',
                  authorization: readerToken,
                  data: {'empresa': 'Cliente autorizado'}))
              .$1,
          201);
      expect(
          (await call('PATCH', '/api/usuarios/$target',
                  authorization: token, data: {'permissoes': []}))
              .$1,
          200);
      expect(
          (await call('POST', '/api/clientes',
                  authorization: readerToken,
                  data: {'empresa': 'Cliente recusado'}))
              .$1,
          403);
    });

    test('todas as operações protegidas exigem autenticação', () async {
      const operations = <(String, String)>[
        ('POST', '/auth/logout'),
        ('GET', '/usuarios/me'),
        ('PATCH', '/usuarios/me'),
        ('GET', '/usuarios'),
        ('POST', '/usuarios'),
        ('PATCH', '/usuarios/1'),
        ('DELETE', '/usuarios/1'),
        ('GET', '/cargos'),
        ('GET', '/permissoes'),
        ('GET', '/projetos'),
        ('GET', '/prioridades'),
        ('GET', '/clientes'),
        ('POST', '/clientes'),
        ('GET', '/divulgacoes'),
        ('POST', '/divulgacoes'),
        ('GET', '/configuracoes'),
        ('PUT', '/configuracoes'),
        ('GET', '/tarefas'),
        ('POST', '/tarefas'),
        ('GET', '/tarefas/1'),
        ('PATCH', '/tarefas/1'),
        ('PATCH', '/tarefas/1/status'),
        ('POST', '/tarefas/1/avancos'),
        ('POST', '/tarefas/1/checklist/itens'),
        ('PATCH', '/tarefas/1/checklist/itens/1'),
        ('POST', '/tarefas/1/anexos'),
        ('GET', '/tarefas/1/anexos/1'),
        ('DELETE', '/tarefas/1/anexos/1'),
        ('GET', '/vagas'),
        ('POST', '/vagas'),
        ('GET', '/vagas/1'),
        ('PATCH', '/vagas/1'),
        ('GET', '/vagas/1/candidatos'),
        ('POST', '/vagas/1/candidatos'),
        ('GET', '/vagas/1/candidatos/1'),
        ('PATCH', '/vagas/1/candidatos/1'),
        ('DELETE', '/vagas/1/candidatos/1'),
        ('POST', '/importacoes'),
        ('GET', '/importacoes/1'),
        ('GET', '/dashboard/atividades'),
        ('GET', '/dashboard/entregas'),
      ];
      for (final (method, path) in operations) {
        expect((await call(method, '/api$path')).$1, 401,
            reason: '$method $path');
      }
    });
    test(
        'recuperação SMTP real local, uso único, expiração e revogação das sessões',
        () async {
      final smtp = await SmtpCapture.start();
      addTearDown(smtp.close);
      env.addAll({
        'SMTP_HOST': '127.0.0.1',
        'SMTP_PORT': '${smtp.port}',
        'SMTP_FROM': 'suporte@folks.test',
        'SMTP_ALLOW_INSECURE': 'true'
      });
      final recover = await call('POST', '/api/auth/recuperar-senha',
          data: {'email': env['DEV_ADMIN_EMAIL']});
      expect(recover.$1, 202);
      expect(recover.$2.toString(), isNot(contains('token')));
      expect(smtp.messages.length, 1);
      final firstToken = smtp.token;
      expect(
          (await call('POST', '/api/auth/recuperar-senha',
                  data: {'email': env['DEV_ADMIN_EMAIL']}))
              .$1,
          202);
      final secondToken = smtp.token;
      expect(secondToken, isNot(firstToken));
      final stored = await db.one('SELECT token_hash FROM recuperacoes_senha');
      expect(stored!['token_hash'], tokenHash(secondToken));
      expect(
          (await call('POST', '/api/auth/redefinir-senha',
                  data: {'token': firstToken, 'senha': 'NovaSenhaTest!2026'}))
              .$1,
          400);
      expect(
          (await call('POST', '/api/auth/redefinir-senha',
                  data: {'token': secondToken, 'senha': 'NovaSenhaTest!2026'}))
              .$1,
          204);
      expect(
          (await call('POST', '/api/auth/redefinir-senha',
                  data: {'token': secondToken, 'senha': 'NovaSenhaTest!2026'}))
              .$1,
          400);
      expect((await call('GET', '/api/usuarios/me', authorization: token)).$1,
          401);
      expect(
          (await call('POST', '/api/auth/login', data: {
            'email': env['DEV_ADMIN_EMAIL'],
            'senha': env['DEV_ADMIN_PASSWORD']
          }))
              .$1,
          401);
      env['DEV_ADMIN_PASSWORD'] = 'NovaSenhaTest!2026';
      final login = await call('POST', '/api/auth/login', data: {
        'email': env['DEV_ADMIN_EMAIL'],
        'senha': env['DEV_ADMIN_PASSWORD']
      });
      expect(login.$1, 200);
      token = login.$2['token'] as String;
      final me =
          (await call('GET', '/api/usuarios/me', authorization: token)).$2;
      await db.query(
          "INSERT INTO recuperacoes_senha VALUES (@hash, @id, now() - interval '1 second')",
          {'hash': tokenHash('expirado'), 'id': me['id']});
      expect(
          (await call('POST', '/api/auth/redefinir-senha',
                  data: {'token': 'expirado', 'senha': 'NovaSenhaTest!2026'}))
              .$1,
          400);
      final count = smtp.messages.length;
      expect(
          (await call('POST', '/api/auth/recuperar-senha',
                  data: {'email': 'inexistente@folks.test'}))
              .$1,
          202);
      expect(smtp.messages.length, count);
      expect(
          (await call('POST', '/api/auth/recuperar-senha',
                  data: {'email': env['DEV_ADMIN_EMAIL']}))
              .$1,
          202);
      expect(
          (await call('POST', '/api/auth/recuperar-senha',
                  data: {'email': env['DEV_ADMIN_EMAIL']}))
              .$1,
          429);
    });
  },
      skip: !enabled
          ? 'Requer RUN_DB_TESTS=true e PostgreSQL isolado *_test.'
          : false);
}
