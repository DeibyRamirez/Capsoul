import 'dart:async';

import 'package:capsoul/funcionalidades/musica/aplicacion/controlador_busqueda_musica.dart';
import 'package:capsoul/funcionalidades/musica/aplicacion/proveedores_musica.dart';
import 'package:capsoul/funcionalidades/musica/dominio/fallo_musica.dart';
import 'package:capsoul/funcionalidades/musica/dominio/referencia_musica.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../ayudantes/falsos_musica.dart';

void main() {
  late CatalogoMusicaFalso catalogo;
  late ProviderContainer contenedor;

  setUp(() {
    catalogo = CatalogoMusicaFalso();
    contenedor = ProviderContainer(
      overrides: [
        proveedorRepositorioCatalogoMusica.overrideWithValue(catalogo),
        proveedorEsperaBusquedaMusica
            .overrideWithValue(const Duration(milliseconds: 30)),
      ],
    );
    contenedor.listen(proveedorControladorBusquedaMusica, (_, _) {});
  });

  tearDown(() => contenedor.dispose());

  ControladorBusquedaMusica controlador() =>
      contenedor.read(proveedorControladorBusquedaMusica.notifier);

  test('debounce: solo busca la última consulta', () async {
    catalogo.respuestas['daft punk'] = [pistaDeezerPrueba()];
    controlador().cambiarConsulta('da');
    controlador().cambiarConsulta('daft');
    controlador().cambiarConsulta('daft punk');
    await Future<void>.delayed(const Duration(milliseconds: 80));

    expect(catalogo.consultas, ['daft punk']);
    final estado = contenedor.read(proveedorControladorBusquedaMusica);
    expect(estado.resultados, hasLength(1));
    expect(estado.cargando, isFalse);
  });

  test('consulta de menos de 2 letras no busca', () async {
    controlador().cambiarConsulta('a');
    await Future<void>.delayed(const Duration(milliseconds: 60));
    expect(catalogo.consultas, isEmpty);
    expect(
      contenedor.read(proveedorControladorBusquedaMusica).consultaValida,
      isFalse,
    );
  });

  test('ignora la respuesta de una búsqueda vieja', () async {
    final vieja = Completer<List<ReferenciaMusica>>();
    final nueva = Completer<List<ReferenciaMusica>>();
    catalogo.pendientes['uno'] = vieja;
    catalogo.pendientes['dos'] = nueva;

    controlador().cambiarConsulta('uno');
    final primera = controlador().buscarAhora();
    controlador().cambiarConsulta('dos');
    final segunda = controlador().buscarAhora();

    nueva.complete([pistaDeezerPrueba(id: '2', titulo: 'Nueva')]);
    await segunda;
    vieja.complete([pistaDeezerPrueba(id: '1', titulo: 'Vieja')]);
    await primera;

    final estado = contenedor.read(proveedorControladorBusquedaMusica);
    expect(estado.resultados.single.titulo, 'Nueva');
    expect(estado.consultaBuscada, 'dos');
  });

  test('borrar la consulta descarta la respuesta pendiente', () async {
    final pendiente = Completer<List<ReferenciaMusica>>();
    catalogo.pendientes['uno'] = pendiente;
    controlador().cambiarConsulta('uno');
    final busqueda = controlador().buscarAhora();
    controlador().cambiarConsulta('');
    pendiente.complete([pistaDeezerPrueba()]);
    await busqueda;
    expect(
      contenedor.read(proveedorControladorBusquedaMusica).resultados,
      isEmpty,
    );
  });

  test('resultado vacío marca sinResultados', () async {
    controlador().cambiarConsulta('zzzz');
    await controlador().buscarAhora();
    final estado = contenedor.read(proveedorControladorBusquedaMusica);
    expect(estado.sinResultados, isTrue);
    expect(estado.error, isNull);
  });

  test('error de Deezer queda como mensaje en español', () async {
    catalogo.fallo = const FalloMusica(TipoFalloMusica.tiempoAgotado);
    controlador().cambiarConsulta('daft');
    await controlador().buscarAhora();
    final estado = contenedor.read(proveedorControladorBusquedaMusica);
    expect(estado.error, contains('tardó demasiado'));
    expect(estado.cargando, isFalse);
    expect(estado.sinResultados, isFalse);
  });
}
