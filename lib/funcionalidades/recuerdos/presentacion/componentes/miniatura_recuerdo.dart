import 'package:flutter/material.dart';

import '../../../../nucleo/componentes/onda_audio.dart';
import '../../../../nucleo/tema/colores_app.dart';
import '../../../elementos/dominio/tipo_elemento.dart';
import '../../dominio/recuerdo.dart';

/// Imagen pequeña de un recuerdo: degradado de marca con ícono, onda o
/// texto según el tipo. [imagen] (miniatura firmada) se dibuja encima si
/// existe.
class MiniaturaRecuerdo extends StatelessWidget {
  const MiniaturaRecuerdo({
    super.key,
    required this.recuerdo,
    this.imagen,
    this.tamanoIcono = 30,
  });

  final Recuerdo recuerdo;
  final Widget? imagen;
  final double tamanoIcono;

  @override
  Widget build(BuildContext context) {
    final imagenFirmada = imagen;
    return Stack(
      fit: StackFit.expand,
      children: [
        _Fondo(recuerdo: recuerdo, tamanoIcono: tamanoIcono),
        ?imagenFirmada,
        if (recuerdo.tipo == TipoElemento.video)
          Center(child: _IconoReproducir(tamano: tamanoIcono)),
        if (recuerdo.tieneMusica)
          const Positioned(
            right: 6,
            top: 6,
            child: Icon(Icons.music_note, color: ColoresApp.sobrePrimario, size: 20),
          ),
      ],
    );
  }
}

class _Fondo extends StatelessWidget {
  const _Fondo({required this.recuerdo, required this.tamanoIcono});

  final Recuerdo recuerdo;
  final double tamanoIcono;

  @override
  Widget build(BuildContext context) {
    return switch (recuerdo.tipo) {
      TipoElemento.texto => ColoredBox(
          color: ColoresApp.sobrePrimario,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              recuerdo.contenidoTexto ?? '',
              overflow: TextOverflow.fade,
              style: const TextStyle(
                color: ColoresApp.sobreSuperficie,
                fontStyle: FontStyle.italic,
                height: 1.3,
              ),
            ),
          ),
        ),
      TipoElemento.audio => ColoredBox(
          color: ColoresApp.acento.withValues(alpha: 0.15),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: OndaAudio(
              color: ColoresApp.acento.withValues(alpha: 0.45),
              colorProgreso: ColoresApp.acento,
              progreso: 0.35,
              semilla: recuerdo.id.hashCode,
              barras: 22,
              altura: 40,
            ),
          ),
        ),
      TipoElemento.musica => _PortadaMusica(recuerdo: recuerdo, tamanoIcono: tamanoIcono),
      TipoElemento.foto || TipoElemento.video => DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [ColoresApp.acento, ColoresApp.primario],
            ),
          ),
          child: recuerdo.tipo == TipoElemento.foto
              ? Icon(
                  Icons.photo_outlined,
                  color: ColoresApp.sobrePrimario.withValues(alpha: 0.8),
                  size: tamanoIcono,
                )
              : const SizedBox.expand(),
        ),
    };
  }
}

class _PortadaMusica extends StatelessWidget {
  const _PortadaMusica({required this.recuerdo, required this.tamanoIcono});

  final Recuerdo recuerdo;
  final double tamanoIcono;

  @override
  Widget build(BuildContext context) {
    final url = recuerdo.musica?.portadaUrl;
    if (url != null) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _iconoFallback(tamanoIcono),
      );
    }
    return _iconoFallback(tamanoIcono);
  }

  Widget _iconoFallback(double tamano) => ColoredBox(
        color: ColoresApp.acento.withValues(alpha: 0.2),
        child: Icon(Icons.music_note, size: tamano, color: ColoresApp.primario),
      );
}

class _IconoReproducir extends StatelessWidget {
  const _IconoReproducir({required this.tamano});

  final double tamano;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: ColoresApp.primario.withValues(alpha: 0.35),
        border: Border.all(color: ColoresApp.bordeCupula),
      ),
      child: Icon(
        Icons.play_arrow_rounded,
        color: ColoresApp.sobrePrimario,
        size: tamano,
      ),
    );
  }
}
