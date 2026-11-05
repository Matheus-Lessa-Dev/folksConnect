import 'dart:io';

import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:folks_connect_backend/src/application.dart';
import 'package:folks_connect_backend/src/database.dart';

Future<void> main() async {
  final port = int.tryParse(Platform.environment['PORT'] ?? '') ?? 8080;
  final pool = Database.connect(Platform.environment);
  final db = Database(pool);
  await db.migrate(
      Platform.environment['MIGRATIONS_PATH'] ?? 'database/migrations');
  final application = Application(db, Platform.environment);
  await application.auth.seedDevelopment();
  final server =
      await shelf_io.serve(application.call, InternetAddress.anyIPv4, port);
  server.idleTimeout = const Duration(seconds: 30);
  ProcessSignal.sigint.watch().listen((_) async {
    await server.close(force: true);
    await pool.close();
    exit(0);
  });
  if (!Platform.isWindows) {
    ProcessSignal.sigterm.watch().listen((_) async {
      await server.close(force: true);
      await pool.close();
      exit(0);
    });
  }
  print('Backend ouvindo em http://${server.address.host}:${server.port}');
}
