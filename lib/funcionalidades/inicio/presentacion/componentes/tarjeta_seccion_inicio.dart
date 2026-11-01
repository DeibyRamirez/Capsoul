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
          Padding(
            padding: const EdgeInsets.only(right: 68),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  descripcion,
                  style: estilos.bodySmall?.copyWith(
                    color: ColoresApp.atenuado,
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
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: IgnorePointer(child: ilustracion),
          ),
        ],
      ),
    );
  }
}

/// Ilustración PNG transparente en la esquina de la tarjeta.
class IlustracionSeccion extends StatelessWidget {
  const IlustracionSeccion({super.key, required this.rutaAsset});

  final String rutaAsset;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 72,
      height: 72,
      child: Image.asset(
        rutaAsset,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.medium,
        cacheWidth: 216,
        errorBuilder: (_, _, _) => const _FallbackIlustracionSeccion(),
      ),
    );
  }
}

/// Respaldo si falta el asset en el bundle.
class _FallbackIlustracionSeccion extends StatelessWidget {
  const _FallbackIlustracionSeccion();

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
          colors: [ColoresApp.fondoInicio, ColoresApp.bordeTarjeta],
        ),
      ),
      child: const Icon(
        Icons.image_outlined,
        color: ColoresApp.primario,
        size: 25,
      ),
    );
  }
}
