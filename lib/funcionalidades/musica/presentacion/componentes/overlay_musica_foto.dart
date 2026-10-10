import 'package:flutter/material.dart';

import '../../../../nucleo/tema/colores_app.dart';
import '../../dominio/referencia_musica.dart';
import 'reproductor_preview_musica.dart';

/// Franja inferior sobre una foto con la pista adjunta (estilo historia).
class OverlayMusicaFoto extends StatelessWidget {
  const OverlayMusicaFoto({super.key, required this.referencia});

  final ReferenciaMusica referencia;

  @override
  Widget build(BuildContext context) {
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
                  child: Image.network(
                    referencia.portadaUrl!,
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
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
              ReproductorPreviewMusica(referencia: referencia, compacto: true),
            ],
          ),
        ),
      ),
    );
  }
}
