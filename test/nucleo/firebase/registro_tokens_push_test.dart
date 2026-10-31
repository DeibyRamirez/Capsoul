import 'package:capsoul/funcionalidades/autenticacion/aplicacion/proveedores_autenticacion.dart';
import 'package:capsoul/funcionalidades/perfil/aplicacion/controlador_perfil.dart';
import 'package:capsoul/nucleo/firebase/escucha_tokens_push.dart';
import 'package:capsoul/nucleo/firebase/reintento_token_apns.dart';
import 'package:capsoul/nucleo/firebase/repositorio_dispositivos_push.dart';
import 'package:capsoul/nucleo/firebase/token_push_actual.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../ayudantes/falsos.dart';

/// Guarda las llamadas RPC con sus parámetros.
class _ClienteQueAnotaRpc extends ClientePostgrestFalso {
  final llamadas = <(String, Map<String, dynamic>?)>[];

  @override
  Future<List<dynamic>> rpc(
    String nombre, {
    Map<String, dynamic>? parametros,
  }) async {
    llamadas.add((nombre, parametros));
    return const [];
  }
}

void main() {
  group('RepositorioDispositivosPush', () {
    test('registra el token con la RPC security definer', () async {
      final cliente = _ClienteQueAnotaRpc();
      final repo = RepositorioDispositivosPush(
        cliente,
        uidActual: () => 'uid-1',
        plataforma: () => 'ios',
      );
      await repo.registrarToken('token-1');
      expect(cliente.llamadas, hasLength(1));
      expect(cliente.llamadas.single.$1, 'registrar_dispositivo_push');
      expect(cliente.llamadas.single.$2, {
        'p_token': 'token-1',
        'p_plataforma': 'ios',
      });
      expect(cliente.tablas['dispositivos_push'], isNull);
    });

    test('sin sesión, sin plataforma o con token vacío no llama', () async {
      final cliente = _ClienteQueAnotaRpc();
      await RepositorioDispositivosPush(
        cliente,
        uidActual: () => null,
        plataforma: () => 'android',
      ).registrarToken('t');
      await RepositorioDispositivosPush(
        cliente,
        uidActual: () => 'uid',
        plataforma: () => null,
      ).registrarToken('t');
      await RepositorioDispositivosPush(
        cliente,
        uidActual: () => 'uid',
        plataforma: () => 'android',
      ).registrarToken('');
      expect(cliente.llamadas, isEmpty);
    });
  });

  group('esperarConReintentos', () {
    test('reintenta hasta que llega el token APNs', () async {
      var lecturas = 0;
      final esperas = <Duration>[];
      final valor = await esperarConReintentos(() async {
        lecturas++;
        if (lecturas == 1) throw StateError('apns-token-not-set');
        return lecturas < 3 ? null : 'apns';
      }, dormir: (espera) async => esperas.add(espera));
      expect(valor, 'apns');
      expect(lecturas, 3);
      expect(esperas, esperasTokenApns.take(2).toList());
    });

    test('devuelve null si nunca llega', () async {
      var lecturas = 0;
      final valor = await esperarConReintentos(
        () async {
          lecturas++;
          return null;
        },
        esperas: const [Duration(seconds: 1), Duration(seconds: 2)],
        dormir: (_) async {},
      );
      expect(valor, isNull);
      expect(lecturas, 3);
    });
  });

  group('cerrar sesión', () {
    test('borra solo el token de este dispositivo', () async {
      final registro = RegistroDispositivosPushFalso();
      final contenedor = ProviderContainer(
        overrides: [
          proveedorRepositorioAutenticacion.overrideWithValue(
            RepositorioAutenticacionFalso(usuarioInicial: usuarioPrueba),
          ),
          proveedorRepositorioDispositivosPush.overrideWithValue(registro),
        ],
      );
      addTearDown(contenedor.dispose);
      final sub = contenedor.listen(proveedorControladorPerfil, (_, _) {});
      addTearDown(sub.close);

      contenedor.read(proveedorTokenPushActual.notifier).recordar('token-aqui');
      final ok = await contenedor
          .read(proveedorControladorPerfil.notifier)
          .cerrarSesion();

      expect(ok, isTrue);
      expect(registro.borrados, ['token-aqui']);
    });

    test('sin token conocido no borra nada y cierra igual', () async {
      final registro = RegistroDispositivosPushFalso();
      final contenedor = ProviderContainer(
        overrides: [
          proveedorRepositorioAutenticacion.overrideWithValue(
            RepositorioAutenticacionFalso(usuarioInicial: usuarioPrueba),
          ),
          proveedorRepositorioDispositivosPush.overrideWithValue(registro),
        ],
      );
      addTearDown(contenedor.dispose);
      final sub = contenedor.listen(proveedorControladorPerfil, (_, _) {});
      addTearDown(sub.close);

      final ok = await contenedor
          .read(proveedorControladorPerfil.notifier)
          .cerrarSesion();

      expect(ok, isTrue);
      expect(registro.borrados, isEmpty);
    });
  });
}
