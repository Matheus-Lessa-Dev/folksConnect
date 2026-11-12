import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

/// Sonda HTTP para o backend compilado do perfil test. Não acessa o banco diretamente.
Future<void> main(List<String> args) async {
  if (args.length != 1 || !{'prepare', 'verify'}.contains(args.single)) {
    throw ArgumentError('Use prepare ou verify.');
  }
  final root = Uri.parse(
      Platform.environment['API_URL'] ?? 'http://backend-e2e:8080/api');
  final stateFile = File('/verification/state.json');
  final client = HttpClient()..connectionTimeout = const Duration(seconds: 10);
  var token = '';
  Future<dynamic> call(String method, String path,
      {Object? data, String? csv, String? importKey, int status = 200}) async {
    final request = await client.openUrl(method, Uri.parse('$root$path'));
    if (token.isNotEmpty) request.headers.set('authorization', 'Bearer $token');
    if (csv != null) {
      request.headers.set('content-type', 'text/csv; charset=utf-8');
      request.headers.set('x-idempotency-key', importKey!);
      request.add(utf8.encode(csv));
    } else if (data != null) {
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode(data));
    }
    final response = await request.close();
    final text = await utf8.decoder.bind(response).join();
    if (response.statusCode != status) {
      throw StateError(
          '$method $path: esperado $status, recebido ${response.statusCode}: $text');
    }
    return text.isEmpty ? null : jsonDecode(text);
  }

  Future<int> upload(int id, List<int> bytes, String name) async {
    final request = await client.postUrl(Uri.parse('$root/tarefas/$id/anexos'));
    request.headers.set('authorization', 'Bearer $token');
    request.headers.set('x-file-name', name);
    request.headers.contentType = ContentType.binary;
    request.add(bytes);
    final response = await request.close();
    final text = await utf8.decoder.bind(response).join();
    if (response.statusCode != 201) {
      throw StateError('Upload falhou: ${response.statusCode}');
    }
    return jsonDecode(text)['items'][0]['id'] as int;
  }

  void equal(Object? actual, Object? expected, String name) {
    if (jsonEncode(actual) != jsonEncode(expected)) {
      throw StateError('Persistência divergente: $name');
    }
  }

  try {
    var ready = false;
    for (var attempt = 0; attempt < 30; attempt++) {
      try {
        await call('GET', '/health');
        ready = true;
        break;
      } on SocketException {
        await Future<void>.delayed(const Duration(milliseconds: 500));
      } on HttpException {
        await Future<void>.delayed(const Duration(milliseconds: 500));
      }
    }
    if (!ready) {
      throw StateError('Backend não ficou disponível após o início/reinício.');
    }
    if (args.single == 'prepare') {
      final login = await call('POST', '/auth/login',
          data: {'email': 'admin@folks.e2e', 'senha': 'FolksE2e!2026'});
      token = login['token'] as String;
      final suffix = DateTime.now().microsecondsSinceEpoch.toString();
      final roles = (await call('GET', '/cargos?limit=100'))['items'];
      final projects = (await call('GET', '/projetos?limit=100'))['items'];
      final priorities = (await call('GET', '/prioridades?limit=100'))['items'];
      final user = await call('POST', '/usuarios', status: 201, data: {
        'nome': 'Verificação persistência $suffix',
        'email': 'probe$suffix@folks.test',
        'senha': 'ProbeUser!2026',
        'cargoId': roles.last['id'],
        'permissoes': []
      });
      final customer = await call('POST', '/clientes', status: 201, data: {
        'empresa': 'Verificação persistência $suffix',
        'email': 'probe@folks.test'
      });
      final channel = await call('POST', '/divulgacoes',
          status: 201,
          data: {'nome': 'Verificação $suffix', 'chave': 'probe-$suffix'});
      final configuration = await call('GET', '/configuracoes');
      final nextOrder = (configuration['checklist'] as List)
              .map((item) => item['ordem'] as int)
              .reduce((a, b) => a > b ? a : b) +
          1;
      configuration['checklist'].add(
          {'nome': 'Verificação persistência $suffix', 'ordem': nextOrder});
      final savedConfig =
          await call('PUT', '/configuracoes', data: configuration);
      final task = await call('POST', '/tarefas', status: 201, data: {
        'titulo': 'Verificação persistência $suffix',
        'descricao': 'Fluxo HTTP antes e depois do reinício',
        'cargo': 'Analista',
        'projetoId': projects.first['id'],
        'clienteId': customer['id'],
        'responsavelId': user['id'],
        'prioridadeId': priorities.first['id'],
        'prazoInicial': '2026-11-03',
        'prazoFinal': '2026-12-03'
      });
      final taskId = task['id'] as int;
      await call('PATCH', '/tarefas/$taskId',
          data: {'descricao': 'Descrição editada e persistida'});
      await call('PATCH', '/tarefas/$taskId/status',
          data: {'statusId': savedConfig['kanban'][1]['id']});
      await call('POST', '/tarefas/$taskId/avancos', status: 201, data: {
        'etapaId': savedConfig['funil'][1]['id'],
        'responsavelId': user['id']
      });
      final item = await call('POST', '/tarefas/$taskId/checklist/itens',
          status: 201, data: {'nome': 'Item persistido'});
      await call('PATCH', '/tarefas/$taskId/checklist/itens/${item['id']}',
          data: {'concluido': true});
      final bytes =
          utf8.encode('Conteúdo binário de verificação $suffix\u0000\u00ff');
      final attachment = await upload(taskId, bytes, 'persistencia.bin');
      final deleted = await upload(taskId, [1, 2, 3], 'removido.bin');
      await call('DELETE', '/tarefas/$taskId/anexos/$deleted', status: 204);
      final vacancy = await call('POST', '/vagas', status: 201, data: {
        'cargo': 'Verificação persistência',
        'perfilDesejado': 'Dados exclusivos do teste de persistência',
        'clienteId': customer['id'],
        'responsavelId': user['id'],
        'prazoInicial': '2026-11-03',
        'prazoFinal': '2026-12-03',
        'canais': [channel['id']]
      });
      final candidate = await call('POST', '/vagas/${vacancy['id']}/candidatos',
          status: 201,
          data: {
            'nome': 'Candidato persistido',
            'email': 'probe$suffix@example.com',
            'perfilIdeal': true
          });
      await call('PATCH', '/vagas/${vacancy['id']}', data: {
        'cargo': 'Cargo editado persistido',
        'etapaId': savedConfig['funil'].last['id']
      });
      await call('PATCH', '/tarefas/$taskId/status',
          data: {'statusId': savedConfig['kanban'].last['id']});
      final today = DateTime.now().toUtc().toIso8601String().substring(0, 10);
      final deliveryPath =
          '/dashboard/entregas?dataInicial=$today&dataFinal=$today&responsavelId=${user['id']}';
      final csv =
          'cargo,perfilDesejado,clienteId,responsavelId,prazoInicial,prazoFinal,canais\nImportada,Perfil de teste,${customer['id']},${user['id']},2026-11-03,2026-12-03,${channel['id']}\n';
      final batch = await call('POST', '/importacoes',
          status: 201, csv: csv, importKey: 'probe-$suffix');
      final state = {
        'token': token,
        'perfil': await call('GET', '/usuarios/me'),
        'configuracoes': savedConfig,
        'usuario': user,
        'cliente': customer,
        'canal': channel,
        'vaga': await call('GET', '/vagas/${vacancy['id']}'),
        'candidato': candidate,
        'importacao': batch,
        'csv': csv,
        'chaveImportacao': 'probe-$suffix',
        'vagaImportada': await call('GET', '/vagas/${batch['vagas'][0]}'),
        'dashboardPath': deliveryPath,
        'entregas': await call('GET', deliveryPath),
        'tarefa': await call('GET', '/tarefas/$taskId'),
        'anexoId': attachment,
        'removidoId': deleted,
        'anexoHash': sha256.convert(bytes).toString()
      };
      stateFile.parent.createSync(recursive: true);
      stateFile.writeAsStringSync(jsonEncode(state));
      stdout.writeln(
          'PREPARE OK: sessão, cadastros, tarefa, anexos, vaga editada, candidato, importação e entrega gravados por HTTP.');
      stdout.writeln(
          'Reinicie backend-e2e e execute verify. O token está somente no volume de testes.');
    } else {
      final state = jsonDecode(stateFile.readAsStringSync());
      token = state['token'] as String;
      equal(await call('GET', '/usuarios/me'), state['perfil'],
          'sessão e perfil');
      equal(await call('GET', '/configuracoes'), state['configuracoes'],
          'configurações');
      final taskId = state['tarefa']['id'];
      equal(await call('GET', '/tarefas/$taskId'), state['tarefa'],
          'tarefa, avanço, checklist e metadados');
      final customers = (await call('GET',
              '/clientes?busca=${Uri.encodeComponent(state['cliente']['empresa'] as String)}'))[
          'items'];
      equal(customers.single, state['cliente'], 'cliente');
      final channels = (await call('GET',
              '/divulgacoes?busca=${Uri.encodeComponent(state['canal']['nome'] as String)}'))[
          'items'];
      equal(channels.single, state['canal'], 'canal');
      final users = (await call('GET',
              '/usuarios?busca=${Uri.encodeComponent(state['usuario']['email'] as String)}'))[
          'items'];
      equal(users.single['id'], state['usuario']['id'], 'usuário');
      final vacancies = (await call(
          'GET', '/vagas?clienteId=${state['cliente']['id']}'))['items'];
      equal(vacancies.singleWhere((v) => v['id'] == state['vaga']['id']),
          state['vaga'], 'vaga editada, canais e indicadores');
      equal(
          await call('GET',
              '/vagas/${state['vaga']['id']}/candidatos/${state['candidato']['id']}'),
          state['candidato'],
          'candidato');
      equal(await call('GET', '/importacoes/${state['importacao']['id']}'),
          state['importacao'], 'importação');
      equal(
          await call('POST', '/importacoes',
              csv: state['csv'] as String,
              importKey: state['chaveImportacao'] as String),
          state['importacao'],
          'repetição idempotente após reinício');
      equal(await call('GET', '/vagas/${state['vagaImportada']['id']}'),
          state['vagaImportada'], 'vaga importada');
      equal(await call('GET', state['dashboardPath'] as String),
          state['entregas'], 'eventos de entrega');
      final request = await client.getUrl(
          Uri.parse('$root/tarefas/$taskId/anexos/${state['anexoId']}'));
      request.headers.set('authorization', 'Bearer $token');
      final response = await request.close();
      if (response.statusCode != 200) {
        throw StateError('Download após reinício falhou.');
      }
      final digest = await sha256.bind(response).first;
      equal(digest.toString(), state['anexoHash'], 'bytes do anexo (SHA-256)');
      await call('GET', '/tarefas/$taskId/anexos/${state['removidoId']}',
          status: 404);
      stdout.writeln(
          'VERIFY OK: sessão, cadastros, tarefa, vaga editada, indicadores, candidato, importação idempotente e entrega preservados.');
      stdout.writeln(
          'VERIFY OK: SHA-256 do download idêntico; anexo removido continua ausente.');
    }
  } finally {
    client.close(force: true);
  }
}
