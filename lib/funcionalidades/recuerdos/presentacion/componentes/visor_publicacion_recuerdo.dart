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
import '../../dominio/aspecto_medio.dart';
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
    final maxAlto = MediaQuery.sizeOf(context).height * 0.55;

    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Material(
            color: Colors.transparent,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: TarjetaCapsoul(
                radio: TemaApp.radioGrande,
                borde: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 8, 0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  recuerdo.nombre,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleLarge
                                      ?.copyWith(
                                        fontFamily: TemaApp.fuenteTitulos,
                                        color: ColoresApp.primario,
                                      ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  formatearFechaCorta(recuerdo.fechaRecuerdo),
                                  style: const TextStyle(
                                    color: ColoresApp.atenuado,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: 'Cerrar',
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.close),
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
                                  'Se quitará también de los momentos y de '
                                  'las cápsulas en borrador donde esté. No se '
                                  'puede deshacer.',
                              cargando: ocupado,
                              alEditar: widget.alEditar,
                              alEliminar: _borrar,
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxHeight: maxAlto),
                        child: SingleChildScrollView(
                          child: _ContenidoVisor(
                            recuerdo: recuerdo,
                            previewMusica: _previewMusica,
                            claveEscenaMusica: _claveEscenaMusica,
                            elementoIdPersistirPreviewMusica:
                                esPropietario ? recuerdo.id : null,
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

class _ContenidoVisor extends StatelessWidget {
  const _ContenidoVisor({
    required this.recuerdo,
    required this.previewMusica,
    required this.claveEscenaMusica,
    this.elementoIdPersistirPreviewMusica,
  });

  final Recuerdo recuerdo;
  final PreviewMusicaCompartido previewMusica;
  final GlobalKey<EscenaPreviewMusicaState> claveEscenaMusica;
  final String? elementoIdPersistirPreviewMusica;

  @override
  Widget build(BuildContext context) {
    return switch (recuerdo.tipo) {
      TipoElemento.musica => _musica(recuerdo),
      TipoElemento.foto => _foto(recuerdo),
      TipoElemento.video => ReproductorVideoRecuerdo(
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
      alturaDisco: 200,
      mostrarEnlacesCompletos: true,
      mostrarPieMetadata: true,
    );
  }

  Widget _foto(Recuerdo recuerdo) {
    final musica = recuerdo.musica;
    final ratio = aspectoMedio(
      tipo: TipoElemento.foto,
      ancho: recuerdo.ancho,
      alto: recuerdo.alto,
    );
    if (recuerdo.tieneMusica && musica != null) {
      return AspectRatio(
        aspectRatio: ratio,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(TemaApp.radioGrande),
              child: FotoCompleta(recuerdo: recuerdo),
            ),
            OverlayMusicaFotoVis(
              referencia: musica,
              previewMusica: previewMusica,
              reproducirAutomaticamente: true,
            ),
          ],
        ),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(TemaApp.radioGrande),
      child: FotoCompleta(recuerdo: recuerdo),
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
