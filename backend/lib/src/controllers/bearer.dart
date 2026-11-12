import 'package:shelf/shelf.dart';
import '../exceptions/api_error.dart';

String bearer(Request request) {
  final header = request.headers['authorization'] ?? '';
  if (!header.startsWith('Bearer ') || header.length > 200) {
    throw ApiError(401, 'nao_autenticado', 'Informe um token Bearer válido.');
  }
  return header.substring(7);
}
