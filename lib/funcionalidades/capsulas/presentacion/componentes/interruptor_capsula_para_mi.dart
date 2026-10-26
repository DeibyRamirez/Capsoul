import 'package:flutter/material.dart';

import '../../../../nucleo/tema/colores_app.dart';

/// Incluye al autor entre los destinatarios.
///
/// Si queda como único destinatario, el feed la muestra en «Para mí mismo».
class InterruptorCapsulaParaMi extends StatelessWidget {
  const InterruptorCapsulaParaMi({
    super.key,
    required this.seleccionados,
    required this.uidActual,
    required this.alCambiar,
    this.deshabilitado = false,
  });

  final Set<String> seleccionados;
  final String? uidActual;
  final ValueChanged<Set<String>> alCambiar;
  final bool deshabilitado;

  @override
  Widget build(BuildContext context) {
    final uid = uidActual;
    if (uid == null || uid.isEmpty) return const SizedBox.shrink();
    final activo = seleccionados.contains(uid);
    return SwitchListTile(
      key: const Key('interruptor-para-mi'),
      contentPadding: EdgeInsets.zero,
      title: const Text('También para mí'),
      subtitle: const Text(
        'Si eres el único destinatario, la cápsula aparece en «Para mí mismo».',
        style: TextStyle(color: ColoresApp.atenuado),
      ),
      value: activo,
      onChanged: deshabilitado
          ? null
          : (valor) {
              final siguiente = {...seleccionados};
              if (valor) {
                siguiente.add(uid);
              } else {
                siguiente.remove(uid);
              }
              alCambiar(siguiente);
            },
    );
  }
}
