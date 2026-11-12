import 'package:shelf/shelf.dart';
import '../controllers/bearer.dart';
import '../security/identity.dart';
import '../services/auth_service.dart';

class RouteGuard {
  final AuthService auth;
  RouteGuard(this.auth);
  Future<Response> call(
          Request request, Future<Response> Function(Identity) action) async =>
      action(await auth.authenticate(bearer(request)));
}
