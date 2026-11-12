import '../repositories/attachments_repository.dart';
import '../dto/upload.dart';
import '../dto/download.dart';

import '../database.dart';
import '../dto/validation.dart';
import '../security.dart';

class AttachmentService {
  final Database db;
  final AttachmentRepository repository = AttachmentRepository();
  AttachmentService(this.db);

  Future<Row> create(List<Upload> files, Identity user, int taskId) async {
    user.require('B');
    if (await repository.findTask(db, {'id': taskId}) == null) {
      missing('Tarefa');
    }
    return db.transaction((tx) async {
      final result = <Row>[];
      for (final file in files) {
        final row = await repository.insertAttachment(tx, {
          'tarefa': taskId,
          'nome': file.name,
          'tipo': file.type,
          'tamanho': file.bytes.length,
          'conteudo': file.bytes
        });
        result.add(row!);
      }
      return {'items': result};
    });
  }

  Future<DownloadDto> download(int taskId, int id) async {
    final row = await repository.findDownload(db, {'id': id, 'tarefa': taskId});
    if (row == null) missing('Anexo da tarefa');
    return DownloadDto(row['nome'] as String, row['content_type'] as String,
        row['conteudo'] as List<int>);
  }

  Future<void> delete(Identity user, int taskId, int id) async {
    user.require('B');
    final result =
        await repository.deleteAttachment(db, {'id': id, 'tarefa': taskId});
    if (result.isEmpty) missing('Anexo da tarefa');
    return;
  }
}
