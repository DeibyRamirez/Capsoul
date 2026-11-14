import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../dominio/modo_captura.dart';
import '../tema/tokens_crear.dart';

/// Carrusel horizontal de modos Foto / Video / Texto.
class SelectorModoCaptura extends StatelessWidget {
  const SelectorModoCaptura({
    super.key,
    required this.modos,
    required this.seleccionado,
    required this.alCambiar,
    this.bloqueado = false,
  });

  final List<ModoCaptura> modos;
  final ModoCaptura seleccionado;
  final ValueChanged<ModoCaptura> alCambiar;
  final bool bloqueado;

  @override
  Widget build(BuildContext context) {
    final tokens = tokensCrearDe(context);
    return GestureDetector(
      onHorizontalDragEnd: bloqueado
          ? null
          : (detalles) {
              final indice = modos.indexOf(seleccionado);
              final velocidad = detalles.primaryVelocity ?? 0;
              if (velocidad < -200 && indice < modos.length - 1) {
                _elegir(modos[indice + 1]);
              }
              if (velocidad > 200 && indice > 0) {
                _elegir(modos[indice - 1]);
              }
            },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (final modo in modos)
            Semantics(
              button: true,
              selected: modo == seleccionado,
              label: modo.etiqueta,
              child: InkWell(
                onTap: bloqueado ? null : () => _elegir(modo),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minWidth: tokens.objetivoTactilMin + 16,
                    minHeight: tokens.objetivoTactilMin,
                  ),
                  child: Center(
                    child: Text(
                      modo.etiqueta,
                      style: TextStyle(
                        color: modo == seleccionado
                            ? tokens.superficieCamara
                            : tokens.superficieCamaraAtenuada,
                        fontWeight: modo == seleccionado
                            ? FontWeight.w700
                            : FontWeight.w500,
                        fontSize: 15,
                        shadows: const [
                          Shadow(blurRadius: 4, color: Colors.black54),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _elegir(ModoCaptura modo) {
    HapticFeedback.selectionClick();
    alCambiar(modo);
  }
}
