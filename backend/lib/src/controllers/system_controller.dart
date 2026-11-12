import 'package:shelf/shelf.dart';
import '../http.dart';
import '../repositories/system_repository.dart';

class SystemController {
  final SystemRepository repository;
  SystemController(this.repository);
  Response index(Request r) => json({'message': 'Folks Connect API'});
  Future<Response> health(Request r) async {
    await repository.health();
    return json({'status': 'ok', 'service': 'folks-connect-backend'});
  }
}
