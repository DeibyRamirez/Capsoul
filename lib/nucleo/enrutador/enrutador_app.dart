import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../funcionalidades/autenticacion/aplicacion/proveedores_autenticacion.dart';
import '../../funcionalidades/autenticacion/dominio/usuario_app.dart';
import '../../funcionalidades/autenticacion/presentacion/pantalla_bienvenida.dart';
import '../../funcionalidades/autenticacion/presentacion/pantalla_iniciar_sesion.dart';
import '../../funcionalidades/autenticacion/presentacion/pantalla_nueva_contrasena.dart';
import '../../funcionalidades/autenticacion/presentacion/pantalla_recuperar_contrasena.dart';
import '../../funcionalidades/autenticacion/presentacion/pantalla_registro.dart';
import '../../funcionalidades/autenticacion/presentacion/pantalla_revisa_tu_correo.dart';
import '../../funcionalidades/capsulas/presentacion/pantalla_crear_capsula.dart';
import '../../funcionalidades/capsulas/presentacion/pantalla_editar_capsula.dart';
import '../../funcionalidades/capsulas/presentacion/pantalla_detalle_capsula.dart';
import '../../funcionalidades/capsulas/presentacion/pantalla_capsulas_recibidas.dart';
import '../../funcionalidades/capsulas/presentacion/pantalla_mis_capsulas.dart';
import '../../funcionalidades/crear/presentacion/pantalla_selector_crear.dart';
import '../../funcionalidades/elementos/dominio/elemento_borrador.dart';
import '../../funcionalidades/elementos/presentacion/pantalla_capturar_foto.dart';
import '../../funcionalidades/elementos/presentacion/pantalla_capturar_video.dart';
import '../../funcionalidades/elementos/presentacion/pantalla_escribir_nota.dart';
import '../../funcionalidades/elementos/presentacion/pantalla_grabar_audio.dart';
import '../../funcionalidades/inicio/presentacion/pantalla_inicio.dart';
import '../../funcionalidades/legado/presentacion/pantalla_detalle_herencia.dart';
import '../../funcionalidades/legado/presentacion/pantalla_instrucciones_legado.dart';
import '../../funcionalidades/legado/presentacion/pantalla_legado.dart';
import '../../funcionalidades/legado/presentacion/pantalla_nueva_herencia.dart';
import '../../funcionalidades/legado/presentacion/pantalla_seguridad_legado.dart';
import '../../funcionalidades/momentos/presentacion/pantalla_detalle_momento.dart';
import '../../funcionalidades/momentos/presentacion/pantalla_editar_momento.dart';
import '../../funcionalidades/momentos/presentacion/pantalla_momentos.dart';
import '../../funcionalidades/momentos/presentacion/pantalla_nuevo_momento.dart';
import '../../funcionalidades/navegacion/presentacion/contenedor_navegacion.dart';
import '../../funcionalidades/amistades/presentacion/pantalla_amigos.dart';
import '../../funcionalidades/perfil/aplicacion/controlador_perfil.dart';
import '../../funcionalidades/perfil/presentacion/pantalla_perfil.dart';
import '../../funcionalidades/usuarios/presentacion/pantalla_elegir_nombre_usuario.dart';
import '../../funcionalidades/recuerdos/aplicacion/proveedores_recuerdos.dart';
import '../../funcionalidades/recuerdos/presentacion/pantalla_editar_recuerdo.dart';
import '../../funcionalidades/recuerdos/presentacion/pantalla_elegir_recuerdos.dart';
import '../../funcionalidades/recuerdos/presentacion/pantalla_guardar_recuerdo.dart';
import '../../funcionalidades/musica/presentacion/pantalla_buscar_musica.dart';
import '../../funcionalidades/recuerdos/presentacion/pantalla_recuerdos.dart';
import '../../funcionalidades/retos/presentacion/pantalla_retos.dart';
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
  ref.listen(proveedorPerfilUsuarioActual, (_, _) {
    notificadorRefresco.refrescar();
  });

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
    necesitaNombreUsuario: () {
      final perfil = ref.read(proveedorPerfilUsuarioActual).value;
      return perfil?.necesitaNombreUsuario ?? false;
    },
    perfilCargando: () => ref.read(proveedorPerfilUsuarioActual).isLoading,
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
  bool Function()? necesitaNombreUsuario,
  bool Function()? perfilCargando,
}) {
  final claveNavegadorRaiz = GlobalKey<NavigatorState>();

  return GoRouter(
    navigatorKey: claveNavegadorRaiz,
    initialLocation: RutasApp.inicio,
    refreshListenable: notificadorRefresco,
    redirect: (context, state) {
      final ubicacion = state.matchedLocation;
      final sesion = haySesion();
      final auth = resolverRedireccionAutenticacion(
        sesionIniciada: sesion,
        ubicacion: ubicacion,
        modoRecuperacion: enModoRecuperacion?.call() ?? false,
      );
      if (auth != null) return auth;
      return resolverRedireccionNombreUsuario(
        sesionIniciada: sesion,
        ubicacion: ubicacion,
        necesitaNombreUsuario: necesitaNombreUsuario?.call() ?? false,
        perfilCargando: perfilCargando?.call() ?? false,
      );
    },
    routes: [
      GoRoute(
        path: RutasApp.raiz,
        redirect: (context, state) => RutasApp.inicio,
      ),
      GoRoute(
        path: RutasApp.bienvenida,
        name: 'bienvenida',
        builder: (context, state) => const PantallaBienvenida(),
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
      GoRoute(
        path: RutasApp.elegirNombreUsuario,
        name: 'elegir-usuario',
        builder: (context, state) => const PantallaElegirNombreUsuario(),
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
                routes: [
                  // La ruta fija va antes de `:id`.
                  GoRoute(
                    path: 'nuevo',
                    name: 'nuevo-momento',
                    parentNavigatorKey: claveNavegadorRaiz,
                    builder: (context, state) => const PantallaNuevoMomento(),
                  ),
                  GoRoute(
                    path: ':id/editar',
                    name: 'editar-momento',
                    parentNavigatorKey: claveNavegadorRaiz,
                    builder: (context, state) => PantallaEditarMomento(
                      idMomento: state.pathParameters['id'] ?? '',
                    ),
                  ),
                  GoRoute(
                    path: ':id',
                    name: 'detalle-momento',
                    parentNavigatorKey: claveNavegadorRaiz,
                    builder: (context, state) => PantallaDetalleMomento(
                      idMomento: state.pathParameters['id'] ?? '',
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RutasApp.legado,
                name: 'legado',
                builder: (context, state) => const PantallaLegado(),
                routes: [
                  GoRoute(
                    path: 'nueva',
                    name: 'legado-nueva',
                    parentNavigatorKey: claveNavegadorRaiz,
                    builder: (context, state) => const PantallaNuevaHerencia(),
                  ),
                  GoRoute(
                    path: 'instrucciones',
                    name: 'legado-instrucciones',
                    parentNavigatorKey: claveNavegadorRaiz,
                    builder: (context, state) => const PantallaInstruccionesLegado(),
                  ),
                  GoRoute(
                    path: 'seguridad',
                    name: 'legado-seguridad',
                    parentNavigatorKey: claveNavegadorRaiz,
                    builder: (context, state) => const PantallaSeguridadLegado(),
                  ),
                  GoRoute(
                    path: 'herencia/:id',
                    name: 'legado-herencia-detalle',
                    parentNavigatorKey: claveNavegadorRaiz,
                    builder: (context, state) => PantallaDetalleHerencia(
                      herenciaId: state.pathParameters['id'] ?? '',
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RutasApp.yo,
                name: 'yo',
                builder: (context, state) => const PantallaPerfil(),
                routes: [
                  GoRoute(
                    path: 'amigos',
                    name: 'amigos',
                    parentNavigatorKey: claveNavegadorRaiz,
                    builder: (context, state) => const PantallaAmigos(),
                  ),
                ],
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
            builder: (context, state) => const PantallaCrearCapsula(),
          ),
          GoRoute(
            path: 'video',
            name: 'crear-video',
            parentNavigatorKey: claveNavegadorRaiz,
            builder: (context, state) => const PantallaCapturarVideo(),
          ),
          GoRoute(
            path: 'audio',
            name: 'crear-audio',
            parentNavigatorKey: claveNavegadorRaiz,
            builder: (context, state) => const PantallaGrabarAudio(),
          ),
          GoRoute(
            path: 'escribir',
            name: 'crear-escribir',
            parentNavigatorKey: claveNavegadorRaiz,
            builder: (context, state) => const PantallaEscribirNota(),
          ),
          GoRoute(
            path: 'foto',
            name: 'crear-foto',
            parentNavigatorKey: claveNavegadorRaiz,
            builder: (context, state) => const PantallaCapturarFoto(),
          ),
          GoRoute(
            path: 'musica',
            name: 'crear-musica',
            builder: (context, state) => const PantallaBuscarMusica(),
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
            path: 'recibidas',
            name: 'capsulas-recibidas',
            builder: (context, state) => const PantallaCapsulasRecibidas(),
          ),
          GoRoute(
            path: ':id',
            name: 'detalle-capsula',
            builder: (context, state) => PantallaDetalleCapsula(
              idCapsula: state.pathParameters['id'] ?? '',
            ),
            routes: [
              GoRoute(
                path: 'editar',
                name: 'editar-capsula',
                builder: (context, state) => PantallaEditarCapsula(
                  idCapsula: state.pathParameters['id'] ?? '',
                ),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: RutasApp.retos,
        name: 'retos',
        parentNavigatorKey: claveNavegadorRaiz,
        builder: (context, state) => const PantallaRetos(),
      ),
      GoRoute(
        path: RutasApp.recuerdos,
        name: 'recuerdos',
        parentNavigatorKey: claveNavegadorRaiz,
        builder: (context, state) => const PantallaRecuerdos(),
        routes: [
          // Las rutas fijas van antes de `:id`.
          GoRoute(
            path: 'elegir-musica',
            name: 'elegir-musica',
            builder: (context, state) =>
                const PantallaBuscarMusica(soloSeleccion: true),
          ),
          GoRoute(
            path: 'guardar',
            name: 'guardar-recuerdo',
            redirect: (context, state) {
              if (state.extra is ElementoBorrador) return null;
              final pendiente = ProviderScope.containerOf(
                context,
                listen: false,
              ).read(proveedorBorradorRecuerdoPendiente);
              if (pendiente != null) return null;
              return RutasApp.recuerdos;
            },
            builder: (context, state) {
              final container = ProviderScope.containerOf(context, listen: false);
              final elemento = borradorParaGuardarRecuerdo(
                extra: state.extra,
                pendiente: container.read(proveedorBorradorRecuerdoPendiente),
              );
              return PantallaGuardarRecuerdo(elemento: elemento!);
            },
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
            path: ':id/editar',
            name: 'editar-recuerdo',
            builder: (context, state) => PantallaEditarRecuerdo(
              idRecuerdo: state.pathParameters['id'] ?? '',
            ),
          ),
          GoRoute(
            path: ':id',
            name: 'detalle-recuerdo',
            redirect: (context, state) {
              final id = state.pathParameters['id'] ?? '';
              if (id.isEmpty) return RutasApp.recuerdos;
              return RutasApp.editarRecuerdoDe(id);
            },
          ),
        ],
      ),
    ],
  );
}
