import 'package:folks_connect_backend/src/http.dart';
import 'package:folks_connect_backend/src/security.dart';
import 'package:test/test.dart';

void main() {
  test('datas inválidas e invertidas são recusadas', () {
    expect(
        () => date({'data': '2026-02-30'}, 'data'), throwsA(isA<ApiError>()));
    expect(() => dates('2026-11-04', '2026-11-03'), throwsA(isA<ApiError>()));
    expect(date({'data': '2026-11-03'}, 'data'), '2026-11-03');
  });
  test('IDs não aceitam frações, negativos ou repetições', () {
    for (final value in [0, -1, 1.5, '1', null]) {
      expect(() => integer(value, 'id'), throwsA(isA<ApiError>()));
    }
    expect(() => ids([1, 1], 'ids'), throwsA(isA<ApiError>()));
  });
  test('hash de senha usa sal e verifica a senha sem trim', () async {
    final first = await hashPassword(' senha teste 2026 ');
    final second = await hashPassword(' senha teste 2026 ');
    expect(first, isNot(second));
    expect(await verifyPassword(' senha teste 2026 ', first), true);
    expect(await verifyPassword('senha teste 2026', first), false);
  });
}
