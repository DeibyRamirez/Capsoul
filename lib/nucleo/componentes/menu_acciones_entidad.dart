import 'package:flutter/material.dart';

import '../tema/colores_app.dart';

/// Menú de acciones editar / eliminar (confirmación opcional).
class MenuAccionesEntidad extends StatelessWidget {
  const MenuAccionesEntidad({
    super.key,
    this.puedeEditar = false,
    this.puedeEliminar = false,
    this.alEditar,
    this.alEliminar,
    this.etiquetaEliminar = 'Eliminar',
    this.mensajeConfirmacion =
        'Esta acción no se puede deshacer. ¿Continuar?',
    this.tituloConfirmacion = '¿Eliminar?',
    this.cargando = false,
    this.pedirConfirmacionEliminar = true,
    this.compacto = false,
  });

  final bool puedeEditar;
  final bool puedeEliminar;
  final VoidCallback? alEditar;
  final VoidCallback? alEliminar;
  final String etiquetaEliminar;
  final String mensajeConfirmacion;
  final String tituloConfirmacion;
  final bool cargando;
  final bool pedirConfirmacionEliminar;

  /// En cabeceras estrechas usa [PopupMenuButton]; si no, menú expandible.
  final bool compacto;

  Future<void> _confirmarEliminar(BuildContext context) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (contexto) => AlertDialog(
        title: Text(tituloConfirmacion),
        content: Text(mensajeConfirmacion),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(contexto).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(contexto).pop(true),
            child: Text(etiquetaEliminar),
          ),
        ],
      ),
    );
    if (confirmado == true) alEliminar?.call();
  }

  void _eliminar(BuildContext context) {
    if (pedirConfirmacionEliminar) {
      _confirmarEliminar(context);
    } else {
      alEliminar?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!puedeEditar && !puedeEliminar) {
      return const SizedBox.shrink();
    }
    if (compacto) {
      return PopupMenuButton<String>(
        key: const Key('menu-acciones-ancla'),
        enabled: !cargando,
        onSelected: (valor) {
          if (valor == 'editar') alEditar?.call();
          if (valor == 'eliminar') _eliminar(context);
        },
        itemBuilder: (context) => [
          if (puedeEditar)
            const PopupMenuItem(
              value: 'editar',
              child: ListTile(
                leading: Icon(Icons.edit_outlined),
                title: Text('Editar'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          if (puedeEliminar)
            PopupMenuItem(
              value: 'eliminar',
              child: ListTile(
                leading: Icon(
                  Icons.delete_outline,
                  color: Theme.of(context).colorScheme.error,
                ),
                title: Text(
                  etiquetaEliminar,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                contentPadding: EdgeInsets.zero,
              ),
            ),
        ],
        icon: const Icon(Icons.more_vert),
      );
    }
    return _MenuExpandido(
      puedeEditar: puedeEditar,
      puedeEliminar: puedeEliminar,
      cargando: cargando,
      etiquetaEliminar: etiquetaEliminar,
      alEditar: alEditar,
      alEliminar: alEliminar == null ? null : () => _eliminar(context),
    );
  }
}

class _MenuExpandido extends StatefulWidget {
  const _MenuExpandido({
    required this.puedeEditar,
    required this.puedeEliminar,
    required this.cargando,
    required this.etiquetaEliminar,
    this.alEditar,
    this.alEliminar,
  });

  final bool puedeEditar;
  final bool puedeEliminar;
  final bool cargando;
  final String etiquetaEliminar;
  final VoidCallback? alEditar;
  final VoidCallback? alEliminar;

  @override
  State<_MenuExpandido> createState() => _EstadoMenuExpandido();
}

class _EstadoMenuExpandido extends State<_MenuExpandido> {
  bool _expandido = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        IconButton(
          key: const Key('menu-acciones-ancla'),
          tooltip: 'Acciones',
          onPressed: widget.cargando
              ? null
              : () => setState(() => _expandido = !_expandido),
          icon: AnimatedRotation(
            turns: _expandido ? 0.25 : 0,
            duration: const Duration(milliseconds: 200),
            child: const Icon(Icons.more_vert),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeInOut,
          alignment: Alignment.topRight,
          child: _expandido
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (widget.puedeEditar)
                      _FilaAccion(
                        icono: Icons.edit_outlined,
                        etiqueta: 'Editar',
                        alTocar: widget.cargando ? null : widget.alEditar,
                      ),
                    if (widget.puedeEliminar)
                      _FilaAccion(
                        icono: Icons.delete_outline,
                        etiqueta: widget.etiquetaEliminar,
                        color: Theme.of(context).colorScheme.error,
                        alTocar: widget.cargando ? null : widget.alEliminar,
                      ),
                  ],
                )
              : const SizedBox(width: 48),
        ),
      ],
    );
  }
}

class _FilaAccion extends StatelessWidget {
  const _FilaAccion({
    required this.icono,
    required this.etiqueta,
    required this.alTocar,
    this.color,
  });

  final IconData icono;
  final String etiqueta;
  final VoidCallback? alTocar;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ColoresApp.tarjeta,
      borderRadius: BorderRadius.circular(12),
      elevation: 1,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: alTocar,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icono, size: 20, color: color ?? ColoresApp.textoPrincipal),
              const SizedBox(width: 8),
              Text(
                etiqueta,
                style: TextStyle(
                  color: color ?? ColoresApp.textoPrincipal,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
