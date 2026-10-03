import 'package:capsoul/funcionalidades/capsulas/datos/acceso_tablas_capsulas.dart';
import 'package:capsoul/funcionalidades/capsulas/datos/repositorio_capsulas_supabase.dart';
import 'package:capsoul/funcionalidades/capsulas/dominio/estado_capsula.dart';
import 'package:capsoul/funcionalidades/capsulas/dominio/fallo_capsula.dart';
import 'package:capsoul/funcionalidades/capsulas/dominio/nueva_capsula.dart';
import 'package:capsoul/funcionalidades/elementos/dominio/fallo_medios.dart';
import 'package:capsoul/funcionalidades/elementos/dominio/tipo_elemento.dart';
import 'package:capsoul/funcionalidades/recuerdos/dominio/recuerdo.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../ayudantes/falsos_recuerdos.dart';

/// Base en memoria que registra cada operación.
class _AccesoFalso implements AccesoTablasCapsulas {
  final List<String> operaciones = [];
  final List<Map<String, dynamic>> capsulas = [];
  final List<Map<String, dynamic>> enlaces = [];
  final List<String> capsulasBorradas = [];
  Object? falloEnCapsula;
  Object? falloEnEnlaces;
  Map<String, dynamic>? filaLeida;

  @override
  Future<void> insertarCapsula(Map<String, dynamic> fila) async {
    operaciones.add('capsula:${fila['estado']}');
    final fallo = falloEnCapsula;
    if (fallo != null) throw fallo;
    capsulas.add(fila);
  }

  @override
  Future<void> insertarEnlaces(List<Map<String, dynamic>> filas) async {
    operaciones.add('enlaces');
    final fallo = falloEnEnlaces;
    if (fallo != null) throw fallo;
    enlaces.addAll(filas);
  }

  @override
  Future<void> actualizarEstadoCapsula(String id, String estado) async {
    operaciones.add('estado:$estado');
  }

  @override
  Future<void> eliminarCapsula(String id) async => capsulasBorradas.add(id);

  @override
  Future<List<Map<String, dynamic>>> leerCapsulasDeAutor(String autorId) async =>
      [?filaLeida, {'id': 'rota'}];

  @override
  Future<Map<String, dynamic>?> leerCapsulaConElementos(String id) async =>
      filaLeida;
}

void main() {
  final ahora = DateTime(2026, 10, 3, 10);
  late _AccesoFalso acceso;
  late RepositorioCapsulasSupabase repositorio;

  final nota = recuerdoPrueba('r-nota', tipo: TipoElemento.texto);
  final foto = recuerdoPrueba('r-foto');

  NuevaCapsula nueva(List<Recuerdo> recuerdos) => NuevaCapsula(
        titulo: '  Para Jacobo ',
        mensaje: '  ',
        fechaApertura: DateTime.utc(2046, 8, 13, 13),
        recuerdos: recuerdos,
      );

  setUp(() {
    var siguienteId = 0;
    acceso = _AccesoFalso();
    repositorio = RepositorioCapsulasSupabase(
      acceso: acceso,
      uidActual: () => 'uid-123',
      reloj: () => ahora,
      generarId: () => 'id-${++siguienteId}',
    );
  });

  test('cápsula en borrador, enlaces con orden y la programa', () async {
    final id = await repositorio.crearCapsula(nueva([foto, nota]));

    // El id de la cápsula lo genera el cliente.
    expect(id, 'id-1');
    expect(acceso.operaciones, [
      'capsula:borrador',
      'enlaces',
      'estado:programada',
    ]);
    expect(acceso.capsulas.single['id'], 'id-1');
    expect(acceso.capsulas.single['autor_id'], 'uid-123');
    expect(acceso.capsulas.single['titulo'], 'Para Jacobo');
    expect(acceso.capsulas.single['mensaje'], isNull);
    expect(acceso.capsulas.single['fecha_apertura'], '2046-08-13T13:00:00.000Z');
    expect(acceso.enlaces, [
      {'capsula_id': 'id-1', 'elemento_id': 'r-foto', 'orden': 0},
      {'capsula_id': 'id-1', 'elemento_id': 'r-nota', 'orden': 1},
    ]);
  });

  test('valida antes de escribir nada', () async {
    await expectLater(
      repositorio.crearCapsula(nueva(const [])),
      throwsA(isA<FalloCapsula>().having(
        (f) => f.codigo,
        'codigo',
        FalloCapsula.codigoSinElementos,
      )),
    );
    expect(acceso.operaciones, isEmpty);
  });

  test('sin sesión no guarda', () async {
    final sinSesion = RepositorioCapsulasSupabase(
      acceso: acceso,
      uidActual: () => null,
      reloj: () => ahora,
    );
    await expectLater(
      sinSesion.crearCapsula(nueva([nota])),
      throwsA(isA<FalloCapsula>()),
    );
    expect(acceso.operaciones, isEmpty);
  });

  test('si la cápsula no se inserta, no hay nada que deshacer', () async {
    acceso.falloEnCapsula = const PostgrestException(
      message: 'new row violates row-level security policy for table '
          '"capsulas"',
      code: '42501',
    );

    await expectLater(
      repositorio.crearCapsula(nueva([nota])),
      throwsA(isA<FalloCapsula>().having(
        (f) => f.codigo,
        'codigo',
        FalloCapsula.codigoPermisoDenegado,
      )),
    );
    expect(acceso.capsulasBorradas, isEmpty);
  });

  test('si fallan los enlaces, borra solo la cápsula', () async {
    acceso.falloEnEnlaces = const PostgrestException(
      message: 'máximo de elementos',
      code: 'CAP02',
    );

    await expectLater(
      repositorio.crearCapsula(nueva([nota])),
      throwsA(isA<FalloCapsula>().having(
        (f) => f.codigo,
        'codigo',
        FalloCapsula.codigoDemasiadosElementos,
      )),
    );
    expect(acceso.capsulasBorradas, ['id-1']);
  });

  group('traducirError', () {
    test('cuota (CAP01), permisos, fecha y check', () {
      expect(
        RepositorioCapsulasSupabase.traducirError(
          PostgrestException(message: 'cuota', code: 'CAP01'),
        ).codigo,
        FalloMedios.codigoCuotaExcedida,
      );
      expect(
        RepositorioCapsulasSupabase.traducirError(
          PostgrestException(message: 'x', code: '42501'),
        ).codigo,
        FalloCapsula.codigoPermisoDenegado,
      );
      // El mensaje dice qué tabla rechazó la fila (antes siempre "cápsula").
      expect(
        RepositorioCapsulasSupabase.traducirError(
          PostgrestException(
            message: 'new row violates row-level security policy for table '
                '"elementos"',
            code: '42501',
          ),
        ).mensaje,
        'No tienes permiso para guardar o cambiar este recuerdo.',
      );
      expect(
        RepositorioCapsulasSupabase.traducirError(
          PostgrestException(
            message: 'new row violates row-level security policy for table '
                '"capsula_elementos"',
            code: '42501',
          ),
        ).codigo,
        FalloCapsula.codigoPermisoEnlace,
      );
      expect(
        RepositorioCapsulasSupabase.traducirError(
          PostgrestException(message: 'JWT expired', code: 'PGRST301'),
        ).codigo,
        FalloCapsula.codigoSesionVencida,
      );
      expect(
        RepositorioCapsulasSupabase.traducirError(
          PostgrestException(
            message: 'La fecha de apertura debe estar en el futuro',
            code: 'P0001',
          ),
        ).codigo,
        FalloCapsula.codigoFechaInvalida,
      );
      expect(
        RepositorioCapsulasSupabase.traducirError(
          PostgrestException(message: 'x', code: '23514'),
        ).codigo,
        'dato_invalido',
      );
      expect(
        RepositorioCapsulasSupabase.traducirError(
          PostgrestException(message: 'fk', code: '23503'),
        ).codigo,
        'recuerdo_no_existe',
      );
    });
  });

  group('lectura', () {
    final fila = <String, dynamic>{
      'id': 'c1',
      'autor_id': 'uid-123',
      'titulo': 'Para Jacobo',
      'mensaje': 'Hola',
      'fecha_apertura': '2046-08-13T13:00:00+00:00',
      'estado': 'programada',
      'liberada_en': null,
      'creado_en': '2026-10-03T15:00:00+00:00',
      'capsula_elementos': [
        {
          'orden': 1,
          'elementos': {
            'id': 'e2',
            'propietario_id': 'uid-123',
            'tipo': 'audio',
            'titulo': 'Canción',
            'fecha_recuerdo': '2026-09-30',
            'creado_en': '2026-10-01T02:00:00Z',
            'cloudinary_public_id': 'p2',
            'bytes': 1000,
            'duracion_segundos': 92.4,
          },
        },
        {
          'orden': 0,
          'elementos': {
            'id': 'e1',
            'propietario_id': 'uid-123',
            'tipo': 'texto',
            'creado_en': '2026-10-01T02:00:00Z',
            'contenido_texto': 'Nota',
          },
        },
        {'orden': 2, 'elementos': {'id': 'e3', 'tipo': 'desconocido'}},
      ],
    };

    test('mapea la cápsula con sus elementos ordenados', () async {
      acceso.filaLeida = fila;
      final capsula = await repositorio.obtenerCapsula('c1');

      expect(capsula?.estado, EstadoCapsula.programada);
      expect(capsula?.fechaApertura, DateTime.utc(2046, 8, 13, 13));
      expect(capsula?.elementos.map((e) => e.id), ['e1', 'e2']);
      expect(
        capsula?.elementos[1].duracion,
        const Duration(milliseconds: 92400),
      );
      expect(capsula?.elementos[1].nombre, 'Canción');
      expect(capsula?.elementos[1].fechaRecuerdo, DateTime(2026, 9, 30));
    });

    test('descarta filas corruptas al listar', () async {
      acceso.filaLeida = fila;
      final lista = await repositorio.listarMisCapsulas();
      expect(lista.map((c) => c.id), ['c1']);
    });
  });
}
