import 'package:flutter/material.dart';
import '../../dominio/modo_captura.dart';
import '../tema/tokens_crear.dart';
import 'anillo_progreso_grabacion.dart';

/// Disparador de foto/video del hub (tap; video también admite long-press).
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

  @override
  Widget build(BuildContext context) {
    final tokens = tokensCrearDe(context);
    final duracion = duracionMotionCrear(context, const Duration(milliseconds: 200));
    final etiqueta = switch ((modo, grabando)) {
      (ModoCaptura.foto, _) => 'Tomar foto',
      (_, true) => 'Pausar grabación',
      _ => 'Iniciar grabación',
    };
  return Semantics(
      button: true,
      enabled: habilitado,
      label: etiqueta,
      hint: modo == ModoCaptura.video ? 'Toca para iniciar o pausar' : null,
      child: GestureDetector(
        onTap: habilitado ? alTap : null,
        onLongPressStart: habilitado && modo == ModoCaptura.video
            ? (_) => alInicioLongPress?.call()
            : null,
        onLongPressEnd: habilitado && modo == ModoCaptura.video
            ? (_) => alFinLongPress?.call()
            : null,
        child: AnimatedScale(
          scale: grabando ? 1.15 : 1,
          duration: duracion,
          curve: Curves.easeOutBack,
          child: SizedBox.square(
            dimension: tokens.tamanoBotonCaptura,
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (modo == ModoCaptura.video)
                  RepaintBoundary(
                    child: ValueListenableBuilder<double>(
                      valueListenable: progreso,
                      builder: (_, valor, __) => AnilloProgresoGrabacion(
                        progreso: valor,
                        color: tokens.marcaPrimario,
                        grosor: tokens.grosorAnillo,
                      ),
                    ),
                  ),
                AnimatedOpacity(
                  opacity: grabando ? 0 : 1,
                  duration: duracion,
                  child: _FormaInterior(
                    circular: true,
                    grabando: grabando,
                    modo: modo,
                    tokens: tokens,
                  ),
                ),
                AnimatedOpacity(
                  opacity: grabando ? 1 : 0,
                  duration: duracion,
                  child: _FormaInterior(
                    circular: false,
                    grabando: grabando,
                    modo: modo,
                    tokens: tokens,
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

class _FormaInterior extends StatelessWidget {
  const _FormaInterior({
    required this.circular,
    required this.grabando,
    required this.modo,
    required this.tokens,
  });

  final bool circular;
  final bool grabando;
  final ModoCaptura modo;
  final TokensCrear tokens;

  @override
  Widget build(BuildContext context) {
    final colorError = Theme.of(context).colorScheme.error;
    final interior = modo == ModoCaptura.video && grabando
        ? colorError
        : tokens.sobreMarca;
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: interior,
        borderRadius: BorderRadius.circular(circular ? 32 : 12),
      ),
    );
  }
}
