import 'dart:convert';
import 'dart:async';
import 'dart:typed_data';

import 'package:shelf/shelf.dart';
import 'dto/input.dart';
import 'dto/validation.dart';
import 'exceptions/api_error.dart';
export 'dto/validation.dart';
export 'exceptions/api_error.dart';

Object? jsonValue(Object? value) {
  if (value is DateTime) return value.toUtc().toIso8601String();
  return value;
}

Response json(Object? value, {int status = 200}) =>
    Response(status, body: jsonEncode(value, toEncodable: jsonValue), headers: {
      'content-type': 'application/json; charset=utf-8',
      'cache-control': 'no-store'
    });

Future<Uint8List> readLimited(Request request, int max) async {
  final declared = int.tryParse(request.headers['content-length'] ?? '');
  var oversized = declared != null && declared > max;
  final bytes = BytesBuilder(copy: false);
  try {
    await for (final chunk
        in request.read().timeout(const Duration(seconds: 30))) {
      if (!oversized && bytes.length + chunk.length > max) {
        oversized = true;
        bytes.clear();
      }
      // Consome o restante sem guardar bytes, permitindo devolver HTTP 413
      // também para uploads chunked sem interromper a conexão antes da resposta.
      if (!oversized) bytes.add(chunk);
    }
  } on TimeoutException {
    throw ApiError(
        408, 'tempo_esgotado', 'Tempo de recebimento da requisição esgotado.');
  }
  if (oversized) {
    throw ApiError(
        413, 'limite_excedido', 'Corpo da requisição excede o limite.');
  }
  return bytes.takeBytes();
}

Future<JsonInput> readJson(Request request) async {
  if (!(request.headers['content-type'] ?? '')
      .toLowerCase()
      .startsWith('application/json')) {
    throw ApiError(415, 'tipo_invalido', 'Use Content-Type: application/json.');
  }
  Object? value;
  try {
    value = jsonDecode(utf8.decode(await readLimited(request, 1024 * 1024)));
  } on FormatException {
    invalid('JSON inválido.');
  }
  if (value is! Map<String, dynamic>) {
    invalid('O corpo deve ser um objeto JSON.');
  }
  return JsonInput(value);
}
