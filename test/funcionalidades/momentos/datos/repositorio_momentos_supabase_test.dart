import 'package:capsoul/funcionalidades/elementos/dominio/tipo_elemento.dart';
import 'package:capsoul/funcionalidades/momentos/datos/acceso_tablas_momentos.dart';
import 'package:capsoul/funcionalidades/momentos/datos/repositorio_momentos_supabase.dart';
import 'package:capsoul/funcionalidades/momentos/dominio/fallo_momento.dart';
import 'package:capsoul/funcionalidades/momentos/dominio/nuevo_momento.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:capsoul/nucleo/infraestructura/traductor_errores_backend.dart';

import '../../../ayudantes/falsos_recuerdos.dart';

class _AccesoFalso implements AccesoTablasMomentos {
  final List<String> operaciones = [];
  final List<Map<String, dynamic>> momentos = [];
  final List<Map<String, dynamic>> enlaces = [];
  final List<String> borrados = [];
  Object? falloEnPortada;
  int filasBorradas = 1;
  List<Map<String, dynamic>> listado = [];
  Map<String, dynamic>? detalle;

  @override
  Future<void> insertarMomento(Map<String, dynamic> fila) async {
    operaciones.add('momento');
    momentos.add(fila);
  }

  @override
  Future<void> insertarEnlaces(List<Map<String, dynamic>> filas) async {
    operaciones.add('enlaces');
    enlaces.addAll(filas);
  }

  @override
  Future<void> actualizarPortada(String id, String? elementoId) async {
    operaciones.add('portada:$elementoId');
    final fallo = falloEnPortada;
    if (fallo != null) throw fallo;
  }

  @override
  Future<int> eliminarMomento(String id) async {
    borrados.add(id);
    return filasBorradas;
  }

  @override
  Future<List<Map<String, dynamic>>> listarDeAutor(String autorId) async =>
      listado;

  @override
  Future<Map<String, dynamic>?> leerConRecuerdos(String id) async => detalle;
}

void main() {
  late _AccesoFalso acceso;
  late RepositorioMomentosSupabase repositorio;
  final foto = recuerdoPrueba('r-foto');
  final nota = recuerdoPrueba('r-nota', tipo: TipoElemento.texto);

  setUp(() {
    acceso = _AccesoFalso();
    repositorio = RepositorioMomentosSupabase(
      acceso: acceso,
      uidActual: () => 'uid-123',
      generarId: () => 'id-1',
    );
  });

  test('inserta el momento privado, los enlaces y luego la portada', () async {
    final id = await repositorio.crear(NuevoMomento(
      titulo: ' Viaje ',
      descripcion: '  ',
      recuerdos: [nota, foto],
      portadaId: 'r-foto',
    ));

    expect(id, 'id-1');
    expect(acceso.operaciones, ['momento', 'enlaces', 'portada:r-foto']);
    expect(acceso.momentos.single, {
      'id': 'id-1',
      'autor_id': 'uid-123',
      'titulo': 'Viaje',
      'texto': null,
      'visibilidad': 'privado',
    });
    expect(acceso.enlaces, [
      {'momento_id': 'id-1', 'elemento_id': 'r-nota', 'orden': 0},
      {'momento_id': 'id-1', 'elemento_id': 'r-foto', 'orden': 1},
    ]);
  });

  test('si falla la portada (CAP04) borra el momento', () async {
    acceso.falloEnPortada =
        const ErrorPostgrest(mensaje: 'portada', codigo: 'CAP04');
    await expectLater(
      repositorio.crear(NuevoMomento(
        titulo: 'Viaje',
        recuerdos: [foto],
        portadaId: 'r-foto',
      )),
      throwsA(isA<FalloMomento>().having(
          (f) => f.codigo, 'codigo', FalloMomento.codigoPortadaInvalida)),
    );
    expect(acceso.borrados, ['id-1']);
  });

  test('valida antes de escribir', () async {
    await expectLater(
      repositorio.crear(const NuevoMomento(titulo: 'Viaje', recuerdos: [])),
      throwsA(isA<FalloMomento>()),
    );
    expect(acceso.operaciones, isEmpty);
  });

  test('mapea listado (conteo) y detalle (recuerdos ordenados)', () async {
    final portada = {
      'id': 'r-foto',
      'propietario_id': 'uid-123',
      'tipo': 'foto',
      'creado_en': '2026-10-03T12:00:00Z',
    };
    acceso.listado = [
      {
        'id': 'm1',
        'autor_id': 'uid-123',
        'titulo': 'Viaje',
        'texto': 'Playa',
        'creado_en': '2026-10-03T12:00:00Z',
        'portada': portada,
        'momento_elementos': [
          {'count': 7},
        ],
      },
      {'id': 'roto'},
    ];
    final lista = await repositorio.listar();
    expect(lista.single.cantidad, 7);
    expect(lista.single.portada?.id, 'r-foto');
    expect(lista.single.descripcion, 'Playa');

    acceso.detalle = {
      ...acceso.listado.first,
      'momento_elementos': [
        {
          'orden': 1,
          'elementos': portada,
        },
        {
          'orden': 0,
          'elementos': {
            'id': 'r-nota',
            'propietario_id': 'uid-123',
            'tipo': 'texto',
            'creado_en': '2026-10-03T12:00:00Z',
            'contenido_texto': 'Hola',
          },
        },
      ],
    };
    final momento = await repositorio.obtener('m1');
    expect(momento?.recuerdos.map((r) => r.id), ['r-nota', 'r-foto']);
    expect(momento?.cantidad, 2);
  });

  test('borrar 0 filas es permiso denegado', () async {
    acceso.filasBorradas = 0;
    await expectLater(
      repositorio.eliminar('m1'),
      throwsA(isA<FalloMomento>().having(
          (f) => f.codigo, 'codigo', FalloMomento.codigoPermisoDenegado)),
    );
  });
}
