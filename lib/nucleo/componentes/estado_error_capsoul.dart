import 'package:flutter/material.dart';

import 'estado_vacio_capsoul.dart';
import 'ilustracion_capsoul.dart';

/// Error con ilustración y botón de reintento.
class EstadoErrorCapsoul extends StatelessWidget {
  const EstadoErrorCapsoul({
    super.key,
    required this.mensaje,
    this.alReintentar,
    this.ilustracion = NombresIlustracion.errorSinConexion,
  });

  final String mensaje;
  final VoidCallback? alReintentar;
  final String ilustracion;

  @override
  Widget build(BuildContext context) {
    final reintentar = alReintentar;
    return EstadoVacioCapsoul(
      mensaje: mensaje,
      ilustracion: ilustracion,
      icono: Icons.cloud_off_outlined,
      accion: reintentar == null
          ? null
          : OutlinedButton(
              onPressed: reintentar,
              child: const Text('Reintentar'),
            ),
    );
  }
}

/// Variante que ocupa el alto restante de un [CustomScrollView].
class SliverEstadoErrorCapsoul extends StatelessWidget {
  const SliverEstadoErrorCapsoul({
    super.key,
    required this.mensaje,
    this.alReintentar,
  });

  final String mensaje;
  final VoidCallback? alReintentar;

  @override
  Widget build(BuildContext context) {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: EstadoErrorCapsoul(
          mensaje: mensaje,
          alReintentar: alReintentar,
        ),
      ),
    );
  }
}
