import 'package:flutter/material.dart';

import '../tema/tokens_crear.dart';

class ChipAccionHub extends StatelessWidget {
  const ChipAccionHub({
    super.key,
    required this.etiqueta,
    required this.icono,
    required this.alPresionar,
  });

  final String etiqueta;
  final IconData icono;
  final VoidCallback alPresionar;

  @override
  Widget build(BuildContext context) {
    final tokens = tokensCrearDe(context);
    return Semantics(
      button: true,
      label: etiqueta,
      child: ActionChip(
        avatar: Icon(icono, size: 18, color: tokens.marcaPrimario),
        label: Text(etiqueta),
        onPressed: alPresionar,
        backgroundColor: Colors.black.withValues(alpha: 0.35),
        labelStyle: TextStyle(
          color: tokens.superficieCamara,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        side: BorderSide.none,
        visualDensity: VisualDensity.compact,
        padding: const EdgeInsets.symmetric(horizontal: 4),
      ),
    );
  }
}
