import 'package:flutter/material.dart';

import '../../../../nucleo/tema/colores_app.dart';
import '../../../../nucleo/tema/tema_app.dart';
import '../../dominio/referencia_musica.dart';

/// Portada circular estilo vinilo; gira cuando [girando] es true.
class DiscoPortadaGiratorio extends StatefulWidget {
  const DiscoPortadaGiratorio({
    super.key,
    required this.referencia,
    required this.girando,
    this.tamano = 240,
    this.alTocar,
  });

  final ReferenciaMusica referencia;
  final bool girando;
  final double tamano;
  final VoidCallback? alTocar;

  @override
  State<DiscoPortadaGiratorio> createState() => _EstadoDiscoPortadaGiratorio();
}

class _EstadoDiscoPortadaGiratorio extends State<DiscoPortadaGiratorio>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controlador = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 8),
  );

  @override
  void didUpdateWidget(covariant DiscoPortadaGiratorio oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sincronizarAnimacion();
  }

  @override
  void initState() {
    super.initState();
    _sincronizarAnimacion();
  }

  void _sincronizarAnimacion() {
    if (widget.girando) {
      if (!_controlador.isAnimating) {
        _controlador.repeat();
      }
    } else {
      _controlador.stop();
    }
  }

  @override
  void dispose() {
    _controlador.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tamano = widget.tamano;
    final agujero = tamano * 0.18;

    Widget disco = SizedBox(
      width: tamano,
      height: tamano,
      child: RotationTransition(
        turns: _controlador,
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: ColoresApp.primario.withValues(alpha: 0.25),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
            border: Border.all(
              color: ColoresApp.primario.withValues(alpha: 0.35),
              width: 3,
            ),
          ),
          child: ClipOval(child: _Portada(referencia: widget.referencia)),
        ),
      ),
    );

    disco = Stack(
      alignment: Alignment.center,
      children: [
        disco,
        IgnorePointer(
          child: Container(
            width: agujero,
            height: agujero,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: ColoresApp.superficie,
              border: Border.all(
                color: ColoresApp.primario.withValues(alpha: 0.5),
                width: 2,
              ),
            ),
          ),
        ),
      ],
    );

    if (widget.alTocar != null) {
      disco = Material(
        color: Colors.transparent,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: widget.alTocar,
          child: disco,
        ),
      );
    }

    return disco;
  }
}

class _Portada extends StatelessWidget {
  const _Portada({required this.referencia});

  final ReferenciaMusica referencia;

  @override
  Widget build(BuildContext context) {
    final url = referencia.portadaUrl;
    if (url == null) {
      return DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              ColoresApp.acento.withValues(alpha: 0.35),
              ColoresApp.primario.withValues(alpha: 0.85),
            ],
          ),
        ),
        child: const Center(
          child: Icon(
            Icons.album_outlined,
            size: 72,
            color: ColoresApp.sobrePrimario,
          ),
        ),
      );
    }
    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => DecoratedBox(
        decoration: BoxDecoration(
          color: ColoresApp.acento.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(TemaApp.radioMediano),
        ),
        child: const Center(
          child: Icon(Icons.music_note, size: 64, color: ColoresApp.primario),
        ),
      ),
    );
  }
}
