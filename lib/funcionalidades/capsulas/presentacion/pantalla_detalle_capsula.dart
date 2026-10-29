import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../nucleo/errores/fallo_app.dart';
import '../../../nucleo/tema/colores_app.dart';
import '../../autenticacion/aplicacion/proveedores_autenticacion.dart';
import '../../../nucleo/enrutador/rutas_app.dart';
import '../../recuerdos/dominio/recuerdo.dart';
import '../../recuerdos/presentacion/navegacion_visor_recuerdo.dart';
import '../aplicacion/proveedores_capsulas.dart';
import '../dominio/apertura_capsula.dart';
import '../dominio/capsula.dart';
import '../dominio/estado_capsula.dart';
import 'package:share_plus/share_plus.dart';

import '../../../nucleo/componentes/avisos_emergentes.dart';
import '../../../nucleo/componentes/menu_acciones_entidad.dart';
import '../../../nucleo/enlaces/enlace_capsoul.dart';
import 'componentes/animacion_apertura.dart';
import 'componentes/cabecera_capsula.dart';
import 'componentes/cuenta_regresiva.dart';
import 'componentes/tarjeta_contenido.dart';

/// Detalle de una cápsula: sellada (candado y cuenta regresiva; el autor ve
/// su contenido), o lista para abrir con la animación del frasco.
class PantallaDetalleCapsula extends ConsumerWidget {
  const PantallaDetalleCapsula({super.key, required this.idCapsula});

  final String idCapsula;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final capsula = ref.watch(proveedorCapsula(idCapsula));
    return Scaffold(
      body: capsula.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _EstadoSinCapsula(
          mensaje: mensajeParaUsuario(error),
          alReintentar: () => ref.invalidate(proveedorCapsula(idCapsula)),
        ),
        data: (datos) => datos == null
            ? const _EstadoSinCapsula(
                mensaje: 'Esta cápsula no existe o aún no puedes verla.',
              )
            : _ContenidoDetalle(capsula: datos),
      ),
    );
  }
}

class _ContenidoDetalle extends ConsumerStatefulWidget {
  const _ContenidoDetalle({required this.capsula});

  final Capsula capsula;

  @override
  ConsumerState<_ContenidoDetalle> createState() => _EstadoContenidoDetalle();
}

class _EstadoContenidoDetalle extends ConsumerState<_ContenidoDetalle> {
  bool _abierta = false;

  Future<void> _abrir(Capsula capsula, String? uid) async {
    await mostrarAnimacionApertura(context);
    if (!mounted) return;
    final esDestinatario =
        uid != null && capsula.autorId != uid && capsula.autorId.isNotEmpty;
    if (esDestinatario) {
      try {
        await ref
            .read(proveedorRepositorioCapsulas)
            .marcarAbierta(capsula.id);
        ref.invalidate(proveedorCapsulasRecibidas);
      } catch (_) {
        // La animación ya ocurrió; el usuario puede reintentar refrescando.
      }
    }
    if (mounted) setState(() => _abierta = true);
  }

  bool _puedeGestionar(Capsula capsula, String? uid) =>
      uid != null &&
      capsula.autorId == uid &&
      (capsula.estado == EstadoCapsula.borrador ||
          capsula.estado == EstadoCapsula.programada ||
          capsula.estado == EstadoCapsula.cancelada);

  Future<void> _cancelar(Capsula capsula) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancelar cápsula'),
        content: const Text(
          'La cápsula quedará cancelada y no se abrirá en la fecha programada.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('No')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Sí, cancelar')),
        ],
      ),
    );
    if (confirmar != true || !mounted) return;
    try {
      await ref.read(proveedorRepositorioCapsulas).cancelarCapsula(capsula.id);
      ref.invalidate(proveedorCapsula(capsula.id));
      ref.invalidate(proveedorMisCapsulas);
      if (mounted) mostrarAvisoInformativo(context, 'Cápsula cancelada.');
    } catch (error) {
      if (mounted) mostrarAvisoError(context, mensajeParaUsuario(error));
    }
  }

  Future<void> _eliminar(Capsula capsula) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar cápsula'),
        content: const Text('Esta acción no se puede deshacer.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('No')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Eliminar')),
        ],
      ),
    );
    if (confirmar != true || !mounted) return;
    try {
      await ref.read(proveedorRepositorioCapsulas).eliminarCapsula(capsula.id);
      ref.invalidate(proveedorMisCapsulas);
      if (mounted) context.pop();
    } catch (error) {
      if (mounted) mostrarAvisoError(context, mensajeParaUsuario(error));
    }
  }

  /// Abre el detalle del recuerdo (foto, video, audio o nota).
  void _alTocarElemento(Recuerdo recuerdo) {
    mostrarVisorPublicacionRecuerdo(context, ref, recuerdo);
  }

  @override
  Widget build(BuildContext context) {
    final capsula = widget.capsula;
    final reloj = ref.watch(proveedorReloj);
    final uid = ref.watch(
      proveedorEstadoAutenticacion.select((estado) => estado.value?.uid),
    );
    final modo = calcularModoApertura(capsula, uidActual: uid, ahora: reloj());
    final fecha = capsula.fechaApertura;
    final sellada = modo != ModoApertura.lista;
    final esperaLiberacion = sellada &&
        fecha != null &&
        !fecha.isAfter(reloj()) &&
        capsula.estado != EstadoCapsula.liberada;
    final mensaje = capsula.mensaje?.trim();
    final textoMensaje =
        (mensaje == null || mensaje.isEmpty) ? 'Sin mensaje.' : mensaje;
    final esAutor =
        uid != null && capsula.autorId.isNotEmpty && capsula.autorId == uid;
    final mostrarContenido = modo == ModoApertura.selladaParaAutor ||
        (modo == ModoApertura.lista && (esAutor || _abierta));

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: CabeceraCapsula(
            titulo: capsula.titulo,
            horizonte: fecha == null
                ? null
                : describirHorizonte(capsula.creadoEn, fecha),
            fechaApertura: fecha == null ? null : formatearFechaCorta(fecha),
            sellada: sellada,
            cuentaRegresiva: !sellada || fecha == null
                ? null
                : esperaLiberacion
                    ? const Text('Aún no liberada')
                    : CuentaRegresiva(
                        fechaApertura: fecha,
                        reloj: reloj,
                        alLlegar: () => setState(() {}),
                      ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          sliver: SliverList.list(
            children: [
              if (modo != ModoApertura.bloqueada) ...[
                const _Titulo('Sobre esta cápsula'),
                const SizedBox(height: 6),
                Text(
                  textoMensaje,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 24),
              ],
              const _Titulo('Contenido'),
              const SizedBox(height: 10),
              if (modo == ModoApertura.selladaParaAutor)
                const _AvisoSoloAutor(),
              if (mostrarContenido)
                _RejillaContenido(
                  elementos: capsula.elementos,
                  alTocar: _alTocarElemento,
                )
              else if (modo == ModoApertura.lista && !esAutor)
                _InvitacionAbrir(alAbrir: () => _abrir(capsula, uid))
              else
                _ContenidoBloqueado(
                  fecha: fecha == null ? null : formatearFechaCorta(fecha),
                ),
              const SizedBox(height: 24),
              if (_puedeGestionar(capsula, uid)) ...[
                const SizedBox(height: 8),
                _AccionesAutor(
                  capsula: capsula,
                  alCompartir: () => Share.share(
                    'Te envié una cápsula en Capsoul. Ábrela con la app:\n'
                    '${EnlaceCapsoul.capsula(capsula.id)}',
                  ),
                  alEditar: () =>
                      context.push(RutasApp.editarCapsulaDe(capsula.id)),
                  alCancelar: capsula.estado == EstadoCapsula.programada
                      ? () => _cancelar(capsula)
                      : null,
                  alEliminar: capsula.estado == EstadoCapsula.borrador ||
                          capsula.estado == EstadoCapsula.cancelada
                      ? () => _eliminar(capsula)
                      : null,
                ),
              ],
              const _Titulo('Persona de confianza'),
              const SizedBox(height: 6),
              const _PersonaConfianza(),
            ],
          ),
        ),
      ],
    );
  }
}

class _Titulo extends StatelessWidget {
  const _Titulo(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Text(
      texto,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: ColoresApp.primario,
            fontWeight: FontWeight.w700,
          ),
    );
  }
}

class _RejillaContenido extends StatelessWidget {
  const _RejillaContenido({required this.elementos, required this.alTocar});

  final List<Recuerdo> elementos;
  final ValueChanged<Recuerdo> alTocar;

  @override
  Widget build(BuildContext context) {
    if (elementos.isEmpty) {
      return const Text(
        'Esta cápsula no tiene recuerdos.',
        style: TextStyle(color: ColoresApp.atenuado),
      );
    }
    return LayoutBuilder(
      builder: (context, restricciones) {
        const separacion = 12.0;
        final ancho = (restricciones.maxWidth - separacion) / 2;
        return Wrap(
          spacing: separacion,
          runSpacing: separacion,
          children: [
            for (final elemento in elementos)
              SizedBox(
                key: ValueKey(elemento.id),
                width: ancho,
                child: TarjetaContenido(
                  elemento: elemento,
                  alTocar: () => alTocar(elemento),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _AvisoSoloAutor extends StatelessWidget {
  const _AvisoSoloAutor();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(Icons.visibility_outlined, size: 18, color: ColoresApp.acento),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Solo tú puedes ver el contenido hasta la fecha de apertura.',
              style: TextStyle(color: ColoresApp.atenuado),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContenidoBloqueado extends StatelessWidget {
  const _ContenidoBloqueado({required this.fecha});

  final String? fecha;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: ColoresApp.primario.withValues(alpha: 0.06),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            const Icon(Icons.lock_outline, color: ColoresApp.primario),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                fecha == null
                    ? 'El contenido está sellado.'
                    : 'El contenido se revelará el $fecha.',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InvitacionAbrir extends StatelessWidget {
  const _InvitacionAbrir({required this.alAbrir});

  final Future<void> Function() alAbrir;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Llegó el día. Esta cápsula ya se puede abrir.',
          style: TextStyle(color: ColoresApp.atenuado),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: () => alAbrir(),
          icon: const Icon(Icons.lock_open_outlined),
          label: const Text('Abrir cápsula'),
        ),
      ],
    );
  }
}

class _PersonaConfianza extends StatelessWidget {
  const _PersonaConfianza();

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: ColoresApp.acento.withValues(alpha: 0.15),
        foregroundColor: ColoresApp.primario,
        child: const Icon(Icons.person_outline),
      ),
      title: const Text('Sin asignar'),
      trailing: const Chip(
        label: Text('Próximamente'),
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}

class _EstadoSinCapsula extends StatelessWidget {
  const _EstadoSinCapsula({required this.mensaje, this.alReintentar});

  final String mensaje;
  final VoidCallback? alReintentar;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const BackButton(),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.inventory_2_outlined,
                        size: 48, color: ColoresApp.atenuado),
                    const SizedBox(height: 12),
                    Text(mensaje, textAlign: TextAlign.center),
                    if (alReintentar != null) ...[
                      const SizedBox(height: 16),
                      OutlinedButton(
                        onPressed: alReintentar,
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AccionesAutor extends StatelessWidget {
  const _AccionesAutor({
    required this.capsula,
    required this.alEditar,
    required this.alCompartir,
    this.alCancelar,
    this.alEliminar,
  });

  final Capsula capsula;
  final VoidCallback alEditar;
  final VoidCallback alCompartir;
  final VoidCallback? alCancelar;
  final VoidCallback? alEliminar;

  @override
  Widget build(BuildContext context) {
    final puedeEditar = capsula.estado == EstadoCapsula.borrador ||
        capsula.estado == EstadoCapsula.programada;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _Titulo('Gestionar'),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: alCompartir,
          icon: const Icon(Icons.share_outlined),
          label: const Text('Compartir enlace'),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: MenuAccionesEntidad(
            puedeEditar: puedeEditar,
            puedeEliminar: alEliminar != null,
            pedirConfirmacionEliminar: false,
            etiquetaEliminar: 'Eliminar cápsula',
            alEditar: alEditar,
            alEliminar: alEliminar,
          ),
        ),
        if (alCancelar != null) ...[
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: alCancelar,
            icon: const Icon(Icons.cancel_outlined),
            label: const Text('Cancelar programación'),
          ),
        ],
      ],
    );
  }
}
