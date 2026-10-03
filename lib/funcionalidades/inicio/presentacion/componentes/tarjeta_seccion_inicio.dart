import 'package:flutter/material.dart';

import '../../../../nucleo/tema/colores_app.dart';
import '../../../../nucleo/tema/tema_app.dart';

/// Tarjeta de la rejilla de Inicio (Recuerdos, Retos, Cápsulas, Pequeñas
/// herencias) con conteo e ilustración.
class TarjetaSeccionInicio extends StatelessWidget {
  const TarjetaSeccionInicio({
    super.key,
    required this.icono,
    required this.titulo,
    required this.descripcion,
    required this.conteo,
    required this.etiquetaConteo,
    required this.ilustracion,
    required this.alTocar,
  });

  final IconData icono;
  final String titulo;
  final String descripcion;
  final int conteo;
  final String etiquetaConteo;
  final Widget ilustracion;
  final VoidCallback alTocar;

  /// Alto mínimo de la tarjeta; crece si el texto lo necesita.
  static const double altoMinimo = 168;

  @override
  Widget build(BuildContext context) {
    final estilos = Theme.of(context).textTheme;
    return Material(
      color: ColoresApp.sobrePrimario,
      borderRadius: BorderRadius.circular(TemaApp.radioGrande),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: alTocar,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: altoMinimo),
          child: Padding(
          padding: const EdgeInsets.all(14),
          child: Stack(
            children: [
              Positioned(right: 0, bottom: 0, child: ilustracion),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: ColoresApp.primario,
                          borderRadius:
                              BorderRadius.circular(TemaApp.radioPequeno),
                        ),
                        child: Icon(icono,
                            size: 18, color: ColoresApp.sobrePrimario),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          titulo,
                          style: estilos.titleSmall?.copyWith(
                            color: ColoresApp.primario,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Padding(
                    // Deja libre la ilustración de la esquina.
                    padding: const EdgeInsets.only(right: 44),
                    child: Text(
                      descripcion,
                      style: estilos.bodySmall?.copyWith(
                        color: ColoresApp.atenuado,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '$conteo',
                    style: estilos.titleLarge?.copyWith(
                      color: ColoresApp.primario,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    etiquetaConteo,
                    style: estilos.labelSmall?.copyWith(
                      color: ColoresApp.atenuado,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        ),
      ),
    );
  }
}

/// Ilustración placeholder: ícono grande dentro de un círculo degradado.
class IlustracionSeccion extends StatelessWidget {
  const IlustracionSeccion({super.key, required this.icono});

  final IconData icono;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            ColoresApp.acento.withValues(alpha: 0.35),
            ColoresApp.primario.withValues(alpha: 0.85),
          ],
        ),
      ),
      child: Icon(icono, color: ColoresApp.sobrePrimario, size: 28),
    );
  }
}
