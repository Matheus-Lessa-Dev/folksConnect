import 'dart:convert';
import 'dart:io';


import 'package:bcrypt/bcrypt.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';

// Função auxiliar para respostas JSON
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

Future<void> main() async {
  final port = int.tryParse(Platform.environment['PORT'] ?? '') ?? 8080;

  final router = Router()
    // Health Check
    ..get('/api/health', (Request request) {
      return _jsonResponse({
        'status': 'ok',
        'service': 'folks-connect-backend'
      });
    })
    // Endpoint de Login (POST /api/auth/login)
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

        // --- SIMULAÇÃO / CONSULTA AO BANCO POSTGRESQL ---
        // Na integração real com PostgreSQL:
        // final usuario = await db.query('SELECT * FROM usuarios WHERE email = @email', substitutionValues: {'email': email});
        // if (usuario.isEmpty) return _jsonResponse({'erro': 'Credenciais inválidas'}, statusCode: 401);
        // final hashArmazenado = usuario.first['senha_hash'];
        // final senhaValida = Bcrypt.checkpw(senha, hashArmazenado);

        // Exemplo temporário para validar login:
        if (email.toLowerCase() == 'joabe@gmail.com' && senha == '12345') {
          return _jsonResponse({
            'token': 'jwt_token_exemplo_folks_connect_123456',
            'usuario': {
              'id': 1,
              'email': email,
              'nome': 'Joabe',
            },
          });
        }

        return _jsonResponse(
          {'erro': 'E-mail ou senha incorretos.'},
          statusCode: 401,
        );
      } catch (e) {
        return _jsonResponse({'erro': 'Erro no servidor: $e'}, statusCode: 500);
      }
    })

    // Endpoint de Tarefas (GET /api/tarefas)
    ..get('/api/tarefas', (Request request) async {
      try {
        // Verificar token enviado no cabeçalho Authorization: Bearer <token>
        final authHeader = request.headers['authorization'];
        if (authHeader == null || !authHeader.startsWith('Bearer ')) {
          return _jsonResponse({'erro': 'Não autorizado'}, statusCode: 401);
        }

        // --- CONSULTA AO BANCO POSTGRESQL ---
        // Exemplo de query real:
        // final result = await db.query('''
        //   SELECT t.id_tarefa, u.email, c.nome as cargo, p.nome as projeto
        //   FROM tarefas t
        //   JOIN usuarios u ON t.id_usuario = u.id_usuario
        //   JOIN cargos c ON t.id_cargo = c.id_cargo
        //   JOIN projetos p ON t.id_projeto = p.id_projeto
        // ''');

        // Resposta JSON com a lista de tarefas:
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
    });

  final handler = Pipeline()
      .addMiddleware(logRequests())
      .addMiddleware(_corsMiddleware())
      .addHandler(router.call);

  final server = await shelf_io.serve(handler, InternetAddress.anyIPv4, port);
  print('Backend ouvindo em http://${server.address.host}:${server.port}');
}

// Middleware para tratar Preflight OPTIONS de navegadores
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