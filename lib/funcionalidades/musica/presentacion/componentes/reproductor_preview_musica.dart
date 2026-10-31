import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import '../../../../nucleo/componentes/avisos_emergentes.dart';
import '../../../../nucleo/tema/colores_app.dart';
import '../../aplicacion/coordinador_preview_musica.dart';
import '../../aplicacion/intentar_cargar_preview_con_refresco.dart';
import '../../aplicacion/preview_musica_compartido.dart';
import '../../aplicacion/proveedores_musica.dart';
import '../../dominio/fallo_musica.dart';
import '../../dominio/referencia_musica.dart';
import 'barra_progreso_preview.dart';

/// Play/pausa del preview de 30 s de una [ReferenciaMusica], en streaming.
class ReproductorPreviewMusica extends ConsumerStatefulWidget {
  const ReproductorPreviewMusica({
    super.key,
    required this.referencia,
    this.compacto = false,
    this.compartido,
    this.alQuitar,
  });

  final ReferenciaMusica referencia;
  final bool compacto;
  final PreviewMusicaCompartido? compartido;
  final VoidCallback? alQuitar;

  @override
  ConsumerState<ReproductorPreviewMusica> createState() =>
      ReproductorPreviewMusicaState();
}

class ReproductorPreviewMusicaState
    extends ConsumerState<ReproductorPreviewMusica> {
  AudioPlayer? _propio;
  StreamSubscription<PlayerState>? _suscripcion;
  late final CoordinadorPreviewMusica _coordinador;
  bool _cargando = false;
  bool _reproduciendo = false;
  bool _listo = false;
  bool _sinPreview = false;
  late ReferenciaMusica _referencia;

  AudioPlayer get _reproductor =>
      widget.compartido?.reproductor ?? (_propio ??= AudioPlayer());

  bool get _esActivo =>
      widget.compartido == null ||
      widget.compartido!.idActivo == _referencia.idExterno;

  bool get _disponible => _referencia.puedeReproducirPreview && !_sinPreview;

  @override
  void initState() {
    super.initState();
    _referencia = widget.referencia;
    _coordinador = ref.read(proveedorCoordinadorPreviewMusica);
    _suscripcion = _reproductor.playerStateStream.listen(_alCambiarEstado);
    widget.compartido?.addListener(_alCambiarCompartido);
  }

  void _alCambiarEstado(PlayerState estado) {
    if (!mounted) return;
    final activo = _esActivo && _listo;
    if (activo && estado.processingState == ProcessingState.completed) {
      unawaited(_reproductor.pause());
      unawaited(_reproductor.seek(Duration.zero));
    }
    final sonando = activo &&
        estado.playing &&
        estado.processingState != ProcessingState.completed;
    if (sonando != _reproduciendo) setState(() => _reproduciendo = sonando);
  }

  @override
  void didUpdateWidget(covariant ReproductorPreviewMusica oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.referencia != oldWidget.referencia) {
      _referencia = widget.referencia;
      _listo = false;
      _sinPreview = false;
    }
  }

  void _alCambiarCompartido() {
    if (!mounted) return;
    if (!_esActivo) {
      setState(() {
        _reproduciendo = false;
        _listo = false;
      });
    }
  }

  @override
  void dispose() {
    _suscripcion?.cancel();
    widget.compartido?.removeListener(_alCambiarCompartido);
    final propio = _propio;
    if (propio != null) {
      _coordinador.soltar(propio);
      unawaited(propio.dispose());
    }
    super.dispose();
  }

  /// Inicia el preview si se puede (p. ej. autoplay del visor).
  Future<void> reproducirSiPuede() async {
    if (_reproduciendo || _cargando || !_disponible) return;
    await _alternar();
  }

  Future<void> _alternar() async {
    if (!_disponible) return;
    if (_reproduciendo) {
      await _reproductor.pause();
      return;
    }
    await widget.compartido?.pausarSiNoEs(_referencia.idExterno);
    setState(() => _cargando = true);
    try {
      if (!_listo || !_esActivo) {
        final resultado = await intentarCargarPreviewConRefresco(
          _reproductor,
          _referencia,
          ref.read(proveedorRepositorioCatalogoMusica),
        );
        if (!mounted) return;
        _referencia = resultado.referencia;
        _listo = true;
        widget.compartido?.marcarActivo(_referencia.idExterno);
      }
      await _coordinador.tomar(_reproductor);
      unawaited(_reproductor.play());
    } on FalloMusica catch (fallo) {
      if (!mounted) return;
      if (fallo.tipo == TipoFalloMusica.sinPreview) {
        setState(() => _sinPreview = true);
      }
      mostrarAvisoInformativo(context, fallo.mensaje);
    } catch (error) {
      debugPrint('Capsoul: preview de música falló: $error');
      if (mounted) {
        mostrarAvisoInformativo(
          context,
          'No se pudo reproducir la vista previa.',
        );
      }
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Widget _icono({required double tamano, required bool relleno}) {
    if (_cargando) {
      return SizedBox(
        width: tamano * 0.8,
        height: tamano * 0.8,
        child: const CircularProgressIndicator(strokeWidth: 2),
      );
    }
    if (!_disponible) {
      return Icon(Icons.music_off_outlined,
          color: ColoresApp.navInactivo, size: tamano);
    }
    return Icon(
      _reproduciendo
          ? (relleno ? Icons.pause_circle_filled : Icons.pause)
          : (relleno ? Icons.play_circle : Icons.play_arrow),
      color: relleno ? ColoresApp.acento : ColoresApp.primario,
      size: tamano,
    );
  }

  @override
  Widget build(BuildContext context) {
    final tooltip = !_disponible
        ? 'Sin vista previa'
        : (_reproduciendo ? 'Pausar vista previa' : 'Escuchar vista previa');
    if (widget.compacto) {
      return IconButton(
        tooltip: tooltip,
        onPressed: !_disponible || _cargando ? null : _alternar,
        icon: _icono(tamano: 28, relleno: true),
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                _referencia.etiquetaCorta,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            if (!_disponible)
              const Text(
                'Sin vista previa',
                style: TextStyle(color: ColoresApp.atenuado, fontSize: 12),
              )
            else
              IconButton(
                tooltip: tooltip,
                onPressed: _cargando ? null : _alternar,
                icon: _icono(tamano: 24, relleno: false),
              ),
            if (widget.alQuitar != null)
              IconButton(
                tooltip: 'Quitar música',
                onPressed: widget.alQuitar,
                icon: const Icon(Icons.close),
              ),
          ],
        ),
        if (_listo && _esActivo)
          BarraProgresoPreview(
            reproductor: _reproductor,
            mostrarTiempos: false,
          ),
      ],
    );
  }
}
