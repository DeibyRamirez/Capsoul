import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../nucleo/componentes/cabecera_detalle_capsoul.dart';
import '../../../nucleo/componentes/tarjeta_capsoul.dart';
import '../../../nucleo/componentes/avisos_emergentes.dart';
import '../../../nucleo/enrutador/rutas_app.dart';
import '../../../nucleo/errores/fallo_app.dart';
import '../../../nucleo/formato/fechas.dart';
import '../../../nucleo/tema/colores_app.dart';
import '../../../nucleo/tema/tema_app.dart';
import '../../amistades/aplicacion/proveedores_amistades.dart';
import '../../amistades/presentacion/componentes/tarjeta_solicitud_amistad.dart';
import '../../autenticacion/aplicacion/proveedores_autenticacion.dart';
import '../../capsulas/aplicacion/proveedores_capsulas.dart';
import '../../capsulas/dominio/avisos_capsulas.dart';
import '../../capsulas/dominio/capsula_recibida.dart';

/// Solicitudes de amistad pendientes y cápsulas compartidas ya abiertas.
class PantallaAvisos extends ConsumerWidget {
  const PantallaAvisos({super.key});

  Future<void> _refrescar(WidgetRef ref) async {
    ref.invalidate(proveedorCapsulasRecibidas);
    refrescarAmistades(ref.invalidate);
    await Future.wait([
      ref.read(proveedorCapsulasRecibidas.future),
      ref.read(proveedorSolicitudesAmistad.future),
    ]);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = ref.watch(proveedorEstadoAutenticacion).value?.uid;
    final recibidas = ref.watch(proveedorCapsulasRecibidas);
    final solicitudes = ref.watch(proveedorSolicitudesAmistad);
    final cargandoCapsulas = recibidas.isLoading && !recibidas.hasValue;
    final cargandoSolicitudes = solicitudes.isLoading && !solicitudes.hasValue;

    return Scaffold(
      backgroundColor: ColoresApp.superficie,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const CabeceraDetalleCapsoul(
            titulo: 'Avisos',
            subtitulo: 'Solicitudes de amistad y cápsulas abiertas',
            trailing: null,
          ),
          Expanded(
            child: cargandoCapsulas || cargandoSolicitudes
                ? const Center(child: CircularProgressIndicator())
                : _ListaAvisos(
                    uid: uid,
                    alReintentar: () => _refrescar(ref),
                    alRefrescar: () => _refrescar(ref),
                  ),
          ),
        ],
      ),
    );
  }
}

class _ListaAvisos extends ConsumerWidget {
  const _ListaAvisos({
    required this.uid,
    required this.alReintentar,
    required this.alRefrescar,
  });

  final String? uid;
  final Future<void> Function() alReintentar;
  final Future<void> Function() alRefrescar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recibidas = ref.watch(proveedorCapsulasRecibidas);
    final solicitudes = ref.watch(proveedorSolicitudesAmistad);
    final avisos = avisosCapsulasCompartidas(recibidas.value ?? const [], uid);
    final pendientes = solicitudes.value ?? const [];
    final sinDatos = !recibidas.hasValue && !solicitudes.hasValue;
    if (sinDatos && (recibidas.hasError || solicitudes.hasError)) {
      return _EstadoAvisos(
        mensaje: mensajeParaUsuario(recibidas.error ?? solicitudes.error),
        alReintentar: () => alReintentar(),
      );
    }
    if (avisos.isEmpty && pendientes.isEmpty) {
      if (recibidas.hasError || solicitudes.hasError) {
        return _EstadoAvisos(
          mensaje: mensajeParaUsuario(recibidas.error ?? solicitudes.error),
          alReintentar: () => alReintentar(),
        );
      }
      return const _EstadoAvisos(
        mensaje:
            'Cuando te llegue una solicitud de amistad o se abra una cápsula '
            'compartida, aparecerá aquí.',
      );
    }
    return RefreshIndicator(
      onRefresh: alRefrescar,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          for (final solicitud in pendientes)
            TarjetaSolicitudAmistad(solicitud: solicitud),
          for (var indice = 0; indice < avisos.length; indice++) ...[
            if (pendientes.isNotEmpty || indice > 0) const SizedBox(height: 12),
            _TarjetaAviso(aviso: avisos[indice]),
          ],
        ],
      ),
    );
  }
}

class _TarjetaAviso extends ConsumerWidget {
  const _TarjetaAviso({required this.aviso});

  final CapsulaRecibida aviso;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estilos = Theme.of(context).textTheme;
    final cuando = aviso.liberadaEn ?? aviso.fechaApertura;
    final sinLeer = aviso.leidaEn == null;

    return TarjetaCapsoul(
      icono: Icons.notifications_outlined,
      alTocar: () => _abrir(context, ref),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  aviso.tituloVisible,
                  style: estilos.titleMedium?.copyWith(
                    fontFamily: TemaApp.fuenteTitulos,
                    color: ColoresApp.primario,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (sinLeer) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: ColoresApp.acento.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(TemaApp.radioPequeno),
                    border: Border.all(color: ColoresApp.acento),
                  ),
                  child: const Text(
                    'Nuevo',
                    style: TextStyle(
                      color: ColoresApp.acento,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'De ${aviso.autorNombre}',
            style: estilos.bodyMedium?.copyWith(
              color: ColoresApp.textoPrincipal,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            formatearFechaHora(cuando),
            style: estilos.bodySmall?.copyWith(
              color: ColoresApp.textoSecundario,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _abrir(BuildContext context, WidgetRef ref) async {
    if (aviso.leidaEn == null) {
      try {
        await ref.read(proveedorRepositorioCapsulas).marcarAvisoLeido(aviso.id);
        ref.invalidate(proveedorCapsulasRecibidas);
      } catch (error) {
        if (context.mounted) mostrarAvisoError(context, error);
        return;
      }
    }
    if (!context.mounted) return;
    await context.push(RutasApp.detalleCapsulaDe(aviso.id));
  }
}

class _EstadoAvisos extends StatelessWidget {
  const _EstadoAvisos({required this.mensaje, this.alReintentar});

  final String mensaje;
  final VoidCallback? alReintentar;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.notifications_none_outlined,
              size: 56,
              color: ColoresApp.acento.withValues(alpha: 0.7),
            ),
            const SizedBox(height: 16),
            Text(
              mensaje,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge
                  ?.copyWith(color: ColoresApp.textoSecundario),
            ),
            if (alReintentar != null) ...[
              const SizedBox(height: 20),
              FilledButton(
                onPressed: alReintentar,
                child: const Text('Reintentar'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
