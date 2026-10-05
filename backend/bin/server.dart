import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';

Future<void> main() async {
  final port = int.tryParse(Platform.environment['PORT'] ?? '') ?? 8080;
  final router = Router()
    ..get('/api/health', (Request request) {
      return Response.ok(
        '{"status":"ok","service":"folks-connect-backend"}',
        headers: {'content-type': 'application/json'},
      );
    })
    ..get('/api', (Request request) {
      return Response.ok(
        '{"message":"Folks Connect API"}',
        headers: {'content-type': 'application/json'},
      );
    });

  final handler = const Pipeline()
      .addMiddleware(logRequests())
      .addHandler(router.call);

  final server = await shelf_io.serve(handler, InternetAddress.anyIPv4, port);
  print('Backend ouvindo em http://${server.address.host}:${server.port}');
}