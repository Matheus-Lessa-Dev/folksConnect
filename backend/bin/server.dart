import 'dart:convert';
import 'dart:io';

import 'package:bcrypt/bcrypt.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';

// Função auxiliar para respostas JSON com suporte a CORS
Response _jsonResponse(Object data, {int statusCode = 200}) {
  return Response(
    statusCode,
    body: jsonEncode(data),
    headers: {
      'content-type': 'application/json; charset=utf-8',
      'access-control-allow-origin': '*',
      'access-control-allow-headers': 'Origin, Content-Type, Authorization',
      'access-control-allow-methods': 'GET, POST, PATCH, PUT, DELETE, OPTIONS',
    },
  );
}

// Hash Bcrypt gerado para a conta de demonstração (senha: 12345)
final _demoUserHash = BCrypt.hashpw('12345', BCrypt.gensalt());

Future<void> main() async {
  final port = int.tryParse(Platform.environment['PORT'] ?? '') ?? 8080;

  final router = Router()
    // 1. Health Check
    ..get('/api/health', (Request request) {
      return _jsonResponse({
        'status': 'ok',
        'service': 'folks-connect-backend',
      });
    })

    // 2. Endpoint de Login com validação Bcrypt (POST /api/auth/login)
    ..post('/api/auth/login', (Request request) async {
      try {
        final bodyText = await request.readAsString();
        final payload = jsonDecode(bodyText) as Map<String, dynamic>;

        final email = payload['email'] as String?;
        final senha = payload['senha'] as String?;

        if (email == null || senha == null) {
          return _jsonResponse(
            {'erro': 'E-mail e senha são obrigatórios.'},
            statusCode: 400,
          );
        }

        // Validação com Bcrypt (compara a senha recebida com o Hash + Salt armazenado)
        if (email.toLowerCase() == 'joabe@gmail.com') {
          final bool senhaValida = BCrypt.checkpw(senha, _demoUserHash);
          if (senhaValida) {
            return _jsonResponse({
              'token': 'jwt_token_exemplo_folks_connect_123456',
              'usuario': {
                'id': 1,
                'email': email,
                'nome': 'Joabe',
              },
            });
          }
        }

        return _jsonResponse(
          {'erro': 'E-mail ou senha incorretos.'},
          statusCode: 401,
        );
      } catch (e) {
        return _jsonResponse({'erro': 'Erro no servidor: $e'}, statusCode: 500);
      }
    })

    // 3. Endpoint de Tarefas (GET /api/tarefas)
    ..get('/api/tarefas', (Request request) async {
      try {
        final authHeader = request.headers['authorization'];
        if (authHeader == null || !authHeader.startsWith('Bearer ')) {
          return _jsonResponse({'erro': 'Não autorizado'}, statusCode: 401);
        }

        final tarefas = [
          {
            'id': 'task-1',
            'titulo': 'Triagem — Analista Financeiro Jr.',
            'projeto': 'Recrutamento',
            'empresa': 'Faculdade Donaduzzi',
            'responsavel': 'Joabe — Analista',
            'prioridade': 'alta',
            'status': 'a_fazer',
          },
          {
            'id': 'task-2',
            'titulo': 'Consultoria — Acompanhamento da equipe',
            'projeto': 'Consultoria',
            'empresa': 'Spotty',
            'responsavel': 'Eduarda — Analista',
            'prioridade': 'media',
            'status': 'em_andamento',
          },
        ];

        return _jsonResponse(tarefas);
      } catch (e) {
        return _jsonResponse({'erro': 'Erro ao listar tarefas'}, statusCode: 500);
      }
    })

    // 4. Endpoint de Vagas (GET /api/vagas)
    ..get('/api/vagas', (Request request) async {
      try {
        final authHeader = request.headers['authorization'];
        if (authHeader == null || !authHeader.startsWith('Bearer ')) {
          return _jsonResponse({'erro': 'Não autorizado'}, statusCode: 401);
        }

        final vagas = [
          {
            'id': 'vacancy-1',
            'cargo': 'Analista Financeiro Jr.',
            'empresa': 'Faculdade Donaduzzi',
            'perfil': 'Análise financeira e indicadores',
            'responsavel': 'Eduarda — Analista',
          },
          {
            'id': 'vacancy-2',
            'cargo': 'Desenvolvedor Sênior',
            'empresa': 'Meta',
            'perfil': 'Desenvolvimento e manutenção de sistemas',
            'responsavel': 'Joabe — Analista',
          },
        ];

        return _jsonResponse(vagas);
      } catch (e) {
        return _jsonResponse({'erro': 'Erro ao listar vagas'}, statusCode: 500);
      }
    })

    // 5. Endpoint de Usuários (GET /api/usuarios)
    ..get('/api/usuarios', (Request request) async {
      try {
        final authHeader = request.headers['authorization'];
        if (authHeader == null || !authHeader.startsWith('Bearer ')) {
          return _jsonResponse({'erro': 'Não autorizado'}, statusCode: 401);
        }

        final usuarios = [
          {'id': 1, 'nome': 'Ana Munaro', 'email': 'ana@example.com', 'cargo': 'Assistente'},
          {'id': 2, 'nome': 'Matheus Lessa', 'email': 'matheus@example.com', 'cargo': 'Gerente'},
          {'id': 3, 'nome': 'Eduarda Oliveira', 'email': 'eduarda@example.com', 'cargo': 'Analista'},
          {'id': 4, 'nome': 'João Francisco', 'email': 'joao@example.com', 'cargo': 'Diretor'},
        ];

        return _jsonResponse(usuarios);
      } catch (e) {
        return _jsonResponse({'erro': 'Erro ao listar usuários'}, statusCode: 500);
      }
    });

  final handler = Pipeline()
      .addMiddleware(logRequests())
      .addMiddleware(_corsMiddleware())
      .addHandler(router.call);

  final server = await shelf_io.serve(handler, InternetAddress.anyIPv4, port);
  print('Backend ouvindo em http://${server.address.host}:${server.port}');
}

// Middleware para tratar Preflight OPTIONS de navegadores (CORS)
Middleware _corsMiddleware() {
  return (Handler innerHandler) {
    return (Request request) async {
      if (request.method == 'OPTIONS') {
        return Response.ok('', headers: {
          'access-control-allow-origin': '*',
          'access-control-allow-headers': 'Origin, Content-Type, Authorization',
          'access-control-allow-methods': 'GET, POST, PATCH, PUT, DELETE, OPTIONS',
        });
      }
      return await innerHandler(request);
    };
  };
}
