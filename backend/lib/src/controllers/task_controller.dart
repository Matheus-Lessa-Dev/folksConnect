import 'package:shelf/shelf.dart';
import '../dto/input.dart';
import '../http.dart';
import '../security/identity.dart';
import '../services/tasks_service.dart';

class TaskController {
  final TaskService service;
  TaskController(this.service);
  Future<Response> list(Request r, Identity user) async =>
      json(await service.list(QueryInput(r.url.queryParameters)));
  Future<Response> get(Request r, Identity user, String id) async =>
      json(await service.get(routeId(id)));
  Future<Response> create(Request r, Identity user) async {
    user.require('B');
    return json(await service.create(await readJson(r), user), status: 201);
  }

  Future<Response> update(Request r, Identity user, String id) async {
    user.require('B');
    return json(await service.update(await readJson(r), user, routeId(id)));
  }

  Future<Response> move(Request r, Identity user, String id) async {
    user.require('B');
    return json(await service.move(await readJson(r), user, routeId(id)));
  }

  Future<Response> advance(Request r, Identity user, String id) async {
    user.require('B');
    return json(await service.advance(await readJson(r), user, routeId(id)),
        status: 201);
  }

  Future<Response> addItem(Request r, Identity user, String id) async {
    user.require('B');
    return json(await service.addItem(await readJson(r), user, routeId(id)),
        status: 201);
  }

  Future<Response> checkItem(
      Request r, Identity user, String id, String item) async {
    user.require('B');
    return json(await service.checkItem(
        await readJson(r), user, routeId(id), routeId(item)));
  }
}
