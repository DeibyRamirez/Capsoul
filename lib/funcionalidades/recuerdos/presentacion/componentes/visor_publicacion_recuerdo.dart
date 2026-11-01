import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../nucleo/componentes/menu_acciones_entidad.dart';
import '../../../../nucleo/componentes/tarjeta_capsoul.dart';
import '../../../../nucleo/formato/fechas.dart';
import '../../../../nucleo/tema/colores_app.dart';
import '../../../../nucleo/tema/tema_app.dart';
import '../../../autenticacion/aplicacion/proveedores_autenticacion.dart';
import '../../../elementos/dominio/nota_serializada.dart';
import '../../../elementos/dominio/tipo_elemento.dart';
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
    return Material(
      color: ColoresApp.medianoche,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: _ContenidoVisor(
              recuerdo: recuerdo,
              previewMusica: previewMusica,
              claveEscenaMusica: claveEscenaMusica,
              elementoIdPersistirPreviewMusica:
                  esPropietario ? recuerdo.id : null,
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
                    ColoresApp.medianoche.withValues(alpha: 0.92),
                    ColoresApp.medianoche.withValues(alpha: 0.45),
                    ColoresApp.medianoche.withValues(alpha: 0),
                  ],
                  stops: const [0, 0.55, 1],
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
                ),
              ),
            ),
          ),
        ],
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
    final maxAlto = MediaQuery.sizeOf(context).height * 0.72;

    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Material(
            color: Colors.transparent,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: TarjetaCapsoul(
                radio: TemaApp.radioGrande,
                borde: false,
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
                      padding: const EdgeInsets.fromLTRB(16, 16, 8, 0),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxHeight: maxAlto),
                        child: SingleChildScrollView(
                          child: _ContenidoVisor(
                            recuerdo: recuerdo,
                            previewMusica: previewMusica,
                            claveEscenaMusica: claveEscenaMusica,
                            elementoIdPersistirPreviewMusica:
                                esPropietario ? recuerdo.id : null,
                            pantallaCompleta: false,
                          ),
                        ),
                      ),
                    ),
                  ],
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
    final colorTitulo = temaClaro ? ColoresApp.sobrePrimario : ColoresApp.primario;
    final colorFecha = temaClaro
        ? ColoresApp.sobrePrimario.withValues(alpha: 0.85)
        : ColoresApp.atenuado;
    final iconTheme = temaClaro ? ColoresApp.sobrePrimario : null;

    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  recuerdo.nombre,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontFamily: TemaApp.fuenteTitulos,
                        color: colorTitulo,
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  formatearFechaCorta(recuerdo.fechaRecuerdo),
                  style: TextStyle(color: colorFecha, fontSize: 13),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Cerrar',
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(Icons.close, color: iconTheme),
          ),
          if (esPropietario)
            MenuAccionesEntidad(
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
        ],
      ),
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
      TipoElemento.video => pantallaCompleta
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
    final nota = NotaSerializada.parse(recuerdo.contenidoTexto);
    final fam = nota.estilo.esPlayfair()
        ? TemaApp.fuenteTitulos
        : TemaApp.fuenteUi;
    return Card(
      color: nota.estilo.colorFondo(),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: MarkdownBody(
          data: nota.cuerpo.isEmpty ? ' ' : nota.cuerpo,
          selectable: true,
          styleSheet: MarkdownStyleSheet(
            p: TextStyle(
              fontSize: 16,
              height: 1.5,
              fontFamily: fam,
              color: ColoresApp.textoPrincipal,
            ),
          ),
        ),
      ),
    );
  }
}
