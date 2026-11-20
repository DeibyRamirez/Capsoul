import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../nucleo/componentes/menu_acciones_entidad.dart';
import '../../../../nucleo/componentes/tarjeta_capsoul.dart';
import '../../../../nucleo/formato/fechas.dart';
import '../../../../nucleo/tema/colores_app.dart';
import '../../../../nucleo/tema/tema_app.dart';
import '../../../autenticacion/aplicacion/proveedores_autenticacion.dart';
import '../../../elementos/dominio/tipo_elemento.dart';
import '../../../elementos/presentacion/componentes/vista_nota_rica.dart';
import '../../../musica/aplicacion/preview_musica_compartido.dart';
import '../../../musica/presentacion/componentes/escena_preview_musica.dart';
import '../../../musica/presentacion/componentes/overlay_musica_foto_vis.dart';
import '../../aplicacion/controlador_recuerdos.dart';
import '../../dominio/recuerdo.dart';
import '../acciones_recuerdo.dart';
import 'reproductores_medio.dart';

/// Visor centrado tipo publicación para un [Recuerdo].
class VisorPublicacionRecuerdo extends ConsumerStatefulWidget {
  const VisorPublicacionRecuerdo({
    super.key,
    required this.recuerdo,
    required this.alEditar,
  });

  final Recuerdo recuerdo;
  final VoidCallback alEditar;

  @override
  ConsumerState<VisorPublicacionRecuerdo> createState() =>
      _EstadoVisorPublicacionRecuerdo();
}

class _EstadoVisorPublicacionRecuerdo
    extends ConsumerState<VisorPublicacionRecuerdo> {
  final _previewMusica = PreviewMusicaCompartido();
  final _claveEscenaMusica = GlobalKey<EscenaPreviewMusicaState>();

  @override
  void dispose() {
    unawaited(_previewMusica.reproductor.stop());
    _previewMusica.dispose();
    super.dispose();
  }

  Future<void> _borrar() async {
    await borrarRecuerdoConConfirmacion(
      context,
      ref,
      widget.recuerdo,
      alExito: () => Navigator.of(context).pop(),
    );
  }

  bool _esInmersivo(TipoElemento tipo) =>
      tipo == TipoElemento.foto || tipo == TipoElemento.video;

  @override
  Widget build(BuildContext context) {
    final recuerdo = widget.recuerdo;
    final uid = ref.watch(
      proveedorEstadoAutenticacion.select((estado) => estado.value?.uid),
    );
    final ocupado = ref.watch(
      proveedorControladorRecuerdos.select((estado) => estado.ocupado),
    );
    final esPropietario = recuerdo.propietarioId == uid;

    if (_esInmersivo(recuerdo.tipo)) {
      return _VisorInmersivo(
        recuerdo: recuerdo,
        esPropietario: esPropietario,
        ocupado: ocupado,
        alEditar: widget.alEditar,
        alBorrar: _borrar,
        previewMusica: _previewMusica,
        claveEscenaMusica: _claveEscenaMusica,
      );
    }

    return _VisorTarjeta(
      recuerdo: recuerdo,
      esPropietario: esPropietario,
      ocupado: ocupado,
      alEditar: widget.alEditar,
      alBorrar: _borrar,
      previewMusica: _previewMusica,
      claveEscenaMusica: _claveEscenaMusica,
    );
  }
}

class _VisorInmersivo extends StatelessWidget {
  const _VisorInmersivo({
    required this.recuerdo,
    required this.esPropietario,
    required this.ocupado,
    required this.alEditar,
    required this.alBorrar,
    required this.previewMusica,
    required this.claveEscenaMusica,
  });

  final Recuerdo recuerdo;
  final bool esPropietario;
  final bool ocupado;
  final VoidCallback alEditar;
  final Future<void> Function() alBorrar;
  final PreviewMusicaCompartido previewMusica;
  final GlobalKey<EscenaPreviewMusicaState> claveEscenaMusica;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Material(
        color: ColoresApp.medianoche,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(
              child: _ContenidoVisor(
                recuerdo: recuerdo,
                previewMusica: previewMusica,
                claveEscenaMusica: claveEscenaMusica,
                elementoIdPersistirPreviewMusica: esPropietario
                    ? recuerdo.id
                    : null,
                pantallaCompleta: true,
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      ColoresApp.medianoche.withValues(alpha: 0.96),
                      ColoresApp.medianoche.withValues(alpha: 0.62),
                      ColoresApp.medianoche.withValues(alpha: 0),
                    ],
                    stops: const [0, 0.52, 1],
                  ),
                ),
                child: SafeArea(
                  bottom: false,
                  child: _CabeceraVisor(
                    recuerdo: recuerdo,
                    esPropietario: esPropietario,
                    ocupado: ocupado,
                    alEditar: alEditar,
                    alBorrar: alBorrar,
                    temaClaro: true,
                    padding: const EdgeInsets.fromLTRB(16, 8, 8, 28),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VisorTarjeta extends StatelessWidget {
  const _VisorTarjeta({
    required this.recuerdo,
    required this.esPropietario,
    required this.ocupado,
    required this.alEditar,
    required this.alBorrar,
    required this.previewMusica,
    required this.claveEscenaMusica,
  });

  final Recuerdo recuerdo;
  final bool esPropietario;
  final bool ocupado;
  final VoidCallback alEditar;
  final Future<void> Function() alBorrar;
  final PreviewMusicaCompartido previewMusica;
  final GlobalKey<EscenaPreviewMusicaState> claveEscenaMusica;

  @override
  Widget build(BuildContext context) {
    final maxAlto = MediaQuery.sizeOf(context).height * 0.68;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Material(
              color: Colors.transparent,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: TarjetaCapsoul(
                  radio: TemaApp.radioGrande,
                  borde: true,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _CabeceraVisor(
                        recuerdo: recuerdo,
                        esPropietario: esPropietario,
                        ocupado: ocupado,
                        alEditar: alEditar,
                        alBorrar: alBorrar,
                        padding: EdgeInsets.zero,
                      ),
                      const Divider(
                        height: 24,
                        thickness: 1,
                        color: ColoresApp.bordeTarjeta,
                      ),
                      ConstrainedBox(
                        constraints: BoxConstraints(maxHeight: maxAlto),
                        child: SingleChildScrollView(
                          child: SizedBox(
                            width: double.infinity,
                            child: _ContenidoVisor(
                              recuerdo: recuerdo,
                              previewMusica: previewMusica,
                              claveEscenaMusica: claveEscenaMusica,
                              elementoIdPersistirPreviewMusica: esPropietario
                                  ? recuerdo.id
                                  : null,
                              pantallaCompleta: false,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _PieVisor(esPropietario: esPropietario),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CabeceraVisor extends StatelessWidget {
  const _CabeceraVisor({
    required this.recuerdo,
    required this.esPropietario,
    required this.ocupado,
    required this.alEditar,
    required this.alBorrar,
    this.temaClaro = false,
    this.padding = const EdgeInsets.fromLTRB(12, 8, 4, 12),
  });

  final Recuerdo recuerdo;
  final bool esPropietario;
  final bool ocupado;
  final VoidCallback alEditar;
  final Future<void> Function() alBorrar;
  final bool temaClaro;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final estilos = Theme.of(context).textTheme;
    final colorTitulo = temaClaro
        ? ColoresApp.sobrePrimario
        : ColoresApp.primario;
    final colorMeta = temaClaro
        ? ColoresApp.sobrePrimario.withValues(alpha: 0.82)
        : ColoresApp.atenuado;
    final iconTheme = IconThemeData(
      color: temaClaro ? ColoresApp.sobrePrimario : ColoresApp.textoPrincipal,
    );

    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _EtiquetaTipoRecuerdo(
                  tipo: recuerdo.tipo,
                  temaClaro: temaClaro,
                ),
                const SizedBox(height: 10),
                Text(
                  recuerdo.nombre,
                  style: estilos.titleLarge?.copyWith(
                    fontFamily: TemaApp.fuenteTitulos,
                    color: colorTitulo,
                    fontWeight: FontWeight.w600,
                    height: 1.15,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 13,
                      color: colorMeta,
                    ),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        formatearFechaCorta(recuerdo.fechaRecuerdo),
                        style: estilos.bodySmall?.copyWith(color: colorMeta),
                      ),
                    ),
                    if (esPropietario) ...[
                      const SizedBox(width: 10),
                      Container(
                        width: 3,
                        height: 3,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: colorMeta,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          'En tu banco',
                          style: estilos.bodySmall?.copyWith(color: colorMeta),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'Cerrar',
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close, size: 20),
            style: IconButton.styleFrom(
              backgroundColor: temaClaro
                  ? Colors.white.withValues(alpha: 0.12)
                  : ColoresApp.primario.withValues(alpha: 0.06),
              foregroundColor: temaClaro
                  ? ColoresApp.sobrePrimario
                  : ColoresApp.textoPrincipal,
            ),
          ),
          if (esPropietario)
            IconTheme.merge(
              data: iconTheme,
              child: MenuAccionesEntidad(
                key: const Key('menu-acciones-visor'),
                compacto: true,
                puedeEditar: true,
                puedeEliminar: true,
                pedirConfirmacionEliminar: false,
                etiquetaEliminar: 'Borrar recuerdo',
                tituloConfirmacion: '¿Borrar este recuerdo?',
                mensajeConfirmacion:
                    'Se quitará también de los momentos y de las cápsulas en '
                    'borrador donde esté. No se puede deshacer.',
                cargando: ocupado,
                alEditar: alEditar,
                alEliminar: alBorrar,
              ),
            ),
        ],
      ),
    );
  }
}

class _EtiquetaTipoRecuerdo extends StatelessWidget {
  const _EtiquetaTipoRecuerdo({required this.tipo, required this.temaClaro});

  final TipoElemento tipo;
  final bool temaClaro;

  IconData get _icono => switch (tipo) {
    TipoElemento.foto => Icons.photo_outlined,
    TipoElemento.video => Icons.videocam_outlined,
    TipoElemento.audio => Icons.mic_none_outlined,
    TipoElemento.musica => Icons.music_note_outlined,
    TipoElemento.texto => Icons.notes_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final color = temaClaro ? ColoresApp.sobrePrimario : ColoresApp.primario;
    final fondo = temaClaro
        ? Colors.white.withValues(alpha: 0.12)
        : ColoresApp.primario.withValues(alpha: 0.08);
    final borde = temaClaro
        ? Colors.white.withValues(alpha: 0.18)
        : ColoresApp.bordeTarjeta;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: fondo,
        borderRadius: BorderRadius.circular(TemaApp.radioPildora),
        border: Border.all(color: borde),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icono, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            tipo.etiqueta,
            style: Theme.of(context).textTheme.labelSmall
                ?.copyWith(color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _PieVisor extends StatelessWidget {
  const _PieVisor({required this.esPropietario});

  final bool esPropietario;

  @override
  Widget build(BuildContext context) {
    final estilos = Theme.of(context).textTheme;
    final texto = esPropietario
        ? 'Guardado en tu banco de recuerdos'
        : 'Compartido contigo';

    return Row(
      children: [
        Icon(
          esPropietario ? Icons.inventory_2_outlined : Icons.people_outline,
          size: 15,
          color: ColoresApp.atenuado,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            texto,
            style: estilos.bodySmall?.copyWith(color: ColoresApp.atenuado),
          ),
        ),
        Text(
          'Capsoul',
          style: estilos.labelSmall?.copyWith(
            color: ColoresApp.acento,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _ContenidoVisor extends StatelessWidget {
  const _ContenidoVisor({
    required this.recuerdo,
    required this.previewMusica,
    required this.claveEscenaMusica,
    this.elementoIdPersistirPreviewMusica,
    this.pantallaCompleta = false,
  });

  final Recuerdo recuerdo;
  final PreviewMusicaCompartido previewMusica;
  final GlobalKey<EscenaPreviewMusicaState> claveEscenaMusica;
  final String? elementoIdPersistirPreviewMusica;
  final bool pantallaCompleta;

  @override
  Widget build(BuildContext context) {
    return switch (recuerdo.tipo) {
      TipoElemento.musica => _musica(recuerdo),
      TipoElemento.foto => _foto(recuerdo),
      TipoElemento.video =>
        pantallaCompleta
            ? Center(
                child: ReproductorVideoRecuerdo(
                  recuerdo: recuerdo,
                  reproducirAlIniciar: true,
                ),
              )
            : ReproductorVideoRecuerdo(
                recuerdo: recuerdo,
                reproducirAlIniciar: true,
              ),
      TipoElemento.audio => ReproductorAudioRecuerdo(
        recuerdo: recuerdo,
        reproducirAlIniciar: true,
      ),
      TipoElemento.texto => _nota(recuerdo),
    };
  }

  Widget _musica(Recuerdo recuerdo) {
    final musica = recuerdo.musica;
    if (musica == null) {
      return const Text(
        'No se pudo cargar la canción.',
        textAlign: TextAlign.center,
      );
    }
    return EscenaPreviewMusica(
      key: claveEscenaMusica,
      referencia: musica,
      elementoRecuerdoIdParaPersistir: elementoIdPersistirPreviewMusica,
      reproducirAutomaticamente: true,
      alturaDisco: pantallaCompleta ? 240 : 200,
      mostrarEnlacesCompletos: true,
      mostrarPieMetadata: true,
    );
  }

  Widget _foto(Recuerdo recuerdo) {
    final musica = recuerdo.musica;
    final foto = FotoCompleta(
      recuerdo: recuerdo,
      pantallaCompleta: pantallaCompleta,
    );
    if (recuerdo.tieneMusica && musica != null) {
      if (pantallaCompleta) {
        return Stack(
          fit: StackFit.expand,
          children: [
            foto,
            OverlayMusicaFotoVis(
              referencia: musica,
              previewMusica: previewMusica,
              reproducirAutomaticamente: true,
              margenLateral: 16,
              margenInferior: 24,
            ),
          ],
        );
      }
      return Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(TemaApp.radioGrande),
            child: foto,
          ),
          OverlayMusicaFotoVis(
            referencia: musica,
            previewMusica: previewMusica,
            reproducirAutomaticamente: true,
          ),
        ],
      );
    }
    if (pantallaCompleta) return foto;
    return ClipRRect(
      borderRadius: BorderRadius.circular(TemaApp.radioGrande),
      child: foto,
    );
  }

  Widget _nota(Recuerdo recuerdo) {
    final nota = recuerdo.nota;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: nota.estilo.colorFondo(),
        borderRadius: BorderRadius.circular(TemaApp.radioMediano),
        border: Border.all(
          color: ColoresApp.bordeTarjeta.withValues(alpha: 0.8),
        ),
      ),
      child: VistaNotaRica(nota: nota, seleccionable: true),
    );
  }
}
