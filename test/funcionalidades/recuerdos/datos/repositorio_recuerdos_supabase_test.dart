import 'package:capsoul/funcionalidades/elementos/dominio/elemento_borrador.dart';
import 'package:capsoul/funcionalidades/elementos/dominio/fallo_medios.dart';
import 'package:capsoul/funcionalidades/elementos/dominio/tipo_elemento.dart';
import 'package:capsoul/funcionalidades/recuerdos/datos/acceso_tablas_recuerdos.dart';
import 'package:capsoul/funcionalidades/recuerdos/datos/mapeo_recuerdos.dart';
import 'package:capsoul/funcionalidades/recuerdos/datos/repositorio_recuerdos_supabase.dart';
import 'package:capsoul/funcionalidades/recuerdos/dominio/fallo_recuerdo.dart';
import 'package:capsoul/funcionalidades/recuerdos/dominio/filtro_recuerdos.dart';
import 'package:capsoul/funcionalidades/recuerdos/dominio/nuevo_recuerdo.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../ayudantes/falsos_capsulas.dart';

class _AccesoFalso implements AccesoTablasRecuerdos {
  final List<Map<String, dynamic>> insertadas = [];
  Map<String, Object?> ultimoListado = {};
  List<Map<String, dynamic>> filas = [];
  int borradas = 1;
  Object? falloAlInsertar;
  Object? falloAlBorrar;

  @override
  Future<void> insertar(Map<String, dynamic> fila) async {
    final fallo = falloAlInsertar;
    if (fallo != null) throw fallo;
    insertadas.add(fila);
  }

  @override
  Future<List<Map<String, dynamic>>> listar({
    required String propietarioId,
    List<String> tipos = const [],
    String? desde,
    String? hasta,
    int limite = 200,
  }) async {
    ultimoListado = {
      'propietario': propietarioId,
      'tipos': tipos,
      'desde': desde,
      'hasta': hasta,
    };
    return filas;
  }

  @override
  Future<Map<String, dynamic>?> leerPorId(String id) async =>
      filas.isEmpty ? null : filas.first;

  @override
  Future<int> contarCapsulasSelladas(String id) async => 2;

  @override
  Future<int> eliminar(String id) async {
    final fallo = falloAlBorrar;
    if (fallo != null) throw fallo;
    return borradas;
  }

  @override
  Future<Map<String, dynamic>?> leerUsoMedios() async =>
      {'bytes_usados': 2048, 'bytes_limite': 4096};
}

void main() {
  final ahora = DateTime(2026, 10, 3, 10);
  late _AccesoFalso acceso;
  late RepositorioMediosFalso medios;
  late RepositorioRecuerdosSupabase repositorio;

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

  setUp(() {
    acceso = _AccesoFalso();
    medios = RepositorioMediosFalso();
    repositorio = RepositorioRecuerdosSupabase(
      acceso: acceso,
      medios: medios,
      uidActual: () => 'uid-123',
      reloj: () => ahora,
      generarId: () => 'id-1',
    );
  });

  test('guarda una nota sin subir nada y con id del cliente', () async {
    final recuerdo = await repositorio.crear(
      NuevoRecuerdo(
        elemento: nota,
        fechaRecuerdo: DateTime(2026, 9, 1),
        titulo: '  ',
      ),
    );

    expect(medios.subidos, isEmpty);
    expect(acceso.insertadas.single, {
      'id': 'id-1',
      'propietario_id': 'uid-123',
      'tipo': 'texto',
      'titulo': null,
      'fecha_recuerdo': '2026-09-01',
      'contenido_texto': 'Te quiero',
    });
    expect(recuerdo.id, 'id-1');
    expect(recuerdo.fechaRecuerdo, DateTime(2026, 9, 1));
    expect(recuerdo.nombre, 'Te quiero');
  });

  test('sube la foto y guarda sus datos con el título recortado', () async {
    final recuerdo = await repositorio.crear(
      NuevoRecuerdo(elemento: foto, fechaRecuerdo: ahora, titulo: ' Playa '),
    );

    final fila = acceso.insertadas.single;
    expect(medios.subidos, [foto]);
    expect(fila['cloudinary_public_id'], 'capsoul/aleatorio-1');
    expect(fila['titulo'], 'Playa');
    expect(fila['fecha_recuerdo'], '2026-10-03');
    expect(fila['duracion_segundos'], isNull);
    expect(recuerdo.publicId, 'capsoul/aleatorio-1');
  });

  test('valida antes de subir', () async {
    await expectLater(
      repositorio.crear(
        NuevoRecuerdo(elemento: foto, fechaRecuerdo: DateTime(2026, 10, 4)),
      ),
      throwsA(isA<FalloRecuerdo>().having(
          (f) => f.codigo, 'codigo', FalloRecuerdo.codigoFechaInvalida)),
    );
    expect(medios.subidos, isEmpty);
  });

  test('traduce cuota, CAP03, RLS y sesión', () async {
    acceso.falloAlInsertar = const PostgrestException(
      message: 'cuota',
      code: 'CAP01',
    );
    await expectLater(
      repositorio.crear(NuevoRecuerdo(elemento: nota, fechaRecuerdo: ahora)),
      throwsA(isA<FalloMedios>()),
    );

    acceso.falloAlBorrar = const PostgrestException(
      message: 'en capsula',
      code: 'CAP03',
    );
    await expectLater(
      repositorio.eliminar('x'),
      throwsA(isA<FalloRecuerdo>().having((f) => f.codigo, 'codigo',
          FalloRecuerdo.codigoEnCapsulaSellada)),
    );

    expect(
      RepositorioRecuerdosSupabase.traducirError(
        const PostgrestException(message: 'rls', code: '42501'),
      ),
      const FalloRecuerdo.permisoDenegado(),
    );
    expect(
      RepositorioRecuerdosSupabase.traducirError(
        const PostgrestException(message: 'jwt', code: 'PGRST303'),
      ),
      const FalloRecuerdo.sesionVencida(),
    );
  });

  test('borrar 0 filas es permiso denegado', () async {
    acceso.borradas = 0;
    await expectLater(
      repositorio.eliminar('x'),
      throwsA(const FalloRecuerdo.permisoDenegado()),
    );
  });

  test('lista con filtros como fechas de BD y descarta filas rotas', () async {
    acceso.filas = [
      {
        'id': 'e1',
        'propietario_id': 'uid-123',
        'tipo': 'audio',
        'fecha_recuerdo': '2026-09-30',
        'creado_en': '2026-10-01T02:00:00Z',
        'duracion_segundos': '12.5',
      },
      {'id': 'rota'},
    ];
    final lista = await repositorio.listar(
      FiltroRecuerdos(
        tipos: const {TipoElemento.video, TipoElemento.audio},
        desde: DateTime(2026, 9, 27),
        hasta: DateTime(2026, 10, 3),
      ),
    );

    expect(acceso.ultimoListado, {
      'propietario': 'uid-123',
      'tipos': ['audio', 'video'],
      'desde': '2026-09-27',
      'hasta': '2026-10-03',
    });
    expect(lista.single.duracion, const Duration(milliseconds: 12500));
    expect(lista.single.fechaRecuerdo, DateTime(2026, 9, 30));
  });

  test('sin sesión falla sin tocar la base', () async {
    final sinSesion = RepositorioRecuerdosSupabase(
      acceso: acceso,
      medios: medios,
      uidActual: () => null,
    );
    await expectLater(
      sinSesion.listar(FiltroRecuerdos.todos),
      throwsA(const FalloRecuerdo.sinSesion()),
    );
  });

  test('lee el uso de medios y cuenta cápsulas selladas', () async {
    final uso = await repositorio.leerUsoMedios();
    expect(uso.bytesUsados, 2048);
    expect(uso.fraccion, 0.5);
    expect(await repositorio.contarCapsulasSelladas('x'), 2);
  });

  test('mapeo: fecha para BD y fecha por defecto desde creado_en', () {
    expect(fechaParaBd(DateTime(987, 1, 2)), '0987-01-02');
    final recuerdo = recuerdoDesdeFila({
      'id': 'a',
      'propietario_id': 'u',
      'tipo': 'foto',
      'creado_en': '2026-10-03T12:00:00Z',
    });
    expect(recuerdo?.fechaRecuerdo, DateTime(2026, 10, 3));
    expect(recuerdoDesdeFila({'id': 'a', 'tipo': 'otro'}), isNull);
  });
}
