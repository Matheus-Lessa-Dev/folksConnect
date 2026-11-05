import 'dart:io';

import 'package:postgres/postgres.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import 'auth.dart';
import 'attachments.dart';
import 'catalogs.dart';
import 'database.dart';
import 'http.dart';
import 'security.dart';
import 'settings.dart';
import 'tasks.dart';
import 'vacancies.dart';

class Application {
  final Database db;
  final Map<String, String> env;
  late final Auth auth = Auth(db, env);
  late final Catalogs catalogs = Catalogs(db);
  late final Users users = Users(db, auth);
  late final Settings settings = Settings(db);
  late final Tasks tasks = Tasks(db);
  late final Attachments attachments = Attachments(db);
  late final Vacancies vacancies = Vacancies(db);
  final router = Router();
  Application(this.db, this.env) {
    router.get('/api', (Request r) => json({'message': 'Folks Connect API'}));
    router.get('/api/health', (Request r) async {
      await db.one('SELECT 1');
      return json({'status': 'ok', 'service': 'folks-connect-backend'});
    });
    router.post('/api/auth/login', auth.login);
    router.post('/api/auth/recuperar-senha', auth.recover);
    router.post('/api/auth/redefinir-senha', auth.reset);
    router.post(
        '/api/auth/logout', (Request r) => protected(r, (u) => auth.logout(r)));
    router.get(
        '/api/usuarios/me',
        (Request r) =>
            protected(r, (u) async => json(await auth.profile(u.id))));
    router.patch('/api/usuarios/me',
        (Request r) => protected(r, (u) => auth.updateProfile(r, u)));
    for (final name in [
      'cargos',
      'projetos',
      'prioridades',
      'permissoes',
      'clientes',
      'divulgacoes'
    ]) {
      router.get('/api/$name',
          (Request r) => protected(r, (u) => catalogs.list(r, name)));
    }
    router.post('/api/clientes',
        (Request r) => protected(r, (u) => catalogs.createClient(r, u)));
    router.post('/api/divulgacoes',
        (Request r) => protected(r, (u) => catalogs.createChannel(r, u)));
    router.get(
        '/api/usuarios', (Request r) => protected(r, (u) => users.list(r, u)));
    router.post('/api/usuarios',
        (Request r) => protected(r, (u) => users.create(r, u)));
    router.patch(
        '/api/usuarios/<id>',
        (Request r, String id) =>
            protected(r, (u) => users.update(r, u, routeId(id))));
    router.delete(
        '/api/usuarios/<id>',
        (Request r, String id) =>
            protected(r, (u) => users.deactivate(u, routeId(id))));
    router.get('/api/configuracoes',
        (Request r) => protected(r, (u) => settings.get()));
    router.put('/api/configuracoes',
        (Request r) => protected(r, (u) => settings.put(r, u)));
    router.get(
        '/api/tarefas', (Request r) => protected(r, (u) => tasks.list(r)));
    router.post(
        '/api/tarefas', (Request r) => protected(r, (u) => tasks.create(r, u)));
    router.get('/api/tarefas/<id>',
        (Request r, String id) => protected(r, (u) => tasks.get(routeId(id))));
    router.patch(
        '/api/tarefas/<id>',
        (Request r, String id) =>
            protected(r, (u) => tasks.update(r, u, routeId(id))));
    router.patch(
        '/api/tarefas/<id>/status',
        (Request r, String id) =>
            protected(r, (u) => tasks.move(r, u, routeId(id))));
    router.post(
        '/api/tarefas/<id>/avancos',
        (Request r, String id) =>
            protected(r, (u) => tasks.advance(r, u, routeId(id))));
    router.post(
        '/api/tarefas/<id>/checklist/itens',
        (Request r, String id) =>
            protected(r, (u) => tasks.addItem(r, u, routeId(id))));
    router.patch(
        '/api/tarefas/<id>/checklist/itens/<itemId>',
        (Request r, String id, String itemId) => protected(
            r, (u) => tasks.checkItem(r, u, routeId(id), routeId(itemId))));
    router.post(
        '/api/tarefas/<id>/anexos',
        (Request r, String id) =>
            protected(r, (u) => attachments.create(r, u, routeId(id))));
    router.get(
        '/api/tarefas/<id>/anexos/<anexoId>',
        (Request r, String id, String anexoId) => protected(
            r, (u) => attachments.download(routeId(id), routeId(anexoId))));
    router.delete(
        '/api/tarefas/<id>/anexos/<anexoId>',
        (Request r, String id, String anexoId) => protected(
            r, (u) => attachments.delete(u, routeId(id), routeId(anexoId))));
    router.get(
        '/api/vagas', (Request r) => protected(r, (u) => vacancies.list(r)));
    router.post('/api/vagas',
        (Request r) => protected(r, (u) => vacancies.create(r, u)));
  }

  Future<Response> protected(
          Request request, Future<Response> Function(Identity) action) async =>
      action(await auth.authenticate(request));

  Future<Response> call(Request request) async {
    final origin = request.headers['origin'];
    final allowed = (env['CORS_ORIGINS'] ?? 'http://localhost:8080')
        .split(',')
        .map((s) => s.trim())
        .toSet();
    final cors = <String, String>{
      'x-content-type-options': 'nosniff',
      if (origin != null && allowed.contains(origin))
        'access-control-allow-origin': origin,
      'vary': 'Origin',
      'access-control-allow-methods': 'GET, POST, PATCH, PUT, DELETE, OPTIONS',
      'access-control-allow-headers':
          'Authorization, Content-Type, X-File-Name',
      'access-control-expose-headers': 'Content-Disposition',
    };
    if (request.method == 'OPTIONS') return Response(204, headers: cors);
    Response response;
    try {
      response = await router.call(request);
      if (response.statusCode == 404) {
        response = json({
          'erro': {
            'codigo': 'nao_encontrado',
            'mensagem': 'Rota ou registro não encontrado.'
          }
        }, status: 404);
      }
    } on ApiError catch (e) {
      response = json({
        'erro': {'codigo': e.code, 'mensagem': e.message}
      }, status: e.status);
    } on ServerException catch (e) {
      final status = switch (e.code) {
        '23505' || '23503' => 409,
        '23514' || '22001' || '22P02' => 400,
        _ => 500
      };
      if (status == 500) stderr.writeln('Falha PostgreSQL: ${e.code}');
      response = json({
        'erro': {
          'codigo': status == 409
              ? 'conflito'
              : status == 400
                  ? 'validacao'
                  : 'erro_interno',
          'mensagem': switch (e.code) {
            '23505' => 'Já existe um registro com estes dados únicos.',
            '23503' => 'Referência inexistente ou registro ainda em uso.',
            '23514' || '22001' || '22P02' => 'Dados inválidos.',
            _ => 'Não foi possível concluir a operação.',
          }
        }
      }, status: status);
    } on PgException {
      response = json({
        'erro': {
          'codigo': 'banco_indisponivel',
          'mensagem': 'Banco de dados temporariamente indisponível.'
        }
      }, status: 503);
    } catch (e, stack) {
      stderr.writeln('Falha interna: ${e.runtimeType}\n$stack');
      response = json({
        'erro': {
          'codigo': 'erro_interno',
          'mensagem': 'Não foi possível concluir a operação.'
        }
      }, status: 500);
    }
    return response.change(headers: cors);
  }
}
