import 'dart:convert';
import 'dart:io';

/// Servidor SMTP exclusivo da suíte. Captura mensagens locais, sem encaminhá-las.
class SmtpCapture {
  final ServerSocket server;
  final sockets = <Socket>[];
  final messages = <String>[];
  SmtpCapture._(this.server) {
    server.listen((socket) {
      sockets.add(socket);
      socket.write('220 localhost ESMTP test\r\n');
      var inData = false;
      final content = StringBuffer();
      socket
          .cast<List<int>>()
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen((line) {
        if (inData) {
          if (line == '.') {
            inData = false;
            messages.add(content.toString());
            content.clear();
            socket.write('250 Message accepted\r\n');
          } else {
            content.writeln(line.startsWith('..') ? line.substring(1) : line);
          }
          return;
        }
        final command = line.toUpperCase();
        if (command.startsWith('EHLO')) {
          socket.write('250-localhost\r\n250 SIZE 1000000\r\n');
        } else if (command.startsWith('DATA')) {
          inData = true;
          socket.write('354 End with dot\r\n');
        } else if (command.startsWith('QUIT')) {
          socket.write('221 Bye\r\n');
          socket.close();
        } else {
          socket.write('250 OK\r\n');
        }
      });
    });
  }
  static Future<SmtpCapture> start() async =>
      SmtpCapture._(await ServerSocket.bind('127.0.0.1', 0));
  int get port => server.port;
  String get token {
    final raw = messages.last;
    final boundary = raw.indexOf('\n\n');
    if (boundary < 0) throw StateError('E-mail SMTP sem corpo.');
    final headers = raw.substring(0, boundary).toLowerCase();
    final encoded = raw.substring(boundary + 2);
    final message = headers.contains('content-transfer-encoding: base64')
        ? utf8.decode(base64.decode(encoded.replaceAll(RegExp(r'\s'), '')))
        : encoded.replaceAll('=\n', '');
    final match =
        RegExp(r'^([A-Za-z0-9_-]{43})$', multiLine: true).firstMatch(message);
    if (match == null) {
      throw StateError('O e-mail de teste não contém token legível.');
    }
    return match.group(1)!;
  }

  Future<void> close() async {
    for (final socket in sockets) {
      socket.destroy();
    }
    await server.close();
  }
}
