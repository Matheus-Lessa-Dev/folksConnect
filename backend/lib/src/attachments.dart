import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';

import 'package:mime/mime.dart';
import 'package:shelf/shelf.dart';

import 'database.dart';
import 'http.dart';
import 'security.dart';

class Upload {
  final String name;
  final String type;
  final Uint8List bytes;
  Upload(this.name, this.type, this.bytes);
}

class Attachments {
  static const maxFile = 10 * 1024 * 1024;
  final Database db;
  Attachments(this.db);

  bool hasClosingBoundary(Uint8List bytes, String boundary) {
    final marker = ascii.encode('--$boundary--');
    for (var start = bytes.length - marker.length; start >= 0; start--) {
      if (bytes[start] != marker.first ||
          (start != 0 && (start < 2 || bytes[start - 2] != 13 || bytes[start - 1] != 10))) {
        continue;
      }
      var matches = true;
      for (var offset = 1; offset < marker.length; offset++) {
        if (bytes[start + offset] != marker[offset]) {
          matches = false;
          break;
        }
      }
      final end = start + marker.length;
      if (matches && (end == bytes.length ||
          (end + 1 < bytes.length && bytes[end] == 13 && bytes[end + 1] == 10))) {
        return true;
      }
    }
    return false;
  }

  String fileName(String? value) {
    if (value == null ||
        value.trim().isEmpty ||
        value.length > 255 ||
        RegExp(r'[/\\\x00-\x1f\x7f]').hasMatch(value) ||
        value.trim() == '.' ||
        value.trim() == '..') {
      invalid('Nome de arquivo inválido.');
    }
    return value.trim();
  }

  String? multipartName(String? value) {
    // MIME expõe os bytes do cabeçalho como caracteres Latin-1; browsers e
    // Insomnia enviam nomes acentuados em UTF-8. Mantém clientes Latin-1 válidos.
    if (value == null || value.codeUnits.any((unit) => unit > 255)) return value;
    try {
      return utf8.decode(latin1.encode(value));
    } on FormatException {
      return value;
    }
  }

  Upload upload(String? name, String? contentType, Uint8List bytes) {
    if (bytes.isEmpty) invalid('Arquivo vazio.');
    if (bytes.length > maxFile) {
      throw ApiError(413, 'limite_excedido',
          'Cada arquivo pode ter até 10 MB (10485760 bytes).');
    }
    String type;
    try {
      type =
          ContentType.parse(contentType ?? 'application/octet-stream').mimeType;
    } on FormatException {
      invalid('Tipo do arquivo inválido.');
    }
    if (type.length > 150) invalid('Tipo do arquivo inválido.');
    return Upload(fileName(name), type, bytes);
  }

  Future<Response> create(Request request, Identity user, int taskId) async {
    user.require('B');
    if (await db.one('SELECT id_tarefa FROM tarefas WHERE id_tarefa = @id',
            {'id': taskId}) ==
        null) {
      missing('Tarefa');
    }
    final files = <Upload>[];
    ContentType type;
    try {
      type = ContentType.parse(
          request.headers['content-type'] ?? 'application/octet-stream');
    } on FormatException {
      invalid('Content-Type inválido.');
    }
    if (type.mimeType == 'multipart/form-data') {
      final boundary = type.parameters['boundary'];
      if (boundary == null || boundary.isEmpty || boundary.length > 70 ||
          boundary.codeUnits.any((value) => value < 32 || value > 126)) {
        invalid('Boundary multipart inválido.');
      }
      final bytes = await readLimited(request, 10 * maxFile + 65536);
      // O parser aguarda a última parte indefinidamente quando falta o
      // delimitador final. O corpo já está limitado e lido por completo aqui.
      if (!hasClosingBoundary(bytes, boundary)) invalid('Multipart sem fechamento válido.');
      try {
        await for (final part
            in MimeMultipartTransformer(boundary).bind(Stream.value(bytes))) {
          final data = BytesBuilder(copy: false);
          var oversized = false;
          await for (final chunk in part) {
            if (!oversized && data.length + chunk.length > maxFile) {
              oversized = true;
              data.clear();
            }
            if (!oversized) data.add(chunk);
          }
          // Consome cada parte antes de rejeitar metadados/tamanho: o parser
          // só libera o stream externo quando a parte atual é consumida.
          if (oversized) {
            throw ApiError(413, 'limite_excedido', 'Cada arquivo pode ter até 10 MB.');
          }
          final disposition =
              HeaderValue.parse(part.headers['content-disposition'] ?? '');
          if (disposition.value != 'form-data' ||
              !{'arquivo', 'arquivos'}.contains(disposition.parameters['name'])) {
            invalid('Use o campo multipart arquivo ou arquivos.');
          }
          if (files.length >= 10) {
            invalid('Envie no máximo 10 arquivos por requisição.');
          }
          files.add(upload(multipartName(disposition.parameters['filename']),
              part.headers['content-type'], data.takeBytes()));
        }
      } on FormatException {
        invalid('Multipart inválido.');
      } on MimeMultipartException {
        invalid('Multipart inválido.');
      }
    } else {
      String? name = request.headers['x-file-name'];
      if (name != null) {
        try {
          name = Uri.decodeComponent(name);
        } on ArgumentError {
          invalid('X-File-Name inválido.');
        }
      }
      files.add(
          upload(name, type.mimeType, await readLimited(request, maxFile)));
    }
    if (files.isEmpty) invalid('Envie ao menos um arquivo.');
    return db.transaction((tx) async {
      final result = <Row>[];
      for (final file in files) {
        final row = await tx.one(
            '''INSERT INTO anexos (tarefa_id, nome, content_type, tamanho, conteudo)
          VALUES (@tarefa, @nome, @tipo, @tamanho, @conteudo)
          RETURNING id, nome, content_type AS "contentType", tamanho, criado_em AS "criadoEm"''',
            {
              'tarefa': taskId,
              'nome': file.name,
              'tipo': file.type,
              'tamanho': file.bytes.length,
              'conteudo': file.bytes
            });
        result.add(row!);
      }
      return json({'items': result}, status: 201);
    });
  }

  Future<Response> download(int taskId, int id) async {
    final row = await db.one(
        'SELECT nome, content_type, conteudo FROM anexos WHERE id = @id AND tarefa_id = @tarefa',
        {'id': id, 'tarefa': taskId});
    if (row == null) missing('Anexo da tarefa');
    return Response.ok(row['conteudo'], headers: {
      'content-type': row['content_type'] as String,
      'content-disposition':
          "attachment; filename*=UTF-8''${Uri.encodeComponent(row['nome'] as String)}",
      'cache-control': 'no-store',
    });
  }

  Future<Response> delete(Identity user, int taskId, int id) async {
    user.require('B');
    final result = await db.query(
        'DELETE FROM anexos WHERE id = @id AND tarefa_id = @tarefa RETURNING id',
        {'id': id, 'tarefa': taskId});
    if (result.isEmpty) missing('Anexo da tarefa');
    return Response(204);
  }
}
