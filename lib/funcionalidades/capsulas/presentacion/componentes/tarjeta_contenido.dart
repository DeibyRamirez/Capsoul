import 'package:flutter/material.dart';

import '../../../../nucleo/componentes/onda_audio.dart';
import '../../../../nucleo/tema/colores_app.dart';
import '../../../../nucleo/tema/tema_app.dart';
import '../../../elementos/dominio/tipo_elemento.dart';
import '../../../elementos/dominio/validador_medios.dart';
import '../../../recuerdos/dominio/recuerdo.dart';
import '../../../recuerdos/presentacion/componentes/miniatura_recuerdo_firmada.dart';

/// Tarjeta de un recuerdo en "Contenido": video (con duración), nota de voz
/// (con onda), foto o nota. Fotos y videos muestran la miniatura firmada.
class TarjetaContenido extends StatelessWidget {
  const TarjetaContenido({
    super.key,
    required this.elemento,
    required this.alTocar,
  });

  final Recuerdo elemento;
  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) {
    final duracion = elemento.duracion;
    final pie = switch (elemento.tipo) {
      TipoElemento.video ||
      TipoElemento.audio =>
        duracion == null ? null : formatearDuracion(duracion),
      _ => null,
    };
    return Semantics(
      button: true,
      label: '${elemento.tipo.etiqueta}: ${elemento.nombre}',
      child: InkWell(
        borderRadius: BorderRadius.circular(TemaApp.radioMediano),
        onTap: alTocar,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(
              aspectRatio: 1.35,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(TemaApp.radioMediano),
                child: _Portada(elemento: elemento),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: Text(
                    elemento.nombre,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: ColoresApp.sobreSuperficie,
                    ),
                  ),
                ),
                if (pie != null)
                  Text(pie, style: const TextStyle(color: ColoresApp.atenuado)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Portada extends StatelessWidget {
  const _Portada({required this.elemento});

  final Recuerdo elemento;

  @override
  Widget build(BuildContext context) {
    return switch (elemento.tipo) {
      TipoElemento.video ||
      TipoElemento.foto =>
        MiniaturaRecuerdoFirmada(recuerdo: elemento),
      TipoElemento.audio => ColoredBox(
          color: ColoresApp.acento.withValues(alpha: 0.15),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: OndaAudio(
              color: ColoresApp.acento.withValues(alpha: 0.45),
              colorProgreso: ColoresApp.acento,
              progreso: 0.35,
              semilla: elemento.id.hashCode,
              barras: 26,
              altura: 44,
            ),
          ),
        ),
      TipoElemento.texto => ColoredBox(
          color: ColoresApp.sobrePrimario,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              elemento.contenidoTexto ?? '',
              maxLines: 5,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: ColoresApp.sobreSuperficie,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ),
    };
  }
}
