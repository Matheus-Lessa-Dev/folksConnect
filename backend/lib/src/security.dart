import 'dart:convert';
import 'dart:isolate';
import 'dart:math';

import 'package:crypto/crypto.dart' show sha256;
import 'package:cryptography/cryptography.dart';

import 'http.dart';

String randomToken([int length = 32]) {
  final random = Random.secure();
  return base64UrlEncode(List.generate(length, (_) => random.nextInt(256)))
      .replaceAll('=', '');
}

String tokenHash(String value) => sha256.convert(utf8.encode(value)).toString();

String password(Map<String, dynamic> data) {
  final value = data['senha'];
  if (value is! String ||
      value.length < 12 ||
      value.length > 128 ||
      value.trim().isEmpty) {
    invalid('senha deve ter entre 12 e 128 caracteres.');
  }
  return value;
}

Future<String> hashPassword(String value) => Isolate.run(() async {
      final salt = randomToken(16);
      final key = await Pbkdf2(
              macAlgorithm: Hmac.sha256(), iterations: 600000, bits: 256)
          .deriveKey(
              secretKey: SecretKey(utf8.encode(value)),
              nonce: utf8.encode(salt));
      return 'pbkdf2-sha256\$600000\$$salt\$${base64UrlEncode(await key.extractBytes())}';
    });

Future<bool> verifyPassword(String value, String encoded) =>
    Isolate.run(() async {
      final parts = encoded.split('\$');
      if (parts.length != 4 ||
          parts[0] != 'pbkdf2-sha256' ||
          parts[1] != '600000') {
        return false;
      }
      final key = await Pbkdf2(
              macAlgorithm: Hmac.sha256(), iterations: 600000, bits: 256)
          .deriveKey(
              secretKey: SecretKey(utf8.encode(value)),
              nonce: utf8.encode(parts[2]));
      final actual = await key.extractBytes();
      final expected = base64Url.decode(parts[3]);
      if (actual.length != expected.length) return false;
      var difference = 0;
      for (var i = 0; i < actual.length; i++) {
        difference |= actual[i] ^ expected[i];
      }
      return difference == 0;
    });

class Identity {
  final int id;
  final bool admin;
  final Set<String> permissions;
  Identity(this.id, this.admin, this.permissions);
  void require(String permission) {
    if (!admin && !permissions.contains(permission)) {
      throw ApiError(403, 'acesso_negado', 'Permissão insuficiente.');
    }
  }
}
