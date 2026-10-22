import 'package:flutter/material.dart';

import '../tema/colores_app.dart';
import '../tema/espaciado_app.dart';
import '../tema/tipografia_app.dart';
import 'ilustracion_capsoul.dart';

/// Estado vacío con ilustración (o icono si el PNG aún no existe).
class EstadoVacioCapsoul extends StatelessWidget {
  const EstadoVacioCapsoul({
    super.key,
    required this.mensaje,
    required this.ilustracion,
    this.icono = Icons.inbox_outlined,
    this.accion,
  });

  final String mensaje;
  final String ilustracion;
  final IconData icono;
  final Widget? accion;

  @override
  Widget build(BuildContext context) {
    final boton = accion;
    return Padding(
      padding: const EdgeInsets.all(EspaciadoApp.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          IlustracionCapsoul(
            nombre: ilustracion,
            ancho: 160,
            alto: 140,
            fallback: Icon(icono, size: 56, color: ColoresApp.acento),
          ),
          const SizedBox(height: EspaciadoApp.md),
          Text(
            mensaje,
            textAlign: TextAlign.center,
            style: TipografiaApp.cuerpoPequeno,
          ),
          if (boton != null) ...[
            const SizedBox(height: EspaciadoApp.md),
            boton,
          ],
        ],
      ),
    );
  }
}

/// Estado vacío dentro de un sliver.
class SliverEstadoVacioCapsoul extends StatelessWidget {
  const SliverEstadoVacioCapsoul({
    super.key,
    required this.mensaje,
    required this.ilustracion,
    this.icono = Icons.inbox_outlined,
    this.accion,
  });

  final String mensaje;
  final String ilustracion;
  final IconData icono;
  final Widget? accion;

  @override
  Widget build(BuildContext context) {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: EstadoVacioCapsoul(
          mensaje: mensaje,
          ilustracion: ilustracion,
          icono: icono,
          accion: accion,
        ),
      ),
    );
  }
}
