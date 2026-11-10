import 'package:shelf/shelf.dart';
import '../http.dart';
import '../security/identity.dart';
import '../services/auth_service.dart';
import 'bearer.dart';

class AuthController {
  final AuthService service;
  AuthController(this.service);
  Future<Response> login(Request r) async =>
      json(await service.login(await readJson(r)));
  Future<Response> recover(Request r) async =>
      json(await service.recover(await readJson(r)), status: 202);
  Future<Response> reset(Request r) async {
    await service.reset(await readJson(r));
    return Response(204);
  }

  Future<Response> logout(Request r, Identity user) async {
    await service.logout(bearer(r));
    return Response(204);
  }

  Future<Response> profile(Request r, Identity user) async =>
      json(await service.profile(user.id));
  Future<Response> updateProfile(Request r, Identity user) async =>
      json(await service.updateProfile(await readJson(r), user));
}
