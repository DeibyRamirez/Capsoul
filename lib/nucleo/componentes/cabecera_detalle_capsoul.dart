import 'package:flutter/material.dart';

import '../tema/colores_app.dart';
import '../tema/tema_app.dart';
import 'cielo_nocturno.dart';

/// Cabecera compacta de detalle con cielo nocturno y título serif.
class CabeceraDetalleCapsoul extends StatelessWidget {
  const CabeceraDetalleCapsoul({
    super.key,
    required this.titulo,
    this.subtitulo,
    this.trailing,
    this.mostrarAtras = true,
  });

  final String titulo;
  final String? subtitulo;
  final Widget? trailing;
  final bool mostrarAtras;

  @override
  Widget build(BuildContext context) {
    final estilos = Theme.of(context).textTheme;
    const blanco = ColoresApp.sobrePrimario;
    final subtitulo = this.subtitulo;
    final trailing = this.trailing;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(
        bottom: Radius.circular(TemaApp.radioGrande),
      ),
      child: CieloNocturno(
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (mostrarAtras) const BackButton(color: blanco),
                Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              titulo,
                              style: estilos.headlineMedium?.copyWith(
                                color: blanco,
                                fontFamily: 'serif',
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (subtitulo != null) ...[
                              const SizedBox(height: 6),
                              Text(
                                subtitulo,
                                style: estilos.titleMedium?.copyWith(
                                  color: blanco.withValues(alpha: 0.85),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      ?trailing,
                    ],
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
