import 'package:flutter/material.dart';

/// Acción principal a todo el ancho. Queda deshabilitada y muestra un
/// indicador de progreso mientras [cargando] es `true`.
class BotonPrincipal extends StatelessWidget {
  const BotonPrincipal({
    super.key,
    required this.etiqueta,
    required this.alPresionar,
    this.cargando = false,
  });

  final String etiqueta;
  final VoidCallback? alPresionar;
  final bool cargando;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: FilledButton(
        onPressed: cargando ? null : alPresionar,
        child: cargando
            ? Semantics(
                label: etiqueta,
                child: SizedBox.square(
                  dimension: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              )
            : Text(etiqueta),
      ),
    );
  }
}
