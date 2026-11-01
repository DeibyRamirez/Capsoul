import 'package:flutter/material.dart';

/// Dirección desde la que entra un bloque de la presentación de Inicio.
enum DireccionEntradaInicio { izquierda, derecha, abajo }

/// Desliza y aparece [child] una sola vez al montar, como una diapositiva.
class EntradaPresentacionInicio extends StatefulWidget {
  const EntradaPresentacionInicio({
    super.key,
    required this.child,
    required this.direccion,
    this.retraso = Duration.zero,
  });

  final Widget child;
  final DireccionEntradaInicio direccion;
  final Duration retraso;

  static const Duration duracion = Duration(milliseconds: 450);

  @override
  State<EntradaPresentacionInicio> createState() =>
      _EstadoEntradaPresentacionInicio();
}

class _EstadoEntradaPresentacionInicio extends State<EntradaPresentacionInicio>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controlador;
  late final Animation<Offset> _desplazamiento;
  late final Animation<double> _opacidad;

  @override
  void initState() {
    super.initState();
    _controlador = AnimationController(
      vsync: this,
      duration: EntradaPresentacionInicio.duracion,
    );
    final origen = switch (widget.direccion) {
      DireccionEntradaInicio.izquierda => const Offset(-0.2, 0),
      DireccionEntradaInicio.derecha => const Offset(0.2, 0),
      DireccionEntradaInicio.abajo => const Offset(0, 0.25),
    };
    final curva = CurvedAnimation(
      parent: _controlador,
      curve: Curves.easeOutCubic,
    );
    _desplazamiento = Tween<Offset>(
      begin: origen,
      end: Offset.zero,
    ).animate(curva);
    _opacidad = Tween<double>(begin: 0, end: 1).animate(curva);
    WidgetsBinding.instance.addPostFrameCallback((_) => _iniciar());
  }

  void _iniciar() {
    if (!mounted) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      _controlador.value = 1;
      return;
    }
    Future<void>.delayed(widget.retraso, () {
      if (mounted) _controlador.forward();
    });
  }

  @override
  void dispose() {
    _controlador.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacidad,
      child: SlideTransition(position: _desplazamiento, child: widget.child),
    );
  }
}
