import 'package:capsoul/nucleo/enlaces/enlace_capsoul.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('capsula: construir y parsear id', () {
    const id = 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee';
    final uri = Uri.parse(EnlaceCapsoul.capsula(id));
    expect(EnlaceCapsoul.idCapsulaDesde(uri), id);
  });

  test('amistad: construir y parsear token', () {
    const token = 'tok_en_abc';
    final uri = Uri.parse(EnlaceCapsoul.amistad(token));
    expect(EnlaceCapsoul.tokenAmistadDesde(uri), token);
  });

  test('ignora enlaces de auth', () {
    final auth = Uri.parse('capsoul://auth/callback');
    expect(EnlaceCapsoul.idCapsulaDesde(auth), isNull);
    expect(EnlaceCapsoul.tokenAmistadDesde(auth), isNull);
  });
}
