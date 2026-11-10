import 'dart:typed_data';

class Upload {
  final String name;
  final String type;
  final Uint8List bytes;
  Upload(this.name, this.type, this.bytes);
}
