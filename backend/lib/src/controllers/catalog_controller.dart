import 'package:shelf/shelf.dart';
import '../dto/input.dart';
import '../http.dart';
import '../security/identity.dart';
import '../services/catalogs_service.dart';

class CatalogController {
  final CatalogService service;
  CatalogController(this.service);
  Future<Response> list(Request r, Identity user, String name) async =>
      json(await service.list(QueryInput(r.url.queryParameters), name));
  Future<Response> createClient(Request r, Identity user) async {
    user.require('C');
    return json(await service.createClient(await readJson(r), user),
        status: 201);
  }

  Future<Response> createChannel(Request r, Identity user) async {
    user.require('C');
    return json(await service.createChannel(await readJson(r), user),
        status: 201);
  }
}
