import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:video_player/video_player.dart';

import '../../../../nucleo/componentes/onda_audio.dart';
import '../../../../nucleo/tema/colores_app.dart';
import '../../../../nucleo/tema/tema_app.dart';
import '../../../elementos/dominio/validador_medios.dart';
import '../../aplicacion/proveedores_recuerdos.dart';
import '../../dominio/enlace_medio.dart';
import '../../dominio/recuerdo.dart';
import 'vista_recuerdo.dart';

/// Original del recuerdo (caché del dispositivo o enlace de `firmar-medio`).
/// `cargando` es `true` mientras se busca o descarga.
({File? archivo, bool cargando}) _original(WidgetRef ref, Recuerdo recuerdo) {
  final solicitud = solicitudMedioDe(recuerdo, VarianteMedio.original);
  if (solicitud == null) return (archivo: null, cargando: false);
  final estado = ref.watch(proveedorArchivoMedio(solicitud));
  return (archivo: estado.value, cargando: estado.isLoading);
}

/// Foto a tamaño completo (original, solo en el detalle), con zoom.
class FotoCompleta extends ConsumerWidget {
  const FotoCompleta({super.key, required this.recuerdo});

  final Recuerdo recuerdo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (:archivo, :cargando) = _original(ref, recuerdo);
    if (archivo == null) {
      return Stack(
        alignment: Alignment.center,
        children: [
          MarcoMiniatura(recuerdo: recuerdo),
          if (cargando) const CircularProgressIndicator(),
        ],
      );
    }
    final ancho = recuerdo.ancho;
    final alto = recuerdo.alto;
    return AspectRatio(
      aspectRatio: ancho != null && alto != null && alto > 0 ? ancho / alto : 4 / 3,
      child: InteractiveViewer(
        maxScale: 4,
        child: Image.file(
          archivo,
          fit: BoxFit.contain,
          semanticLabel: recuerdo.nombre,
          errorBuilder: (_, _, _) => MarcoMiniatura(recuerdo: recuerdo),
        ),
      ),
    );
  }
}

/// Reproductor de video del recuerdo (video_player).
class ReproductorVideoRecuerdo extends ConsumerStatefulWidget {
  const ReproductorVideoRecuerdo({super.key, required this.recuerdo});

  final Recuerdo recuerdo;

  @override
  ConsumerState<ReproductorVideoRecuerdo> createState() =>
      _EstadoReproductorVideo();
}

class _EstadoReproductorVideo extends ConsumerState<ReproductorVideoRecuerdo> {
  VideoPlayerController? _controlador;
  bool _fallo = false;

  @override
  void dispose() {
    _controlador?.dispose();
    super.dispose();
  }

  Future<void> _preparar(File archivo) async {
    final controlador = VideoPlayerController.file(archivo);
    _controlador = controlador;
    try {
      await controlador.initialize();
      if (mounted) setState(() {});
    } catch (error) {
      debugPrint('Capsoul: no se pudo abrir el video: $error');
      if (mounted) setState(() => _fallo = true);
    }
  }

  void _alternar() {
    final controlador = _controlador;
    if (controlador == null) return;
    setState(() {
      controlador.value.isPlaying ? controlador.pause() : controlador.play();
    });
  }

  @override
  Widget build(BuildContext context) {
    final (:archivo, :cargando) = _original(ref, widget.recuerdo);
    if (archivo != null && _controlador == null) unawaited(_preparar(archivo));
    final controlador = _controlador;
    if (_fallo || controlador == null || !controlador.value.isInitialized) {
      return Stack(
        alignment: Alignment.center,
        children: [
          MarcoMiniatura(recuerdo: widget.recuerdo),
          if (_fallo)
            const _AvisoMedio('No se pudo reproducir el video.')
          else if (cargando || archivo != null)
            const CircularProgressIndicator(color: ColoresApp.sobrePrimario),
        ],
      );
    }
    return AspectRatio(
      aspectRatio: controlador.value.aspectRatio,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          GestureDetector(onTap: _alternar, child: VideoPlayer(controlador)),
          ValueListenableBuilder(
            valueListenable: controlador,
            builder: (context, valor, _) => valor.isPlaying
                ? const SizedBox.shrink()
                : Center(
                    child: IconButton.filled(
                      iconSize: 40,
                      tooltip: 'Reproducir',
                      onPressed: _alternar,
                      icon: const Icon(Icons.play_arrow_rounded),
                    ),
                  ),
          ),
          VideoProgressIndicator(
            controlador,
            allowScrubbing: true,
            colors: const VideoProgressColors(
              playedColor: ColoresApp.acento,
              bufferedColor: ColoresApp.vidrioCupula,
            ),
          ),
        ],
      ),
    );
  }
}

/// Reproductor de la nota de voz con su onda (just_audio).
class ReproductorAudioRecuerdo extends ConsumerStatefulWidget {
  const ReproductorAudioRecuerdo({super.key, required this.recuerdo});

  final Recuerdo recuerdo;

  @override
  ConsumerState<ReproductorAudioRecuerdo> createState() =>
      _EstadoReproductorAudio();
}

class _EstadoReproductorAudio extends ConsumerState<ReproductorAudioRecuerdo> {
  AudioPlayer? _reproductor;
  bool _fallo = false;

  @override
  void dispose() {
    _reproductor?.dispose();
    super.dispose();
  }

  Future<void> _preparar(File archivo) async {
    final reproductor = AudioPlayer();
    _reproductor = reproductor;
    try {
      await reproductor.setFilePath(archivo.path);
      if (mounted) setState(() {});
    } catch (error) {
      debugPrint('Capsoul: no se pudo abrir la nota de voz: $error');
      if (mounted) setState(() => _fallo = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final (:archivo, cargando: _) = _original(ref, widget.recuerdo);
    if (archivo != null && _reproductor == null) unawaited(_preparar(archivo));
    final reproductor = _reproductor;
    final total = widget.recuerdo.duracion ?? Duration.zero;
    return Card(
      color: ColoresApp.acento.withValues(alpha: 0.12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(TemaApp.radioGrande),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 16, 16, 16),
        child: reproductor == null || _fallo
            ? Row(
                children: [
                  const Padding(
                    padding: EdgeInsets.all(12),
                    child: Icon(Icons.mic_none_outlined, color: ColoresApp.acento),
                  ),
                  Expanded(
                    child: _fallo
                        ? const _AvisoMedio('No se pudo reproducir la nota de voz.')
                        : OndaAudio(
                            color: ColoresApp.acento.withValues(alpha: 0.45),
                            semilla: widget.recuerdo.id.hashCode,
                            barras: 32,
                            altura: 48,
                          ),
                  ),
                ],
              )
            : StreamBuilder<PlayerState>(
                stream: reproductor.playerStateStream,
                builder: (context, estado) {
                  final sonando = estado.data?.playing ?? false;
                  final termino = estado.data?.processingState ==
                      ProcessingState.completed;
                  return StreamBuilder<Duration>(
                    stream: reproductor.positionStream,
                    builder: (context, posicion) {
                      final actual = posicion.data ?? Duration.zero;
                      final duracion = reproductor.duration ?? total;
                      final progreso = duracion.inMilliseconds == 0
                          ? 0.0
                          : (actual.inMilliseconds / duracion.inMilliseconds)
                              .clamp(0.0, 1.0);
                      return Row(
                        children: [
                          IconButton.filled(
                            tooltip: sonando && !termino ? 'Pausar' : 'Reproducir',
                            onPressed: () async {
                              if (termino) {
                                await reproductor.seek(Duration.zero);
                              }
                              sonando && !termino
                                  ? await reproductor.pause()
                                  : unawaited(reproductor.play());
                            },
                            icon: Icon(
                              sonando && !termino
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OndaAudio(
                              color: ColoresApp.acento.withValues(alpha: 0.35),
                              colorProgreso: ColoresApp.acento,
                              progreso: progreso,
                              semilla: widget.recuerdo.id.hashCode,
                              barras: 32,
                              altura: 48,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '${formatearDuracion(actual)} / '
                            '${formatearDuracion(duracion)}',
                            style: const TextStyle(color: ColoresApp.atenuado),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
      ),
    );
  }
}

class _AvisoMedio extends StatelessWidget {
  const _AvisoMedio(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: ColoresApp.primario.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(TemaApp.radioPequeno),
        ),
        child: Text(
          texto,
          style: const TextStyle(color: ColoresApp.sobrePrimario),
        ),
      );
}
