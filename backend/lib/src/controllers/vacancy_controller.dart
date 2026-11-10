import 'package:shelf/shelf.dart';
import '../dto/input.dart';
import '../http.dart';
import '../security/identity.dart';
import '../services/vacancies_service.dart';

class VacancyController {
  final VacancyService service;
  VacancyController(this.service);
  Future<Response> list(Request r, Identity user) async =>
      json(await service.list(QueryInput(r.url.queryParameters)));
  Future<Response> get(Request r, Identity user, String id) async =>
      json(await service.get(routeId(id)));
  Future<Response> update(Request r, Identity user, String id) async {
    user.require('D');
    return json(await service.update(routeId(id), await readJson(r), user));
  }

  Future<Response> create(Request r, Identity user) async {
    user.require('C');
    return json(await service.create(await readJson(r), user), status: 201);
  }
}
