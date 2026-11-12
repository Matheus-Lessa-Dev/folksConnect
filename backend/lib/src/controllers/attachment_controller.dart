import 'package:shelf/shelf.dart';
import 'upload_decoder.dart';
import '../http.dart';
import '../security/identity.dart';
import '../services/attachments_service.dart';

class AttachmentController {
  final AttachmentService service;
  AttachmentController(this.service);
  Future<Response> create(Request r, Identity user, String task) async {
    user.require('B');
    return json(
        await service.create(
            await UploadDecoder().read(r), user, routeId(task)),
        status: 201);
  }

  Future<Response> download(
      Request r, Identity user, String task, String id) async {
    final file = await service.download(routeId(task), routeId(id));
    return Response.ok(file.bytes, headers: {
      'content-type': file.contentType,
      'content-disposition':
          "attachment; filename*=UTF-8''${Uri.encodeComponent(file.name)}",
      'cache-control': 'no-store',
    });
  }

  Future<Response> delete(
      Request r, Identity user, String task, String id) async {
    await service.delete(user, routeId(task), routeId(id));
    return Response(204);
  }
}
