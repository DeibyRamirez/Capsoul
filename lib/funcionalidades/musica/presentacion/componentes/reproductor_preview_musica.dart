import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import '../../../../nucleo/componentes/avisos_emergentes.dart';
import '../../../../nucleo/tema/colores_app.dart';
import '../../dominio/referencia_musica.dart';

/// Reproduce el preview de 30 s de una [ReferenciaMusica] (URL de Spotify).
class ReproductorPreviewMusica extends StatefulWidget {
  const ReproductorPreviewMusica({
    super.key,
    required this.referencia,
    this.compacto = false,
  });

  final ReferenciaMusica referencia;
  final bool compacto;

  @override
  State<ReproductorPreviewMusica> createState() =>
      _EstadoReproductorPreviewMusica();
}

class _EstadoReproductorPreviewMusica extends State<ReproductorPreviewMusica> {
  final AudioPlayer _reproductor = AudioPlayer();
  bool _cargando = false;
  bool _reproduciendo = false;

  @override
  void initState() {
    super.initState();
    _reproductor.playerStateStream.listen((estado) {
      if (!mounted) return;
      setState(() => _reproduciendo = estado.playing);
    });
  }

  @override
  void dispose() {
    _reproductor.dispose();
    super.dispose();
  }

  Future<void> _alternar() async {
    if (!widget.referencia.tienePreview) return;
    final url = widget.referencia.previewUrl!;
    if (_reproduciendo) {
      await _reproductor.pause();
      return;
    }
    setState(() => _cargando = true);
    try {
      if (_reproductor.audioSource == null) {
        await _reproductor.setUrl(url);
      }
      await _reproductor.play();
    } catch (_) {
      if (mounted) {
        mostrarAvisoError(
          context,
          'No se pudo reproducir la vista previa.',
        );
      }
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sinPreview = !widget.referencia.tienePreview;
    if (widget.compacto) {
      return IconButton(
        tooltip: sinPreview ? 'Sin vista previa' : 'Escuchar vista previa',
        onPressed: sinPreview || _cargando ? null : _alternar,
        icon: _cargando
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(
                _reproduciendo ? Icons.pause_circle_filled : Icons.play_circle,
                color: ColoresApp.acento,
              ),
      );
    }
    return Row(
      children: [
        Expanded(
          child: Text(
            widget.referencia.etiquetaCorta,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        if (sinPreview)
          const Text(
            'Sin vista previa',
            style: TextStyle(color: ColoresApp.atenuado, fontSize: 12),
          )
        else
          IconButton(
            onPressed: _cargando ? null : _alternar,
            icon: _cargando
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(
                    _reproduciendo ? Icons.pause : Icons.play_arrow,
                    color: ColoresApp.primario,
                  ),
          ),
      ],
    );
  }
}
