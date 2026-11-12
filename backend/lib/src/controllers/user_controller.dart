import 'package:shelf/shelf.dart';
import '../dto/input.dart';
import '../http.dart';
import '../security/identity.dart';
import '../services/users_service.dart';

class UserController {
  final UserService service;
  UserController(this.service);
  Future<Response> list(Request r, Identity user) async =>
      json(await service.list(QueryInput(r.url.queryParameters), user));
  Future<Response> create(Request r, Identity user) async {
    user.require('E');
    return json(await service.create(await readJson(r), user), status: 201);
  }

  Future<Response> update(Request r, Identity user, String id) async {
    user.require('F');
    return json(await service.update(await readJson(r), user, routeId(id)));
  }

  Future<Response> deactivate(Request r, Identity user, String id) async {
    await service.deactivate(user, routeId(id));
    return Response(204);
  }
}
