import 'package:capsoul/funcionalidades/autenticacion/aplicacion/proveedores_autenticacion.dart';
import 'package:capsoul/nucleo/firebase/escucha_tokens_push.dart';
import 'package:capsoul/nucleo/firebase/repositorio_dispositivos_push.dart';
import 'package:capsoul/nucleo/firebase/vinculo_token_push.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../ayudantes/falsos.dart';

/// Imita el repositorio real: no guarda nada si no hay sesión.
class RegistroQueRespetaSesion implements RegistroDispositivosPush {
  RegistroQueRespetaSesion(this.uidActual);

  final String? Function() uidActual;
  final guardados = <String>[];
  final borrados = <({String token, String? uid})>[];

  @override
  Future<void> registrarToken(String tokenFcm) async {
    if (uidActual() == null) return;
    guardados.add(tokenFcm);
  }

  @override
  Future<void> eliminarToken(String tokenFcm, {String? uid}) async {
    borrados.add((token: tokenFcm, uid: uid ?? uidActual()));
  }
}

void main() {
  test('el token recibido sin sesión se registra al entrar', () async {
    String? uid;
    final registros = <String>[];
    final vinculo = VinculoTokenPush(
      registrar: (token) async {
        if (uid == null) return;
        registros.add(token);
      },
      eliminar: (token, uidBorrado) async {},
    );

    await vinculo.recordarToken('token-fcm');
    expect(vinculo.tokenRecordado, 'token-fcm');
    expect(registros, isEmpty);

    uid = 'uid-123';
    await vinculo.alCambiarSesion(uidAnterior: null, uidNuevo: uid);
    expect(registros, ['token-fcm']);
  });

  test(
    'la misma sesión no repite el registro y salir borra el token',
    () async {
      final registros = <String>[];
      final borrados = <({String token, String uid})>[];
      final vinculo = VinculoTokenPush(
        registrar: (token) async => registros.add(token),
        eliminar: (token, uid) async => borrados.add((token: token, uid: uid)),
      );

      await vinculo.recordarToken('token-fcm');
      registros.clear();
      await vinculo.alCambiarSesion(
        uidAnterior: 'uid-123',
        uidNuevo: 'uid-123',
      );
      expect(registros, isEmpty);
      expect(borrados, isEmpty);

      await vinculo.alCambiarSesion(uidAnterior: 'uid-123', uidNuevo: null);
      expect(borrados, [(token: 'token-fcm', uid: 'uid-123')]);
    },
  );

  test('un token vacío no se recuerda', () async {
    final vinculo = VinculoTokenPush(
      registrar: (token) async => fail('no debía registrar'),
      eliminar: (token, uid) async => fail('no debía borrar'),
    );
    await vinculo.recordarToken('');
    expect(vinculo.tokenRecordado, isNull);
  });

  testWidgets('registra el token al iniciar sesión después del arranque', (
    tester,
  ) async {
    final auth = RepositorioAutenticacionFalso();
    final registro = RegistroQueRespetaSesion(() => auth.usuarioActual?.uid);
    var inicios = 0;

    await tester.pumpWidget(
      _escucha(auth: auth, registro: registro, alIniciar: () => inicios++),
    );
    await tester.pump();

    expect(inicios, 1);
    expect(registro.guardados, isEmpty);

    await auth.iniciarSesion(correo: 'ana@capsoul.app', contrasena: 'secreta');
    await tester.pump();

    expect(registro.guardados, ['token-fcm']);
    expect(inicios, 1);
  });

  testWidgets('con sesión desde el arranque guarda el token una sola vez', (
    tester,
  ) async {
    final auth = RepositorioAutenticacionFalso(usuarioInicial: usuarioPrueba);
    final registro = RegistroQueRespetaSesion(() => auth.usuarioActual?.uid);
    var inicios = 0;

    await tester.pumpWidget(
      _escucha(auth: auth, registro: registro, alIniciar: () => inicios++),
    );
    await tester.pump();

    expect(registro.guardados, ['token-fcm']);
    expect(inicios, 1);

    await tester.pumpWidget(
      _escucha(auth: auth, registro: registro, alIniciar: () => inicios++),
    );
    await tester.pump();
    expect(inicios, 1);
    expect(registro.guardados, ['token-fcm']);
  });

  testWidgets('al cerrar sesión borra el token con el uid anterior', (
    tester,
  ) async {
    final auth = RepositorioAutenticacionFalso(usuarioInicial: usuarioPrueba);
    final registro = RegistroQueRespetaSesion(() => auth.usuarioActual?.uid);

    await tester.pumpWidget(_escucha(auth: auth, registro: registro));
    await tester.pump();
    expect(registro.guardados, ['token-fcm']);

    await auth.cerrarSesion();
    await tester.pump();

    expect(registro.borrados, [(token: 'token-fcm', uid: usuarioPrueba.uid)]);
    expect(auth.usuarioActual, isNull);

    registro.guardados.clear();
    await auth.iniciarSesion(correo: 'ana@capsoul.app', contrasena: 'secreta');
    await tester.pump();
    expect(registro.guardados, ['token-fcm']);
  });

  testWidgets('recargar la sesión no borra el token ni reinicia FCM', (
    tester,
  ) async {
    final auth = RepositorioAutenticacionFalso(usuarioInicial: usuarioPrueba);
    final registro = RegistroQueRespetaSesion(() => auth.usuarioActual?.uid);
    var inicios = 0;
    final contenedor = ProviderContainer(
      overrides: [
        proveedorRepositorioAutenticacion.overrideWithValue(auth),
        proveedorRepositorioDispositivosPush.overrideWithValue(registro),
      ],
    );
    addTearDown(contenedor.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: contenedor,
        child: EscuchaTokensPush(
          iniciador: ({required alRegistrarToken, required alAbrirRuta}) async {
            inicios++;
            await alRegistrarToken('token-fcm');
            return null;
          },
          child: const SizedBox.shrink(),
        ),
      ),
    );
    await tester.pump();
    expect(registro.guardados, ['token-fcm']);

    contenedor.invalidate(proveedorEstadoAutenticacion);
    await tester.pump();
    await tester.pump();

    expect(registro.borrados, isEmpty);
    expect(registro.guardados, ['token-fcm']);
    expect(inicios, 1);
  });
}

Widget _escucha({
  required RepositorioAutenticacionFalso auth,
  required RegistroQueRespetaSesion registro,
  void Function()? alIniciar,
}) {
  return ProviderScope(
    overrides: [
      proveedorRepositorioAutenticacion.overrideWithValue(auth),
      proveedorRepositorioDispositivosPush.overrideWithValue(registro),
    ],
    child: EscuchaTokensPush(
      iniciador: ({required alRegistrarToken, required alAbrirRuta}) async {
        alIniciar?.call();
        await alRegistrarToken('token-fcm');
        return null;
      },
      child: const SizedBox.shrink(),
    ),
  );
}
