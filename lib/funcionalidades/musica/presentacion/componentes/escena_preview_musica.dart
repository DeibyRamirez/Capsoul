import 'dart:async';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import '../../../../nucleo/componentes/avisos_emergentes.dart';
import '../../../../nucleo/tema/colores_app.dart';
import '../../dominio/referencia_musica.dart';
import 'disco_portada_giratorio.dart';
import 'enlaces_escuchar_completo.dart';

/// Vista centrada: disco giratorio, metadatos y preview de 30 s (Spotify/Deezer).
class EscenaPreviewMusica extends StatefulWidget {
  const EscenaPreviewMusica({
    super.key,
    required this.referencia,
    this.reproducirAutomaticamente = false,
    this.alturaDisco,
    this.mostrarEnlacesCompletos = true,
    this.mostrarPieMetadata = true,
  });

  final ReferenciaMusica referencia;
  final bool reproducirAutomaticamente;
  final double? alturaDisco;
  final bool mostrarEnlacesCompletos;
  final bool mostrarPieMetadata;

  @override
  State<EscenaPreviewMusica> createState() => EscenaPreviewMusicaState();
}

class EscenaPreviewMusicaState extends State<EscenaPreviewMusica> {
  final AudioPlayer _reproductor = AudioPlayer();
  StreamSubscription<PlayerState>? _suscripcionEstado;
  bool _cargando = false;
  bool _reproduciendo = false;

  bool get _tienePreview => widget.referencia.tienePreview;

  @override
  void initState() {
    super.initState();
    _suscripcionEstado = _reproductor.playerStateStream.listen((estado) {
      if (!mounted) return;
      setState(() => _reproduciendo = estado.playing);
    });
    if (widget.reproducirAutomaticamente && _tienePreview) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _alternar());
    }
  }

  @override
  void dispose() {
    _suscripcionEstado?.cancel();
    unawaited(_reproductor.stop());
    _reproductor.dispose();
    super.dispose();
  }

  /// Detiene el preview antes de cerrar la pantalla (p. ej. al guardar).
  Future<void> pausarPreview() async {
    try {
      await _reproductor.stop();
    } catch (_) {
      // Ignorar si el player ya se liberó.
    }
    if (mounted) {
      setState(() {
        _reproduciendo = false;
        _cargando = false;
      });
    }
  }

  Future<void> _alternar() async {
    if (!_tienePreview || !mounted) return;
    final url = widget.referencia.previewUrl;
    if (url == null || url.isEmpty) return;

    if (_reproduciendo) {
      await _reproductor.pause();
      return;
    }

    setState(() => _cargando = true);
    try {
      if (_reproductor.audioSource == null) {
        await _reproductor.setUrl(url);
      }
      if (!mounted) return;
      await _reproductor.play();
    } catch (_) {
      if (mounted) {
        mostrarAvisoError(
          context,
          'No se pudo reproducir la vista previa. Intenta de nuevo.',
        );
      }
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    final alturaPantalla = MediaQuery.sizeOf(context).height;
    final tamanoDisco =
        widget.alturaDisco ?? (alturaPantalla * 0.42).clamp(200.0, 320.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: tamanoDisco + 24,
          child: Center(
            child: DiscoPortadaGiratorio(
              referencia: widget.referencia,
              girando: _reproduciendo,
              tamano: tamanoDisco,
              alTocar: _tienePreview && !_cargando ? _alternar : null,
            ),
          ),
        ),
        Text(
          widget.referencia.titulo,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: esquema.onSurface,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          widget.referencia.artista,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: esquema.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 12),
        if (!_tienePreview)
          Text(
            'No hay muestra de 30 s para esta pista. '
            'Puedes escucharla completa en tu plataforma favorita.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: esquema.onSurfaceVariant,
                ),
          )
        else
          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton.icon(
                    onPressed: _cargando ? null : _alternar,
                    icon: _cargando
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(
                            _reproduciendo
                                ? Icons.pause_circle
                                : Icons.play_circle,
                            color: ColoresApp.acento,
                            size: 28,
                          ),
                    label: Text(
                      _reproduciendo
                          ? 'Pausar vista previa'
                          : 'Reproducir vista previa',
                      style: const TextStyle(color: ColoresApp.acento),
                    ),
                  ),
                ],
              ),
              if (widget.referencia.previewProveedor ==
                  ProveedorPreviewMusica.deezer)
                Text(
                  widget.referencia.etiquetaPreview,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: esquema.onSurfaceVariant,
                      ),
                ),
            ],
          ),
        if (widget.mostrarEnlacesCompletos) ...[
          const SizedBox(height: 20),
          EnlacesEscucharCompleto(referencia: widget.referencia),
        ],
        if (widget.mostrarPieMetadata) ...[
          const SizedBox(height: 4),
          Text(
            'Música · ${widget.referencia.etiquetaCorta}',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: esquema.onSurfaceVariant,
                ),
          ),
        ],
      ],
    );
  }
}
