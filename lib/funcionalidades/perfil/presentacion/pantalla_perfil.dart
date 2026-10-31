import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../nucleo/componentes/avisos_emergentes.dart';
import '../../../nucleo/componentes/pantalla_capsoul.dart';
import '../../../nucleo/enrutador/rutas_app.dart';
import '../../../nucleo/tema/colores_app.dart';
import '../../../nucleo/tema/tema_app.dart';
import '../../amistades/aplicacion/proveedores_amistades.dart';
import '../../autenticacion/aplicacion/proveedores_autenticacion.dart';
import '../../autenticacion/presentacion/validadores_autenticacion.dart';
import '../../crear/presentacion/componentes/hoja_opciones_crear.dart';
import '../../inicio/aplicacion/proveedores_inicio.dart';
import '../../inicio/dominio/resumen_inicio.dart';
import '../../elementos/dominio/elemento_borrador.dart';
import '../../recuerdos/aplicacion/proveedores_recuerdos.dart';
import '../../recuerdos/dominio/filtro_recuerdos.dart';
import '../aplicacion/controlador_perfil.dart';
import '../aplicacion/proveedor_avatar_perfil.dart';
import 'componentes/encabezado_perfil.dart';
import 'componentes/fila_avatares_amigos.dart';
import 'componentes/rejilla_elementos_perfil.dart';

/// Pestaña "Yo": perfil con cabecera estilo Instagram y rejilla de recuerdos.
class PantallaPerfil extends ConsumerWidget {
  const PantallaPerfil({super.key});

  Future<void> _cambiarFoto(BuildContext context, WidgetRef ref) async {
    final origen = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (contexto) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Tomar foto'),
              onTap: () => Navigator.pop(contexto, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Elegir de la galería'),
              onTap: () => Navigator.pop(contexto, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (origen == null || !context.mounted) return;
    String? ruta;
    if (origen == ImageSource.camera) {
      final borrador =
          await context.push<ElementoBorrador>(RutasApp.crearFoto);
      ruta = borrador?.rutaArchivo;
    } else {
      final picker = ImagePicker();
      final archivo = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 2048,
        imageQuality: 90,
      );
      ruta = archivo?.path;
    }
    if (ruta == null || !context.mounted) return;
    final guardado = await ref
        .read(proveedorControladorPerfil.notifier)
        .subirFotoPerfil(ruta);
    if (guardado && context.mounted) {
      mostrarAvisoInformativo(context, 'Foto de perfil actualizada.');
    }
  }

  Future<void> _editarNombre(
    BuildContext context,
    WidgetRef ref,
    String nombreActual,
  ) async {
    final nombreNuevo = await showDialog<String>(
      context: context,
      builder: (_) => _DialogoEditarNombre(nombreInicial: nombreActual),
    );
    if (nombreNuevo == null || nombreNuevo.trim() == nombreActual) return;
    final guardado = await ref
        .read(proveedorControladorPerfil.notifier)
        .actualizarNombreVisible(nombreNuevo);
    if (!context.mounted) return;
    if (guardado) {
      mostrarAvisoInformativo(context, 'Nombre actualizado');
    } else {
      final error = ref.read(proveedorControladorPerfil).error;
      mostrarAvisoError(
        context,
        error ?? 'No se pudo actualizar el nombre.',
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<AsyncValue<void>>(proveedorControladorPerfil, (_, siguiente) {
      if (siguiente is AsyncError) mostrarAvisoError(context, siguiente.error);
    });

    final usuarioSesion = ref.watch(proveedorEstadoAutenticacion).value;
    final perfilAsincrono = ref.watch(proveedorPerfilUsuarioActual);
    final perfil = perfilAsincrono.value;
    final fotoPublicId = perfil?.fotoPublicId?.trim();
    if (fotoPublicId != null && fotoPublicId.isNotEmpty) {
      ref.listen(proveedorUrlsAvatarPerfil(fotoPublicId), (anterior, siguiente) {
        if (!siguiente.hasError || !context.mounted) return;
        if (anterior?.hasError == true) return;
        mostrarAvisoError(
          context,
          siguiente.error ?? 'No se pudo cargar la foto de perfil.',
        );
      });
    }
    final ocupado = ref.watch(proveedorControladorPerfil).isLoading;
    final resumenAsincrono = ref.watch(proveedorResumenInicio);
    ref.listen(proveedorResumenInicio, (anterior, siguiente) {
      if (!siguiente.hasError || !context.mounted) return;
      if (anterior?.hasError == true) return;
      mostrarAvisoError(
        context,
        siguiente.error ?? 'No se pudo cargar el resumen.',
      );
    });
    final resumen = resumenAsincrono.when(
      data: (datos) => datos,
      loading: () => resumenAsincrono.value ?? ResumenInicio.vacio,
      error: (_, _) => resumenAsincrono.value ?? ResumenInicio.vacio,
    );
    final recuerdosAsincrono =
        ref.watch(proveedorRecuerdos(FiltroRecuerdos.todos));
    final amigos = ref.watch(proveedorMisAmigos).value ?? const [];

    final nombre =
        perfil?.nombreVisible ?? usuarioSesion?.nombreVisible ?? 'Sin nombre';
    final nombreLimpio = nombre.trim();
    final inicial =
        nombreLimpio.isEmpty ? '?' : nombreLimpio[0].toUpperCase();

    return PantallaCapsoul(
      cuerpo: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(proveedorPerfilUsuarioActual);
            ref.invalidate(proveedorRecuerdos(FiltroRecuerdos.todos));
            ref.invalidate(proveedorResumenInicio);
            if (fotoPublicId != null && fotoPublicId.isNotEmpty) {
              ref.invalidate(proveedorUrlsAvatarPerfil(fotoPublicId));
              ref.invalidate(proveedorUrlAvatarPerfil(fotoPublicId));
            }
            final esperas = <Future<void>>[
              ref.read(proveedorPerfilUsuarioActual.future),
              ref.read(proveedorRecuerdos(FiltroRecuerdos.todos).future),
              ref.read(proveedorResumenInicio.future),
            ];
            if (fotoPublicId != null && fotoPublicId.isNotEmpty) {
              esperas.add(ref.read(proveedorUrlsAvatarPerfil(fotoPublicId).future));
            }
            await Future.wait(esperas);
          },
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _BarraSuperior(
                  alCrear: () => HojaOpcionesCrear.mostrar(context),
                ),
              ),
              if (perfilAsincrono.isLoading && perfil == null)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: LinearProgressIndicator(),
                  ),
                ),
              SliverToBoxAdapter(
                child: EncabezadoPerfil(
                  nombre: nombre,
                  nombreUsuario: perfil?.nombreUsuario,
                  inicial: inicial,
                  resumen: resumen,
                  publicaciones: resumen.recuerdos,
                  ocupado: ocupado,
                  alEditar: () => _editarNombre(context, ref, nombre),
                  alCerrarSesion: () => ref
                      .read(proveedorControladorPerfil.notifier)
                      .cerrarSesion(),
                  fotoPublicId: perfil?.fotoPublicId,
                  alTocarAvatar: ocupado
                      ? null
                      : () => _cambiarFoto(context, ref),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 12)),
              SliverToBoxAdapter(
                child: Material(
                  type: MaterialType.transparency,
                  child: ListTile(
                    leading: FilaAvataresAmigos(
                      amigos: amigos,
                      vacio: amigos.isEmpty,
                    ),
                    title: Text(
                      amigos.isEmpty
                          ? 'Invita a tus primeros amigos'
                          : 'Amigos e invitaciones',
                    ),
                    trailing: _TrailingAmigos(
                      pendientes: ref.watch(
                        proveedorConteoSolicitudesPendientes,
                      ),
                    ),
                    onTap: () => context.push(RutasApp.amigos),
                  ),
                ),
              ),
              // SliverToBoxAdapter(
              //   child: FilaDestacadosPerfil(
              //     alTocar: (etiqueta) => mostrarAvisoInformativo(
              //       context,
              //       '$etiqueta: próximamente',
              //     ),
              //   ),
              // ),
              const SliverToBoxAdapter(child: SizedBox(height: 8)),
              recuerdosAsincrono.when(
                loading: () => const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(48),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),
                error: (_, _) => const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Text(
                      'No pudimos cargar tus recuerdos.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: ColoresApp.atenuado),
                    ),
                  ),
                ),
                data: (lista) => SliverToBoxAdapter(
                  child: RejillaElementosPerfil(recuerdos: lista),
                ),
              ),
            ],
          ),
        ),
    );
  }
}

class _BarraSuperior extends StatelessWidget {
  const _BarraSuperior({required this.alCrear});

  final VoidCallback alCrear;

  @override
  Widget build(BuildContext context) {
    final estilos = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 4),
      child: Row(
        children: [
          const Icon(Icons.lock_outline, size: 18, color: ColoresApp.primario),
          const SizedBox(width: 6),
          Text(
            'cápsoul',
            style: estilos.titleLarge?.copyWith(
              color: ColoresApp.primario,
              fontWeight: FontWeight.w800,
            ),
          ),
          const Spacer(),
          // IconButton(
          //   tooltip: 'Crear',
          //   onPressed: alCrear,
          //   icon: const Icon(Icons.add_box_outlined),
          // ),
          // IconButton(
          //   tooltip: 'Menú',
          //   onPressed: () {},
          //   icon: const Icon(Icons.menu),
          // ),
        ],
      ),
    );
  }
}

class _DialogoEditarNombre extends StatefulWidget {
  const _DialogoEditarNombre({required this.nombreInicial});

  final String nombreInicial;

  @override
  State<_DialogoEditarNombre> createState() => _EstadoDialogoEditarNombre();
}

class _EstadoDialogoEditarNombre extends State<_DialogoEditarNombre> {
  final _claveFormulario = GlobalKey<FormState>();
  late final TextEditingController _controlador =
      TextEditingController(text: widget.nombreInicial);

  @override
  void dispose() {
    _controlador.dispose();
    super.dispose();
  }

  void _guardar() {
    if (!(_claveFormulario.currentState?.validate() ?? false)) return;
    Navigator.of(context).pop(_controlador.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(TemaApp.radioGrande),
      ),
      title: const Text('Editar nombre'),
      content: Form(
        key: _claveFormulario,
        child: TextFormField(
          controller: _controlador,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(labelText: 'Nombre'),
          validator: ValidadoresAutenticacion.nombreVisible,
          onFieldSubmitted: (_) => _guardar(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _guardar,
          style: FilledButton.styleFrom(minimumSize: const Size(96, 48)),
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}

/// Flecha de «Amigos» con el número de solicitudes pendientes.
class _TrailingAmigos extends StatelessWidget {
  const _TrailingAmigos({required this.pendientes});

  final int pendientes;

  @override
  Widget build(BuildContext context) {
    const flecha = Icon(Icons.chevron_right);
    if (pendientes <= 0) return flecha;
    final texto = pendientes > 9 ? '9+' : '$pendientes';
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          label: '$pendientes solicitudes de amistad pendientes',
          child: Badge(
            key: const Key('badge-solicitudes-amistad'),
            label: Text(texto),
          ),
        ),
        const SizedBox(width: 8),
        flecha,
      ],
    );
  }
}
