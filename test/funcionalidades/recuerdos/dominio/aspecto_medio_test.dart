import 'package:capsoul/funcionalidades/elementos/dominio/tipo_elemento.dart';
import 'package:capsoul/funcionalidades/recuerdos/dominio/aspecto_medio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('usa dimensiones reales cuando existen', () {
    expect(
      aspectoMedio(tipo: TipoElemento.foto, ancho: 1920, alto: 1080),
      1920 / 1080,
    );
  });

  test('fallback por tipo', () {
    expect(aspectoMedio(tipo: TipoElemento.foto), 4 / 3);
    expect(aspectoMedio(tipo: TipoElemento.video), 16 / 9);
  });
}
