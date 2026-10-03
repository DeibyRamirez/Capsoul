import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../funcionalidades/autenticacion/aplicacion/proveedores_autenticacion.dart';
import '../../funcionalidades/autenticacion/dominio/usuario_app.dart';
import '../../funcionalidades/autenticacion/presentacion/pantalla_iniciar_sesion.dart';
import '../../funcionalidades/autenticacion/presentacion/pantalla_nueva_contrasena.dart';
import '../../funcionalidades/autenticacion/presentacion/pantalla_recuperar_contrasena.dart';
import '../../funcionalidades/autenticacion/presentacion/pantalla_registro.dart';
import '../../funcionalidades/autenticacion/presentacion/pantalla_revisa_tu_correo.dart';
import '../../funcionalidades/capsulas/presentacion/pantalla_crear_capsula.dart';
import '../../funcionalidades/capsulas/presentacion/pantalla_detalle_capsula.dart';
import '../../funcionalidades/capsulas/presentacion/pantalla_mis_capsulas.dart';
import '../../funcionalidades/crear/presentacion/pantalla_selector_crear.dart';
import '../../funcionalidades/elementos/dominio/elemento_borrador.dart';
import '../../funcionalidades/elementos/presentacion/pantalla_capturar_foto.dart';
import '../../funcionalidades/elementos/presentacion/pantalla_capturar_video.dart';
import '../../funcionalidades/elementos/presentacion/pantalla_escribir_nota.dart';
import '../../funcionalidades/elementos/presentacion/pantalla_grabar_audio.dart';
import '../../funcionalidades/inicio/presentacion/pantalla_inicio.dart';
import '../../funcionalidades/legado/presentacion/pantalla_legado.dart';
import '../../funcionalidades/momentos/presentacion/pantalla_momentos.dart';
import '../../funcionalidades/navegacion/presentacion/contenedor_navegacion.dart';
import '../../funcionalidades/perfil/presentacion/pantalla_perfil.dart';
import '../../funcionalidades/recuerdos/presentacion/pantalla_detalle_recuerdo.dart';
import '../../funcionalidades/recuerdos/presentacion/pantalla_elegir_recuerdos.dart';
import '../../funcionalidades/recuerdos/presentacion/pantalla_guardar_recuerdo.dart';
import '../../funcionalidades/recuerdos/presentacion/pantalla_recuerdos.dart';
import 'rutas_app.dart';

/// Enrutador de la app conectado a la sesión. Reevalúa su redirección cada
/// vez que [proveedorEstadoAutenticacion] emite, así el contenedor principal
/// nunca se muestra sin sesión.
final proveedorEnrutadorApp = Provider<GoRouter>((ref) {
  final notificadorRefresco = _NotificadorRefrescoEnrutador();
  ref.onDispose(notificadorRefresco.dispose);
  ref.listen<AsyncValue<UsuarioApp?>>(
    proveedorEstadoAutenticacion,
    (_, _) => notificadorRefresco.refrescar(),
  );
  ref.listen<bool>(
    proveedorModoRecuperacion,
    (_, _) => notificadorRefresco.refrescar(),
  );

  bool haySesion() {
    final estado = ref.read(proveedorEstadoAutenticacion);
    final usuario = estado.hasValue
        ? estado.value
        : ref.read(proveedorRepositorioAutenticacion).usuarioActual;
    return usuario != null;
  }

  final enrutador = crearEnrutadorApp(
    notificadorRefresco: notificadorRefresco,
    haySesion: haySesion,
    enModoRecuperacion: () => ref.read(proveedorModoRecuperacion),
  );
  ref.onDispose(enrutador.dispose);
  return enrutador;
});

class _NotificadorRefrescoEnrutador extends ChangeNotifier {
  void refrescar() => notifyListeners();
}

GoRouter crearEnrutadorApp({
  required Listenable notificadorRefresco,
  required bool Function() haySesion,
  bool Function()? enModoRecuperacion,
}) {
  final claveNavegadorRaiz = GlobalKey<NavigatorState>();

  return GoRouter(
    navigatorKey: claveNavegadorRaiz,
    initialLocation: RutasApp.inicio,
    refreshListenable: notificadorRefresco,
    redirect: (context, state) => resolverRedireccionAutenticacion(
      sesionIniciada: haySesion(),
      ubicacion: state.matchedLocation,
      modoRecuperacion: enModoRecuperacion?.call() ?? false,
    ),
    routes: [
      GoRoute(
        path: RutasApp.raiz,
        redirect: (context, state) => RutasApp.inicio,
      ),
      GoRoute(
        path: RutasApp.iniciarSesion,
        name: 'iniciar-sesion',
        builder: (context, state) => const PantallaIniciarSesion(),
      ),
      GoRoute(
        path: RutasApp.registro,
        name: 'registro',
        builder: (context, state) => const PantallaRegistro(),
      ),
      GoRoute(
        path: RutasApp.recuperar,
        name: 'recuperar',
        builder: (context, state) => const PantallaRecuperarContrasena(),
      ),
      GoRoute(
        path: RutasApp.revisaTuCorreo,
        name: 'revisa-tu-correo',
        builder: (context, state) => PantallaRevisaTuCorreo(
          correo: state.uri.queryParameters['correo'] ?? '',
          reenviarAlEntrar: state.uri.queryParameters['reenviar'] == '1',
        ),
      ),
      GoRoute(
        path: RutasApp.nuevaContrasena,
        name: 'nueva-contrasena',
        builder: (context, state) => const PantallaNuevaContrasena(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navegacionRamas) {
          return ContenedorNavegacion(navegacionRamas: navegacionRamas);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RutasApp.inicio,
                name: 'inicio',
                builder: (context, state) => const PantallaInicio(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RutasApp.momentos,
                name: 'momentos',
                builder: (context, state) => const PantallaMomentos(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RutasApp.legado,
                name: 'legado',
                builder: (context, state) => const PantallaLegado(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RutasApp.yo,
                name: 'yo',
                builder: (context, state) => const PantallaPerfil(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: RutasApp.crear,
        name: 'crear',
        parentNavigatorKey: claveNavegadorRaiz,
        builder: (context, state) => const PantallaSelectorCrear(),
        routes: [
          GoRoute(
            path: 'capsula',
            name: 'crear-capsula',
            builder: (context, state) {
              final extra = state.extra;
              return PantallaCrearCapsula(
                elementoInicial: extra is ElementoBorrador ? extra : null,
              );
            },
          ),
          GoRoute(
            path: 'video',
            name: 'crear-video',
            builder: (context, state) => const PantallaCapturarVideo(),
          ),
          GoRoute(
            path: 'audio',
            name: 'crear-audio',
            builder: (context, state) => const PantallaGrabarAudio(),
          ),
          GoRoute(
            path: 'escribir',
            name: 'crear-escribir',
            builder: (context, state) => const PantallaEscribirNota(),
          ),
          GoRoute(
            path: 'foto',
            name: 'crear-foto',
            builder: (context, state) => const PantallaCapturarFoto(),
          ),
        ],
      ),
      GoRoute(
        path: RutasApp.capsulas,
        name: 'capsulas',
        parentNavigatorKey: claveNavegadorRaiz,
        builder: (context, state) => const PantallaMisCapsulas(),
        routes: [
          GoRoute(
            path: ':id',
            name: 'detalle-capsula',
            builder: (context, state) => PantallaDetalleCapsula(
              idCapsula: state.pathParameters['id'] ?? '',
            ),
          ),
        ],
      ),
      GoRoute(
        path: RutasApp.recuerdos,
        name: 'recuerdos',
        parentNavigatorKey: claveNavegadorRaiz,
        builder: (context, state) => const PantallaRecuerdos(),
        routes: [
          // Las rutas fijas van antes de `:id`.
          GoRoute(
            path: 'guardar',
            name: 'guardar-recuerdo',
            redirect: (context, state) =>
                state.extra is ElementoBorrador ? null : RutasApp.recuerdos,
            builder: (context, state) => PantallaGuardarRecuerdo(
              elemento: state.extra! as ElementoBorrador,
            ),
          ),
          GoRoute(
            path: 'elegir',
            name: 'elegir-recuerdos',
            builder: (context, state) {
              final extra = state.extra;
              return PantallaElegirRecuerdos(
                parametros: extra is ParametrosElegirRecuerdos
                    ? extra
                    : const ParametrosElegirRecuerdos(),
              );
            },
          ),
          GoRoute(
            path: ':id',
            name: 'detalle-recuerdo',
            builder: (context, state) => PantallaDetalleRecuerdo(
              idRecuerdo: state.pathParameters['id'] ?? '',
            ),
          ),
        ],
      ),
    ],
  );
}
