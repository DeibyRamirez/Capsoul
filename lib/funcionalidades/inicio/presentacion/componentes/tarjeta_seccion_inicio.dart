import 'package:flutter/material.dart';

import '../../../../nucleo/componentes/tarjeta_capsoul.dart';
import '../../../../nucleo/tema/colores_app.dart';

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
    return TarjetaCapsoul(
      icono: icono,
      titulo: titulo,
      alTocar: alTocar,
      altoMinimo: altoMinimo,
      child: Stack(
        children: [
          Positioned(right: 0, bottom: 0, child: ilustracion),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
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
      child: Icon(icono, color: ColoresApp.sobrePrimario, size: 25),
    );
  }
}
