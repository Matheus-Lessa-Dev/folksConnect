import 'package:shelf/shelf.dart';
import '../http.dart';
import '../security/identity.dart';
import '../services/settings_service.dart';

class SettingsController {
  final SettingsService service;
  SettingsController(this.service);
  Future<Response> get(Request r, Identity user) async =>
      json(await service.get());
  Future<Response> put(Request r, Identity user) async =>
      json(await service.put(await readJson(r), user));
}
