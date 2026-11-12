import 'dart:convert';
import 'package:shelf/shelf.dart';
import '../http.dart';
import '../security/identity.dart';
import '../services/imports_service.dart';

class ImportController {
  final ImportService service;
  ImportController(this.service);
  Future<Response> get(Request r, Identity user, String id) async =>
      json(await service.get(routeId(id), user));
  Future<Response> create(Request r, Identity user) async {
    user.require('A');
    user.require('C');
    final type =
        (r.headers['content-type'] ?? '').split(';').first.trim().toLowerCase();
    if (type != 'text/csv') {
      throw ApiError(
          415, 'tipo_invalido', 'Envie CSV UTF-8 com Content-Type: text/csv.');
    }
    String source;
    try {
      source = utf8.decode(await readLimited(r, 2 * 1024 * 1024));
    } on FormatException {
      invalid('O CSV deve usar UTF-8.');
    }
    final (result, created) = await service.create(
        source, r.headers['x-idempotency-key'] ?? '', user);
    return json(result, status: created ? 201 : 200);
  }
}
