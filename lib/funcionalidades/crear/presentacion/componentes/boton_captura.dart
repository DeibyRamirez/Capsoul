import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../dominio/modo_captura.dart';
import '../tema/tokens_crear.dart';
import 'anillo_progreso_grabacion.dart';

/// Disparador de foto/video del hub (tap; video también admite long-press).
///
/// Anillo exterior fijo (con el progreso del video) y un centro que, al
/// grabar, pasa con una animación suave de círculo a un cuadrado redondeado
/// más pequeño y centrado, al estilo de las apps de video cortos.
class BotonCaptura extends StatelessWidget {
  const BotonCaptura({
    super.key,
    required this.modo,
    required this.grabando,
    required this.progreso,
    this.alTap,
    this.alInicioLongPress,
    this.alFinLongPress,
    this.habilitado = true,
  });

  final ModoCaptura modo;
  final bool grabando;
  final ValueListenable<double> progreso;
  final VoidCallback? alTap;
  final VoidCallback? alInicioLongPress;
  final VoidCallback? alFinLongPress;
  final bool habilitado;

  /// Proporción del lado del cuadrado de grabación respecto al botón.
  static const double proporcionCuadrado = 0.4;

  /// Radio de las esquinas del cuadrado respecto a su lado.
  static const double proporcionEsquinas = 0.25;

  @override
  Widget build(BuildContext context) {
    final tokens = tokensCrearDe(context);
    final duracion =
        duracionMotionCrear(context, const Duration(milliseconds: 240));
    final esVideo = modo == ModoCaptura.video;
    final enGrabacion = esVideo && grabando;

    final tamano = tokens.tamanoBotonCaptura;
    final grosor = tokens.grosorAnillo;
    // Aire entre el anillo y el centro para que no se toquen.
    final separacion = grosor * 0.75;
    final diametroReposo = tamano - 2 * (grosor + separacion);
    final ladoGrabando = tamano * proporcionCuadrado;
    final lado = enGrabacion ? ladoGrabando : diametroReposo;
    final radio =
        enGrabacion ? ladoGrabando * proporcionEsquinas : diametroReposo / 2;
    final colorCentro =
        esVideo ? Theme.of(context).colorScheme.error : tokens.sobreMarca;

    final etiqueta = switch ((modo, grabando)) {
      (ModoCaptura.foto, _) => 'Tomar foto',
      (_, true) => 'Pausar grabación',
      _ => 'Iniciar grabación',
    };
    return Semantics(
      button: true,
      enabled: habilitado,
      label: etiqueta,
      hint: esVideo ? 'Toca para iniciar o pausar' : null,
      child: GestureDetector(
        onTap: habilitado ? alTap : null,
        onLongPressStart:
            habilitado && esVideo ? (_) => alInicioLongPress?.call() : null,
        onLongPressEnd:
            habilitado && esVideo ? (_) => alFinLongPress?.call() : null,
        child: AnimatedOpacity(
          opacity: habilitado ? 1 : 0.5,
          duration: duracion,
          child: SizedBox.square(
            key: const Key('boton-captura'),
            dimension: tamano,
            child: Stack(
              alignment: Alignment.center,
              children: [
                RepaintBoundary(
                  child: ValueListenableBuilder<double>(
                    valueListenable: progreso,
                    builder: (_, valor, _) => AnilloProgresoGrabacion(
                      progreso: esVideo ? valor : 0,
                      color: tokens.marcaPrimario,
                      colorPista: tokens.superficieCamaraAtenuada,
                      grosor: grosor,
                    ),
                  ),
                ),
                AnimatedContainer(
                  key: const Key('centro-boton-captura'),
                  duration: duracion,
                  curve: Curves.easeInOutCubic,
                  width: lado,
                  height: lado,
                  decoration: BoxDecoration(
                    color: colorCentro,
                    borderRadius: BorderRadius.circular(radio),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}