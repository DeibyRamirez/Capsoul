import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../nucleo/componentes/tarjeta_capsoul.dart';
import '../../../../nucleo/tema/colores_app.dart';

/// Tarjeta de la rejilla de Inicio (Recuerdos, Retos, Cápsulas, Pequeñas
/// herencias) con conteo e ilustración.
class TarjetaSeccionInicio extends StatefulWidget {
  const TarjetaSeccionInicio({
    super.key,
    required this.icono,
    required this.titulo,
    required this.descripcion,
    required this.conteo,
    required this.etiquetaConteo,
    required this.ilustracion,
    required this.alTocar,
    this.heroTag,
  });

  final IconData icono;
  final String titulo;
  final String descripcion;
  final int conteo;
  final String etiquetaConteo;
  final Widget ilustracion;
  final VoidCallback alTocar;
  final String? heroTag;

  /// Alto mínimo de la tarjeta; crece si el texto lo necesita.
  static const double altoMinimo = 168;

  @override
  State<TarjetaSeccionInicio> createState() => _EstadoTarjetaSeccionInicio();
}

class _EstadoTarjetaSeccionInicio extends State<TarjetaSeccionInicio> {
  bool _pulsado = false;

  void _marcar(bool valor) {
    if (_pulsado == valor) return;
    setState(() => _pulsado = valor);
  }

  void _alTocar() {
    HapticFeedback.lightImpact();
    widget.alTocar();
  }

  @override
  Widget build(BuildContext context) {
    final estilos = Theme.of(context).textTheme;
    final heroTag = widget.heroTag;
    Widget tarjeta = Listener(
      onPointerDown: (_) => _marcar(true),
      onPointerUp: (_) => _marcar(false),
      onPointerCancel: (_) => _marcar(false),
      child: AnimatedScale(
        scale: _pulsado ? 0.96 : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: TarjetaCapsoul(
          icono: widget.icono,
          titulo: widget.titulo,
          alTocar: _alTocar,
          altoMinimo: TarjetaSeccionInicio.altoMinimo,
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 68),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.descripcion,
                      style: estilos.bodySmall?.copyWith(
                        color: ColoresApp.atenuado,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '${widget.conteo}',
                      style: estilos.titleLarge?.copyWith(
                        color: ColoresApp.primario,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      widget.etiquetaConteo,
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
                child: IgnorePointer(child: widget.ilustracion),
              ),
            ],
          ),
        ),
      ),
    );
    if (heroTag == null) return tarjeta;
    return Hero(
      tag: heroTag,
      child: Material(type: MaterialType.transparency, child: tarjeta),
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
