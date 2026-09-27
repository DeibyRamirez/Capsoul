import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../funcionalidades/autenticacion/aplicacion/proveedores_autenticacion.dart';
import '../../funcionalidades/autenticacion/dominio/usuario_app.dart';
import '../../funcionalidades/autenticacion/presentacion/pantalla_iniciar_sesion.dart';
import '../../funcionalidades/autenticacion/presentacion/pantalla_recuperar_contrasena.dart';
import '../../funcionalidades/autenticacion/presentacion/pantalla_registro.dart';
import '../../funcionalidades/crear/presentacion/pantalla_selector_crear.dart';
import '../../funcionalidades/inicio/presentacion/pantalla_inicio.dart';
import '../../funcionalidades/legado/presentacion/pantalla_legado.dart';
import '../../funcionalidades/momentos/presentacion/pantalla_momentos.dart';
import '../../funcionalidades/navegacion/presentacion/contenedor_navegacion.dart';
import '../../funcionalidades/perfil/presentacion/pantalla_perfil.dart';
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
}) {
  final claveNavegadorRaiz = GlobalKey<NavigatorState>();

  return GoRouter(
    navigatorKey: claveNavegadorRaiz,
    initialLocation: RutasApp.inicio,
    refreshListenable: notificadorRefresco,
    redirect: (context, state) => resolverRedireccionAutenticacion(
      sesionIniciada: haySesion(),
      ubicacion: state.matchedLocation,
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
            path: 'video',
            name: 'crear-video',
            builder: (context, state) =>
                const PantallaMarcadorCrear(modalidad: 'Video'),
          ),
          GoRoute(
            path: 'audio',
            name: 'crear-audio',
            builder: (context, state) =>
                const PantallaMarcadorCrear(modalidad: 'Audio'),
          ),
          GoRoute(
            path: 'escribir',
            name: 'crear-escribir',
            builder: (context, state) =>
                const PantallaMarcadorCrear(modalidad: 'Escribir'),
          ),
          GoRoute(
            path: 'foto',
            name: 'crear-foto',
            builder: (context, state) =>
                const PantallaMarcadorCrear(modalidad: 'Foto'),
          ),
        ],
      ),
    ],
  );
}
