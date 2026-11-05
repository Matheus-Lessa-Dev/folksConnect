import 'dart:convert';
import 'dart:async';
import 'dart:typed_data';

import 'package:shelf/shelf.dart';

class ApiError implements Exception {
  final int status;
  final String code;
  final String message;
  ApiError(this.status, this.code, this.message);
}

Object? jsonValue(Object? value) {
  if (value is DateTime) return value.toUtc().toIso8601String();
  return value;
}

Response json(Object? value, {int status = 200}) =>
    Response(status, body: jsonEncode(value, toEncodable: jsonValue), headers: {
      'content-type': 'application/json; charset=utf-8',
      'cache-control': 'no-store'
    });

Never invalid(String message) => throw ApiError(400, 'validacao', message);
Never missing([String name = 'Registro']) =>
    throw ApiError(404, 'nao_encontrado', '$name não encontrado.');
Never conflict(String message) => throw ApiError(409, 'conflito', message);

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

Future<Map<String, dynamic>> body(Request request, Set<String> allowed) async {
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
  final extra = value.keys.toSet().difference(allowed);
  if (extra.isNotEmpty) invalid('Campos não permitidos: ${extra.join(', ')}.');
  return value;
}

String string(Map<String, dynamic> data, String key,
    {int max = 150, bool optional = false}) {
  final value = data[key];
  if (optional && value == null) return '';
  if (value is! String || value.trim().isEmpty || value.trim().length > max) {
    invalid('$key deve ser texto não vazio de até $max caracteres.');
  }
  return value.trim();
}

int integer(Object? value, String field, {int min = 1, int max = 2147483647}) {
  if (value is! int || value < min || value > max) {
    invalid('$field deve ser inteiro entre $min e $max.');
  }
  return value;
}

int routeId(String value) => integer(int.tryParse(value), 'id');
int queryInt(Request request, String key, int fallback,
        {int max = 2147483647}) =>
    request.url.queryParameters.containsKey(key)
        ? integer(int.tryParse(request.url.queryParameters[key]!), key,
            max: max)
        : fallback;

List<int> ids(Object? value, String field) {
  if (value is! List || value.length > 100) {
    invalid('$field deve ser lista com até 100 IDs.');
  }
  final result = value.map((v) => integer(v, field)).toList();
  if (result.toSet().length != result.length) {
    invalid('$field contém IDs repetidos.');
  }
  return result;
}

String email(Map<String, dynamic> data, String key) {
  final value = string(data, key, max: 150).toLowerCase();
  if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value)) {
    invalid('E-mail inválido.');
  }
  return value;
}

String date(Map<String, dynamic> data, String key) {
  final value = string(data, key, max: 10);
  final parsed = DateTime.tryParse(value);
  if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value) ||
      parsed == null ||
      parsed.year < 1 ||
      parsed.toIso8601String().substring(0, 10) != value) {
    invalid('$key deve ser data válida YYYY-MM-DD.');
  }
  return value;
}

void dates(String start, String end) {
  if (end.compareTo(start) < 0) {
    invalid('prazoFinal deve ser igual ou posterior a prazoInicial.');
  }
}
