import 'package:flutter/material.dart';

import '../tema/colores_app.dart';
import '../tema/degradados_capsoul.dart';
import '../tema/tema_app.dart';

/// Cabecera compacta de detalle sobre fondo claro con titulo Playfair.
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
    const texto = ColoresApp.textoPrincipal;
    final subtitulo = this.subtitulo;
    final trailing = this.trailing;

    return DecoratedBox(
      decoration: const BoxDecoration(gradient: DegradadosCapsoul.suave),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 4, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (mostrarAtras) const BackButton(color: texto),
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
                              color: texto,
                              fontFamily: TemaApp.fuenteTitulos,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (subtitulo != null) ...[
                            const SizedBox(height: 6),
                            Text(
                              subtitulo,
                              style: estilos.titleMedium?.copyWith(
                                color: ColoresApp.textoSecundario,
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
    );
  }
}
