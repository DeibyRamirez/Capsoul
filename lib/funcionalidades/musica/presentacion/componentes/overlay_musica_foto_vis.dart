import 'package:flutter/material.dart';

import '../../../../nucleo/componentes/imagen_red_capsoul.dart';
import '../../../../nucleo/tema/colores_app.dart';
import '../../aplicacion/preview_musica_compartido.dart';
import '../../dominio/referencia_musica.dart';
import 'reproductor_preview_musica.dart';

/// Franja musical sobre foto en el visor, con preview compartido y autoplay.
class OverlayMusicaFotoVis extends StatefulWidget {
  const OverlayMusicaFotoVis({
    super.key,
    required this.referencia,
    required this.previewMusica,
    this.reproducirAutomaticamente = false,
  });

  final ReferenciaMusica referencia;
  final PreviewMusicaCompartido previewMusica;
  final bool reproducirAutomaticamente;

  @override
  State<OverlayMusicaFotoVis> createState() => _EstadoOverlayMusicaFotoVis();
}

class _EstadoOverlayMusicaFotoVis extends State<OverlayMusicaFotoVis> {
  final _claveReproductor = GlobalKey<ReproductorPreviewMusicaState>();

  @override
  void initState() {
    super.initState();
    if (widget.reproducirAutomaticamente && widget.referencia.tienePreview) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _claveReproductor.currentState?.reproducirSiPuede();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final referencia = widget.referencia;
    return Positioned(
      left: 12,
      right: 12,
      bottom: 12,
      child: Material(
        color: ColoresApp.primario.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              if (referencia.portadaUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: ImagenRedCapsoul(
                    url: referencia.portadaUrl!,
                    ancho: 40,
                    alto: 40,
                  ),
                )
              else
                const Icon(Icons.music_note, color: ColoresApp.sobrePrimario),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      referencia.titulo,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: ColoresApp.sobrePrimario,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      referencia.artista,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: ColoresApp.sobrePrimario.withValues(alpha: 0.85),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              ReproductorPreviewMusica(
                key: _claveReproductor,
                referencia: referencia,
                compacto: true,
                compartido: widget.previewMusica,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
