import 'package:capsoul/funcionalidades/musica/dominio/cache_busquedas_musica.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../ayudantes/falsos_musica.dart';

void main() {
  final inicio = DateTime.utc(2026, 11, 3, 12);
  var ahora = inicio;

  setUp(() => ahora = inicio);

  CacheBusquedasMusica cache({int maximo = 50}) =>
      CacheBusquedasMusica(reloj: () => ahora, maximoEntradas: maximo);

  test('la llave va en minúsculas y con los espacios colapsados', () {
    expect(normalizarConsultaMusica('  Hola   Mundo \t'), 'hola mundo');
    expect(normalizarConsultaMusica('HOLA'), 'hola');

    final almacen = cache();
    almacen.guardar('  Hola   Mundo  ', [pistaDeezerPrueba()]);

    expect(almacen.obtener('hola mundo'), isNotNull);
    expect(almacen.obtener('HOLA'), isNull);
    expect(almacen.cantidad, 1);
  });

  test('no guarda la URL del preview y la fila de la base sigue en null', () {
    final almacen = cache();
    final original = pistaDeezerPrueba();
    almacen.guardar('hola', [original]);

    final guardada = almacen.obtener('hola')!.single;
    expect(original.previewUrl, isNotNull);
    expect(guardada.previewUrl, isNull);
    expect(guardada.vistaPreviaConocida, isTrue);
    expect(guardada.hayClipConocido, isTrue);
    expect(guardada.etiquetaPreview, 'Vista previa de 30 s');
    expect(guardada.idPistaDeezer, original.idPistaDeezer);
    expect(guardada.aFilaBd()['musica_preview_url'], isNull);
    expect(guardada.puedeReproducirPreview, isTrue);
  });

  test('una pista sin clip sigue sin clip dentro de la caché', () {
    final almacen = cache();
    almacen.guardar('hola', [pistaDeezerPrueba(preview: null)]);
    final guardada = almacen.obtener('HOLA')!.single;
    expect(guardada.previewUrl, isNull);
    expect(guardada.hayClipConocido, isFalse);
    expect(guardada.etiquetaPreview, 'Sin vista previa');
  });

  test('la vigencia es de 15 minutos', () {
    expect(
      CacheBusquedasMusica.vigenciaPorDefecto,
      const Duration(minutes: 15),
    );
    final almacen = cache();
    almacen.guardar('hola', [pistaDeezerPrueba()]);

    ahora = inicio.add(const Duration(minutes: 14, seconds: 59));
    expect(almacen.obtener('hola'), isNotNull);

    ahora = inicio.add(const Duration(minutes: 15));
    expect(almacen.obtener('hola'), isNull);
    expect(almacen.cantidad, 0);
  });

  test('al pasar del máximo se borran las más viejas', () {
    expect(CacheBusquedasMusica.maximoPorDefecto, 50);
    final almacen = cache(maximo: 2);
    almacen
      ..guardar('una', [pistaDeezerPrueba(id: '1', titulo: 'Una')])
      ..guardar('dos', [pistaDeezerPrueba(id: '2', titulo: 'Dos')])
      ..guardar('tres', [pistaDeezerPrueba(id: '3', titulo: 'Tres')]);

    expect(almacen.obtener('una'), isNull);
    expect(almacen.obtener('dos')!.single.titulo, 'Dos');
    expect(almacen.obtener('tres')!.single.titulo, 'Tres');
    expect(almacen.cantidad, 2);

    // Volver a guardar «dos» la deja como la más reciente.
    almacen
      ..guardar('dos', [pistaDeezerPrueba(id: '2', titulo: 'Dos')])
      ..guardar('cuatro', [pistaDeezerPrueba(id: '4', titulo: 'Cuatro')]);
    expect(almacen.obtener('tres'), isNull);
    expect(almacen.obtener('dos'), isNotNull);
    expect(almacen.obtener('cuatro'), isNotNull);
  });

  test('las vencidas no ocupan sitio', () {
    final almacen = cache(maximo: 2);
    almacen
      ..guardar('vieja', [pistaDeezerPrueba(id: '1')])
      ..guardar('tambien', [pistaDeezerPrueba(id: '2')]);
    ahora = inicio.add(const Duration(minutes: 15));
    almacen.guardar('nueva', [pistaDeezerPrueba(id: '3', titulo: 'Nueva')]);

    expect(almacen.cantidad, 1);
    expect(almacen.obtener('nueva')!.single.titulo, 'Nueva');
    expect(almacen.obtener('vieja'), isNull);
  });
}
