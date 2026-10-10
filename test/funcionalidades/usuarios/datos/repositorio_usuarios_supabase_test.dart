import 'package:capsoul/funcionalidades/usuarios/datos/acceso_tabla_usuarios.dart';
import 'package:capsoul/funcionalidades/usuarios/datos/repositorio_usuarios_supabase.dart';
import 'package:capsoul/funcionalidades/usuarios/dominio/fallo_perfil_usuario.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:capsoul/nucleo/infraestructura/traductor_errores_backend.dart';

class _AccesoSimulado extends Mock implements AccesoTablaUsuarios {}

void main() {
  late _AccesoSimulado acceso;
  late RepositorioUsuariosSupabase repositorio;

  const filaAna = {
    'id': 'uid-1',
    'nombre_visible': 'Ana',
    'correo': 'ana@capsoul.app',
    'foto_public_id': null,
    'perfil_publico': false,
    'creado_en': '2026-10-02T15:30:00+00:00',
  };

  setUp(() {
    acceso = _AccesoSimulado();
    repositorio = RepositorioUsuariosSupabase(acceso);
  });

  tearDown(() => repositorio.liberarRecursos());

  Matcher lanzaFalloPerfil(String codigo) => throwsA(
        isA<FalloPerfilUsuario>()
            .having((fallo) => fallo.codigo, 'codigo', codigo),
      );

  test('observarPerfil lee las columnas en español de usuarios', () async {
    when(() => acceso.leerFila('uid-1')).thenAnswer((_) async => filaAna);

    final perfil = await repositorio.observarPerfil('uid-1').first;

    expect(perfil, isNotNull);
    expect(perfil!.uid, 'uid-1');
    expect(perfil.nombreVisible, 'Ana');
    expect(perfil.correo, 'ana@capsoul.app');
    expect(perfil.fotoPublicId, isNull);
    expect(perfil.perfilPublico, isFalse);
    expect(perfil.creadoEn, DateTime.utc(2026, 10, 2, 15, 30));
  });

  test('observarPerfil emite null si la fila no existe', () async {
    when(() => acceso.leerFila('nadie')).thenAnswer((_) async => null);

    expect(await repositorio.observarPerfil('nadie').first, isNull);
  });

  test('las filas mal formadas se tratan como inexistentes', () {
    expect(
      RepositorioUsuariosSupabase.desdeFila({'id': 'uid-1', 'nombre_visible': 42}),
      isNull,
    );
  });

  test('foto_public_id y perfil_publico se leen cuando vienen', () {
    final perfil = RepositorioUsuariosSupabase.desdeFila({
      ...filaAna,
      'foto_public_id': 'capsoul/usuarios/uid-1/avatar',
      'perfil_publico': true,
    });

    expect(perfil?.fotoPublicId, 'capsoul/usuarios/uid-1/avatar');
    expect(perfil?.perfilPublico, isTrue);
  });

  test('guardarNombreVisible actualiza y vuelve a emitir el perfil', () async {
    var nombre = 'Ana';
    when(() => acceso.leerFila('uid-1'))
        .thenAnswer((_) async => {...filaAna, 'nombre_visible': nombre});
    when(() => acceso.actualizarNombreVisible('uid-1', 'Ana María'))
        .thenAnswer((_) async {
      nombre = 'Ana María';
      return 1;
    });

    final emisiones = repositorio
        .observarPerfil('uid-1')
        .map((perfil) => perfil?.nombreVisible)
        .take(2)
        .toList();
    await Future<void>.delayed(Duration.zero);
    await repositorio.guardarNombreVisible(
      uid: 'uid-1',
      nombreVisible: 'Ana María',
    );

    expect(await emisiones, ['Ana', 'Ana María']);
  });

  test('guardarNombreVisible sin filas afectadas lanza no_encontrado', () {
    when(() => acceso.actualizarNombreVisible(any(), any()))
        .thenAnswer((_) async => 0);

    expect(
      () => repositorio.guardarNombreVisible(uid: 'uid-1', nombreVisible: 'X'),
      lanzaFalloPerfil(FalloPerfilUsuario.codigoNoEncontrado),
    );
  });

  test('un 42501 de Postgres se traduce a permiso_denegado', () {
    when(() => acceso.actualizarNombreVisible(any(), any())).thenThrow(
      const ErrorPostgrest(mensaje: 'permission denied', codigo: '42501'),
    );

    expect(
      () => repositorio.guardarNombreVisible(uid: 'uid-1', nombreVisible: 'X'),
      lanzaFalloPerfil(FalloPerfilUsuario.codigoPermisoDenegado),
    );
  });

  test('un CHECK violado se traduce a dato_invalido', () {
    when(() => acceso.actualizarNombreVisible(any(), any())).thenThrow(
      const ErrorPostgrest(mensaje: 'check violation', codigo: '23514'),
    );

    expect(
      () => repositorio.guardarNombreVisible(uid: 'uid-1', nombreVisible: ''),
      lanzaFalloPerfil(FalloPerfilUsuario.codigoDatoInvalido),
    );
  });

  test('los errores de lectura se emiten como FalloPerfilUsuario', () {
    when(() => acceso.leerFila(any())).thenThrow(StateError('fallo'));

    expect(
      repositorio.observarPerfil('uid-1'),
      emitsError(isA<FalloPerfilUsuario>()),
    );
  });
}
