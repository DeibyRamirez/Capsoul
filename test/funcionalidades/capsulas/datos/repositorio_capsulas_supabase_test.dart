import 'package:capsoul/funcionalidades/capsulas/datos/acceso_tablas_capsulas.dart';
import 'package:capsoul/funcionalidades/capsulas/datos/repositorio_capsulas_supabase.dart';
import 'package:capsoul/funcionalidades/capsulas/dominio/estado_capsula.dart';
import 'package:capsoul/funcionalidades/capsulas/dominio/fallo_capsula.dart';
import 'package:capsoul/funcionalidades/capsulas/dominio/nueva_capsula.dart';
import 'package:capsoul/funcionalidades/elementos/dominio/elemento_borrador.dart';
import 'package:capsoul/funcionalidades/elementos/dominio/fallo_medios.dart';
import 'package:capsoul/funcionalidades/elementos/dominio/tipo_elemento.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../ayudantes/falsos_capsulas.dart';

/// Base en memoria que registra cada operación.
class _AccesoFalso implements AccesoTablasCapsulas {
  final List<String> operaciones = [];
  final List<Map<String, dynamic>> elementos = [];
  final List<Map<String, dynamic>> capsulas = [];
  final List<Map<String, dynamic>> enlaces = [];
  final List<String> elementosBorrados = [];
  final List<String> capsulasBorradas = [];
  Object? falloEnEnlaces;
  Map<String, dynamic>? filaLeida;

  @override
  Future<String> insertarElemento(Map<String, dynamic> fila) async {
    operaciones.add('elemento');
    elementos.add(fila);
    return 'e${elementos.length}';
  }

  @override
  Future<String> insertarCapsula(Map<String, dynamic> fila) async {
    operaciones.add('capsula:${fila['estado']}');
    capsulas.add(fila);
    return 'c1';
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
  Future<void> eliminarElementos(List<String> ids) async =>
      elementosBorrados.addAll(ids);

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
  late RepositorioMediosFalso medios;
  late RepositorioCapsulasSupabase repositorio;

  const nota = ElementoBorrador(
    idLocal: 'n1',
    tipo: TipoElemento.texto,
    texto: 'Te quiero',
    bytes: 9,
  );
  const foto = ElementoBorrador(
    idLocal: 'f1',
    tipo: TipoElemento.foto,
    rutaArchivo: '/tmp/f.jpg',
    bytes: 1000,
    ancho: 1600,
    alto: 1200,
    formato: 'jpg',
  );

  NuevaCapsula nueva(List<ElementoBorrador> elementos) => NuevaCapsula(
        titulo: '  Para Jacobo ',
        mensaje: '  ',
        fechaApertura: DateTime.utc(2046, 8, 13, 13),
        elementos: elementos,
      );

  setUp(() {
    acceso = _AccesoFalso();
    medios = RepositorioMediosFalso();
    repositorio = RepositorioCapsulasSupabase(
      acceso: acceso,
      medios: medios,
      uidActual: () => 'uid-123',
      reloj: () => ahora,
    );
  });

  test('guarda elementos, cápsula en borrador, enlaces y la programa', () async {
    final progreso = <int>[];
    final id = await repositorio.crearCapsula(
      nueva([nota, foto]),
      alProgreso: (guardados, _) => progreso.add(guardados),
    );

    expect(id, 'c1');
    expect(acceso.operaciones, [
      'elemento',
      'elemento',
      'capsula:borrador',
      'enlaces',
      'estado:programada',
    ]);
    expect(progreso, [0, 1, 2]);
    expect(acceso.elementos[0], {
      'propietario_id': 'uid-123',
      'tipo': 'texto',
      'contenido_texto': 'Te quiero',
    });
    expect(acceso.elementos[1]['cloudinary_public_id'], 'capsoul/aleatorio-1');
    expect(acceso.elementos[1]['cloudinary_tipo_recurso'], 'image');
    expect(acceso.elementos[1]['bytes'], 1000);
    expect(acceso.capsulas.single['titulo'], 'Para Jacobo');
    expect(acceso.capsulas.single['mensaje'], isNull);
    expect(acceso.capsulas.single['fecha_apertura'], '2046-08-13T13:00:00.000Z');
    expect(acceso.enlaces, [
      {'capsula_id': 'c1', 'elemento_id': 'e1', 'orden': 0},
      {'capsula_id': 'c1', 'elemento_id': 'e2', 'orden': 1},
    ]);
    expect(medios.subidos, [foto]);
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
      medios: medios,
      uidActual: () => null,
      reloj: () => ahora,
    );
    await expectLater(
      sinSesion.crearCapsula(nueva([nota])),
      throwsA(isA<FalloCapsula>()),
    );
  });

  test('si la subida no está disponible, borra lo ya insertado', () async {
    medios.fallo = const FalloMedios.subidaNoDisponible();

    await expectLater(
      repositorio.crearCapsula(nueva([nota, foto])),
      throwsA(isA<FalloMedios>().having(
        (f) => f.codigo,
        'codigo',
        FalloMedios.codigoSubidaNoDisponible,
      )),
    );
    expect(acceso.capsulas, isEmpty);
    expect(acceso.elementosBorrados, ['e1']);
  });

  test('si falla un paso posterior, borra la cápsula y los elementos', () async {
    acceso.falloEnEnlaces = PostgrestException(
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
    expect(acceso.capsulasBorradas, ['c1']);
    expect(acceso.elementosBorrados, ['e1']);
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
            'tipo': 'audio',
            'cloudinary_public_id': 'p2',
            'bytes': 1000,
            'duracion_segundos': 92.4,
          },
        },
        {
          'orden': 0,
          'elementos': {'id': 'e1', 'tipo': 'texto', 'contenido_texto': 'Nota'},
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
    });

    test('descarta filas corruptas al listar', () async {
      acceso.filaLeida = fila;
      final lista = await repositorio.listarMisCapsulas();
      expect(lista.map((c) => c.id), ['c1']);
    });
  });
}
