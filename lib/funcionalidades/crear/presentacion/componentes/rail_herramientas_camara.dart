import 'package:flutter/material.dart';

import '../tema/tokens_crear.dart';

class ItemRailCamara {
  const ItemRailCamara({
    required this.icono,
    required this.etiqueta,
    required this.alPresionar,
    this.activo = false,
  });

  final IconData icono;
  final String etiqueta;
  final VoidCallback? alPresionar;
  final bool activo;
}

/// Columna de herramientas a la derecha del preview.
class RailHerramientasCamara extends StatelessWidget {
  const RailHerramientasCamara({
    super.key,
    required this.items,
    this.oculto = false,
  });

  final List<ItemRailCamara> items;
  final bool oculto;

  @override
  Widget build(BuildContext context) {
    final tokens = tokensCrearDe(context);
    return AnimatedOpacity(
      opacity: oculto ? 0 : 1,
      duration: duracionMotionCrear(context, const Duration(milliseconds: 200)),
      child: IgnorePointer(
        ignoring: oculto,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final item in items) ...[
              _BotonRail(tokens: tokens, item: item),
              const SizedBox(height: 16),
            ],
          ],
        ),
      ),
    );
  }
}

class _BotonRail extends StatelessWidget {
  const _BotonRail({required this.tokens, required this.item});

  final TokensCrear tokens;
  final ItemRailCamara item;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: item.etiqueta,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: item.alPresionar,
        child: SizedBox(
          width: tokens.objetivoTactilMin,
          height: tokens.objetivoTactilMin,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black.withValues(alpha: 0.3),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Icon(
                    item.icono,
                    size: 26,
                    color: tokens.superficieCamara,
                    shadows: const [
                      Shadow(blurRadius: 4, color: Colors.black54),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                item.etiqueta,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: tokens.superficieCamara,
                  shadows: const [
                    Shadow(blurRadius: 4, color: Colors.black54),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
