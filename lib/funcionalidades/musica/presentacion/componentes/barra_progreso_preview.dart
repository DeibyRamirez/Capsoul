import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import '../../../../nucleo/tema/colores_app.dart';

/// Progreso del preview (posición / duración, máximo ~30 s).
class BarraProgresoPreview extends StatelessWidget {
  const BarraProgresoPreview({
    super.key,
    required this.reproductor,
    this.mostrarTiempos = true,
  });

  final AudioPlayer reproductor;
  final bool mostrarTiempos;

  static const _duracionPorDefecto = Duration(seconds: 30);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Duration>(
      stream: reproductor.positionStream,
      builder: (context, instantanea) {
        final total = reproductor.duration ?? _duracionPorDefecto;
        final posicion = instantanea.data ?? Duration.zero;
        final valor = total.inMilliseconds <= 0
            ? 0.0
            : (posicion.inMilliseconds / total.inMilliseconds).clamp(0.0, 1.0);
        final barra = ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: valor,
            minHeight: 4,
            color: ColoresApp.acento,
            backgroundColor: ColoresApp.bordeTarjeta,
            semanticsLabel: 'Progreso de la vista previa',
          ),
        );
        if (!mostrarTiempos) return barra;
        final estilo = Theme.of(context)
            .textTheme
            .labelSmall
            ?.copyWith(color: ColoresApp.textoSecundario);
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            barra,
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(formatearTiempoPreview(posicion), style: estilo),
                Text(formatearTiempoPreview(total), style: estilo),
              ],
            ),
          ],
        );
      },
    );
  }
}

/// `0:07`, `0:30`.
String formatearTiempoPreview(Duration duracion) {
  final segundos = duracion.inSeconds;
  final minutos = segundos ~/ 60;
  final resto = (segundos % 60).toString().padLeft(2, '0');
  return '$minutos:$resto';
}
