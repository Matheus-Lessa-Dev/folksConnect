import 'package:shelf/shelf.dart';
import '../dto/input.dart';
import '../http.dart';
import '../security/identity.dart';
import '../services/candidates_service.dart';

class CandidateController {
  final CandidateService service;
  CandidateController(this.service);
  Future<Response> list(Request r, Identity user, String vacancy) async => json(
      await service.list(routeId(vacancy), QueryInput(r.url.queryParameters)));
  Future<Response> get(
          Request r, Identity user, String vacancy, String id) async =>
      json(await service.get(routeId(vacancy), routeId(id)));
  Future<Response> create(Request r, Identity user, String vacancy) async {
    user.require('C');
    return json(await service.create(routeId(vacancy), await readJson(r), user),
        status: 201);
  }

  Future<Response> update(
      Request r, Identity user, String vacancy, String id) async {
    user.require('D');
    return json(await service.update(
        routeId(vacancy), routeId(id), await readJson(r), user));
  }

  Future<Response> delete(
      Request r, Identity user, String vacancy, String id) async {
    await service.delete(routeId(vacancy), routeId(id), user);
    return Response(204);
  }
}
