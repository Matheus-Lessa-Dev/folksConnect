import 'dart:io';
import 'package:postgres/postgres.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../config/app_config.dart';
import '../http.dart';

class ApiMiddleware {
  final Router router;
  final AppConfig config;
  ApiMiddleware(this.router, this.config);
  Future<Response> call(Request request) async {
    final origin = request.headers['origin'];
    final allowed = config.corsOrigins;
    final cors = <String, String>{
      'x-content-type-options': 'nosniff',
      if (origin != null && allowed.contains(origin))
        'access-control-allow-origin': origin,
      'vary': 'Origin',
      'access-control-allow-methods': 'GET, POST, PATCH, PUT, DELETE, OPTIONS',
      'access-control-allow-headers':
          'Authorization, Content-Type, X-File-Name, X-Idempotency-Key',
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
