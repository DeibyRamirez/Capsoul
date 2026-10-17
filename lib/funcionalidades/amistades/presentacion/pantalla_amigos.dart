import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:go_router/go_router.dart';



import '../../../nucleo/componentes/avatar_usuario.dart';

import '../../../nucleo/componentes/avisos_emergentes.dart';

import '../../../nucleo/componentes/boton_principal.dart';

import '../../../nucleo/componentes/encabezado_seccion_capsoul.dart';

import '../../../nucleo/componentes/pantalla_capsoul.dart';

import '../../../nucleo/dominio/validador_nombre_usuario.dart';

import '../../../nucleo/errores/fallo_app.dart';

import '../../../nucleo/tema/colores_app.dart';

import '../aplicacion/proveedores_amistades.dart';

import '../dominio/usuario_resuelto.dart';



/// Amigos aceptados, solicitudes pendientes y búsqueda exacta por @.

class PantallaAmigos extends ConsumerStatefulWidget {

  const PantallaAmigos({super.key});



  @override

  ConsumerState<PantallaAmigos> createState() => _EstadoPantallaAmigos();

}



class _EstadoPantallaAmigos extends ConsumerState<PantallaAmigos> {

  final _controladorBusqueda = TextEditingController();

  UsuarioResuelto? _encontrado;

  var _buscando = false;

  var _enviando = false;



  @override

  void dispose() {

    _controladorBusqueda.dispose();

    super.dispose();

  }



  Future<void> _refrescar() async {

    ref.invalidate(proveedorMisAmigos);

    ref.invalidate(proveedorSolicitudesAmistad);

    await Future.wait([

      ref.read(proveedorMisAmigos.future),

      ref.read(proveedorSolicitudesAmistad.future),

    ]);

  }



  Future<void> _buscar() async {

    final error = ValidadorNombreUsuario.validar(_controladorBusqueda.text);

    if (error != null) {

      mostrarAvisoError(context, error);

      return;

    }

    setState(() {

      _buscando = true;

      _encontrado = null;

    });

    try {

      final arroba = ValidadorNombreUsuario.normalizar(_controladorBusqueda.text);

      final usuario =

          await ref.read(proveedorRepositorioAmistades).resolverPorArroba(arroba);

      if (!mounted) return;

      setState(() => _encontrado = usuario);

      if (usuario == null) {

        mostrarAvisoInformativo(context, 'No hay ningún usuario con ese @.');

      }

    } catch (error) {

      if (mounted) mostrarAvisoError(context, error);

    } finally {

      if (mounted) setState(() => _buscando = false);

    }

  }



  Future<void> _enviarSolicitud(UsuarioResuelto usuario) async {

    setState(() => _enviando = true);

    try {

      await ref

          .read(proveedorRepositorioAmistades)

          .enviarSolicitudAmistad(usuario.usuarioId);

      if (!mounted) return;

      mostrarAvisoInformativo(

        context,

        'Solicitud enviada a ${usuario.nombreVisible}.',

      );

      setState(() => _encontrado = null);

      _controladorBusqueda.clear();

    } catch (error) {

      if (mounted) mostrarAvisoError(context, error);

    } finally {

      if (mounted) setState(() => _enviando = false);

    }

  }



  @override

  Widget build(BuildContext context) {

    final amigos = ref.watch(proveedorMisAmigos);

    final solicitudes = ref.watch(proveedorSolicitudesAmistad);

    return PantallaCapsoul(

      cuerpo: RefreshIndicator(

        onRefresh: _refrescar,

        child: CustomScrollView(

          physics: const AlwaysScrollableScrollPhysics(),

          slivers: [

            SliverToBoxAdapter(

              child: Align(

                alignment: Alignment.centerLeft,

                child: IconButton(

                  tooltip: 'Volver',

                  onPressed: () => context.pop(),

                  icon: const Icon(Icons.arrow_back),

                  color: ColoresApp.primario,

                ),

              ),

            ),

            const SliverToBoxAdapter(

              child: EncabezadoSeccionCapsoul(

                titulo: 'Amigos',

                subtitulo: 'Tu círculo en Capsoul.',

                icono: Icons.people_outline,

                padding: EdgeInsets.fromLTRB(16, 0, 16, 4),

              ),

            ),

            SliverToBoxAdapter(

              child: Padding(

                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),

                child: Column(

                  crossAxisAlignment: CrossAxisAlignment.stretch,

                  children: [

                    const _Titulo('Agregar amigo'),

                    const Text(

                      'Busca el usuario exacto (por ejemplo @cheiviz). '

                      'La otra persona debe aceptar tu solicitud.',

                      style: TextStyle(color: ColoresApp.atenuado, fontSize: 13),

                    ),

                    const SizedBox(height: 12),

                    TextField(

                      key: const Key('campo-buscar-arroba'),

                      controller: _controladorBusqueda,

                      decoration: const InputDecoration(

                        labelText: 'Usuario',

                        prefixText: '@',

                      ),

                      autocorrect: false,

                      textInputAction: TextInputAction.search,

                      onSubmitted: (_) => _buscar(),

                    ),

                    const SizedBox(height: 8),

                    BotonPrincipal(

                      key: const Key('boton-buscar-arroba'),

                      etiqueta: 'Buscar',

                      cargando: _buscando,

                      alPresionar: _buscar,

                    ),

                    if (_encontrado != null) ...[

                      const SizedBox(height: 16),

                      Card(

                        child: Padding(

                          padding: const EdgeInsets.all(16),

                          child: Column(

                            crossAxisAlignment: CrossAxisAlignment.stretch,

                            children: [

                              Text(

                                _encontrado!.nombreVisible,

                                style: Theme.of(context).textTheme.titleMedium,

                              ),

                              const SizedBox(height: 4),

                              Text(

                                '@${ValidadorNombreUsuario.normalizar(_controladorBusqueda.text)}',

                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(

                                      color: ColoresApp.atenuado,

                                    ),

                              ),

                              const SizedBox(height: 12),

                              BotonPrincipal(

                                key: const Key('boton-enviar-solicitud'),

                                etiqueta: 'Solicitar',

                                cargando: _enviando,

                                alPresionar: () => _enviarSolicitud(_encontrado!),

                              ),

                            ],

                          ),

                        ),

                      ),

                    ],

                  ],

                ),

              ),

            ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),

            SliverToBoxAdapter(

              child: Padding(

                padding: const EdgeInsets.symmetric(horizontal: 16),

                child: Column(

                  crossAxisAlignment: CrossAxisAlignment.stretch,

                  children: [

                    const _Titulo('Solicitudes pendientes'),

                    solicitudes.when(

                      loading: () => const LinearProgressIndicator(),

                      error: (e, _) => Text(mensajeParaUsuario(e)),

                      data: (lista) => lista.isEmpty

                          ? const Text(

                              'No tienes solicitudes nuevas.',

                              style: TextStyle(color: ColoresApp.atenuado),

                            )

                          : Column(

                              children: [

                                for (final s in lista)

                                  Card(

                                    child: ListTile(

                                      leading: AvatarUsuario(

                                        usuarioId: s.solicitanteId,

                                        nombreVisible: s.solicitanteNombre,

                                        fotoPublicId: s.solicitanteFotoPublicId,

                                        radius: 20,

                                      ),

                                      title: Text(s.solicitanteNombre),

                                      subtitle: const Text('Quiere ser tu amigo'),

                                      trailing: Row(

                                        mainAxisSize: MainAxisSize.min,

                                        children: [

                                          IconButton(

                                            tooltip: 'Rechazar',

                                            onPressed: () async {

                                              await ref

                                                  .read(proveedorRepositorioAmistades)

                                                  .rechazarSolicitud(s.id);

                                              ref.invalidate(proveedorSolicitudesAmistad);

                                            },

                                            icon: const Icon(Icons.close),

                                          ),

                                          IconButton(

                                            tooltip: 'Aceptar',

                                            onPressed: () async {

                                              await ref

                                                  .read(proveedorRepositorioAmistades)

                                                  .aceptarSolicitud(s.id);

                                              ref.invalidate(proveedorSolicitudesAmistad);

                                              ref.invalidate(proveedorMisAmigos);

                                            },

                                            icon: const Icon(Icons.check),

                                          ),

                                        ],

                                      ),

                                    ),

                                  ),

                              ],

                            ),

                    ),

                  ],

                ),

              ),

            ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),

            SliverToBoxAdapter(

              child: Padding(

                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),

                child: Column(

                  crossAxisAlignment: CrossAxisAlignment.stretch,

                  children: [

                    const _Titulo('Tus amigos'),

                    amigos.when(

                      loading: () => const Center(child: CircularProgressIndicator()),

                      error: (e, _) => Text(mensajeParaUsuario(e)),

                      data: (lista) => lista.isEmpty

                          ? const Text(

                              'Aún no tienes amigos. Busca a alguien por @ arriba.',

                              style: TextStyle(color: ColoresApp.atenuado),

                            )

                          : Column(

                              children: [

                                for (final amigo in lista)

                                  ListTile(

                                    leading: AvatarUsuario(

                                      usuarioId: amigo.usuarioId,

                                      nombreVisible: amigo.nombreVisible,

                                      fotoPublicId: amigo.fotoPublicId,

                                      radius: 20,

                                    ),

                                    title: Text(amigo.nombreVisible),

                                    subtitle: Text(amigo.etiquetaArroba),

                                  ),

                              ],

                            ),

                    ),

                  ],

                ),

              ),

            ),

          ],

        ),

      ),

    );

  }

}



class _Titulo extends StatelessWidget {

  const _Titulo(this.texto);

  final String texto;



  @override

  Widget build(BuildContext context) {

    return Padding(

      padding: const EdgeInsets.only(bottom: 8),

      child: Text(

        texto,

        style: Theme.of(context).textTheme.titleMedium?.copyWith(

              fontWeight: FontWeight.w600,

            ),

      ),

    );

  }

}


