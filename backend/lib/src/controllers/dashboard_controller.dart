import 'package:shelf/shelf.dart';
import '../dto/input.dart';
import '../http.dart';
import '../security/identity.dart';
import '../services/dashboard_service.dart';

class DashboardController {
  final DashboardService service;
  DashboardController(this.service);
  Future<Response> activities(Request r, Identity user) async =>
      json(await service.activities(QueryInput(r.url.queryParameters)));
  Future<Response> deliveries(Request r, Identity user) async =>
      json(await service.deliveries(QueryInput(r.url.queryParameters)));
}
