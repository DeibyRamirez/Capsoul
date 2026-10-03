import 'package:flutter/material.dart';

import '../../../../nucleo/componentes/onda_audio.dart';
import '../../../../nucleo/tema/colores_app.dart';
import '../../../../nucleo/tema/tema_app.dart';
import '../../../elementos/dominio/tipo_elemento.dart';
import '../../../elementos/dominio/validador_medios.dart';
import '../../dominio/capsula.dart';

/// Tarjeta de un elemento en "Contenido": video (con duración), nota de voz
/// (con onda), foto o nota. Los medios se muestran como placeholder hasta
/// que exista la Edge Function `firmar-medio`.
class TarjetaContenido extends StatelessWidget {
  const TarjetaContenido({
    super.key,
    required this.elemento,
    required this.alTocar,
  });

  final ElementoCapsula elemento;
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
      label: elemento.tipo.etiqueta,
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
                    elemento.tipo.etiqueta,
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

  final ElementoCapsula elemento;

  @override
  Widget build(BuildContext context) {
    return switch (elemento.tipo) {
      TipoElemento.video => const _FondoMarino(
          child: _IconoCentral(Icons.play_arrow_rounded),
        ),
      TipoElemento.foto => const _FondoMarino(
          child: _IconoCentral(Icons.photo_outlined),
        ),
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

class _FondoMarino extends StatelessWidget {
  const _FondoMarino({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [ColoresApp.acento, ColoresApp.primario],
        ),
      ),
      child: Center(child: child),
    );
  }
}

class _IconoCentral extends StatelessWidget {
  const _IconoCentral(this.icono);

  final IconData icono;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: ColoresApp.sobrePrimario.withValues(alpha: 0.25),
        border: Border.all(color: ColoresApp.bordeCupula),
      ),
      child: Icon(icono, color: ColoresApp.sobrePrimario, size: 30),
    );
  }
}
