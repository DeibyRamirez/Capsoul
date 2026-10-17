import 'package:capsoul/funcionalidades/perfil/aplicacion/urls_avatar.dart';
import 'package:capsoul/funcionalidades/recuerdos/dominio/enlace_medio.dart';
import 'package:capsoul/funcionalidades/recuerdos/dominio/url_medio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final expira = DateTime.utc(2030, 1, 1);
  final medio = UrlMedio(
    idRecuerdo: 'avatar',
    publicId: 'capsoul/usuarios/u1/avatar',
    original: EnlaceFirmado(
      url: 'https://example.com/original',
      expiraEn: expira,
    ),
    miniatura: EnlaceFirmado(
      url: 'https://example.com/thumb',
      expiraEn: expira,
    ),
  );

  test('urlPreferidaAvatar prioriza original', () {
    expect(urlPreferidaAvatar(medio), 'https://example.com/original');
  });

  test('urlAlternativaAvatar devuelve miniatura si falló original', () {
    expect(
      urlAlternativaAvatar(medio, 'https://example.com/original'),
      'https://example.com/thumb',
    );
  });

  test('urlAlternativaAvatar devuelve original si falló miniatura', () {
    expect(
      urlAlternativaAvatar(medio, 'https://example.com/thumb'),
      'https://example.com/original',
    );
  });
}
