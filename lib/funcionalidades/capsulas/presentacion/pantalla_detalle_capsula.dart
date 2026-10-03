import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../nucleo/componentes/avisos_emergentes.dart';
import '../../../nucleo/errores/fallo_app.dart';
import '../../../nucleo/tema/colores_app.dart';
import '../../autenticacion/aplicacion/proveedores_autenticacion.dart';
import '../../elementos/dominio/tipo_elemento.dart';
import '../aplicacion/proveedores_capsulas.dart';
import '../dominio/apertura_capsula.dart';
import '../dominio/capsula.dart';
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

  Future<void> _abrir() async {
    await mostrarAnimacionApertura(context);
    if (mounted) setState(() => _abierta = true);
  }

  void _alTocarElemento(ElementoCapsula elemento) {
    if (elemento.tipo == TipoElemento.texto) {
      showDialog<void>(
        context: context,
        builder: (contexto) => AlertDialog(
          title: const Text('Nota'),
          content: SingleChildScrollView(
            child: Text(elemento.contenidoTexto ?? ''),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(contexto).pop(),
              child: const Text('Cerrar'),
            ),
          ],
        ),
      );
      return;
    }
    mostrarAvisoInformativo(
      context,
      'La reproducción estará disponible cuando se active la entrega segura '
      'de medios.',
    );
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
    final mensaje = capsula.mensaje?.trim();
    final textoMensaje =
        (mensaje == null || mensaje.isEmpty) ? 'Sin mensaje.' : mensaje;
    final mostrarContenido = modo == ModoApertura.selladaParaAutor ||
        (modo == ModoApertura.lista && _abierta);

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
            cuentaRegresiva: sellada && fecha != null
                ? CuentaRegresiva(
                    fechaApertura: fecha,
                    reloj: reloj,
                    alLlegar: () => setState(() {}),
                  )
                : null,
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
              else if (modo == ModoApertura.lista)
                _InvitacionAbrir(alAbrir: _abrir)
              else
                _ContenidoBloqueado(
                  fecha: fecha == null ? null : formatearFechaCorta(fecha),
                ),
              const SizedBox(height: 24),
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

  final List<ElementoCapsula> elementos;
  final ValueChanged<ElementoCapsula> alTocar;

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

  final VoidCallback alAbrir;

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
          onPressed: alAbrir,
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
