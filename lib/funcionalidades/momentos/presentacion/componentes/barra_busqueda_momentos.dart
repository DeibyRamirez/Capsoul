import 'package:flutter/material.dart';

import '../../../../nucleo/tema/colores_app.dart';
import '../../../../nucleo/tema/tema_app.dart';

/// Campo de búsqueda para filtrar momentos por título o descripción.
class BarraBusquedaMomentos extends StatefulWidget {
  const BarraBusquedaMomentos({
    super.key,
    required this.consulta,
    required this.alCambiar,
  });

  final String consulta;
  final ValueChanged<String> alCambiar;

  @override
  State<BarraBusquedaMomentos> createState() => _EstadoBarraBusquedaMomentos();
}

class _EstadoBarraBusquedaMomentos extends State<BarraBusquedaMomentos> {
  late final TextEditingController _controlador =
      TextEditingController(text: widget.consulta);

  @override
  void didUpdateWidget(covariant BarraBusquedaMomentos oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.consulta != _controlador.text) {
      _controlador.text = widget.consulta;
    }
  }

  @override
  void dispose() {
    _controlador.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controlador,
      onChanged: widget.alCambiar,
      decoration: InputDecoration(
        hintText: 'Buscar momentos...',
        prefixIcon: const Icon(Icons.search, color: ColoresApp.atenuado),
        suffixIcon: widget.consulta.isEmpty
            ? IconButton(
                tooltip: 'Filtros',
                onPressed: () {},
                icon: const Icon(Icons.tune, color: ColoresApp.atenuado),
              )
            : IconButton(
                tooltip: 'Limpiar',
                onPressed: () => widget.alCambiar(''),
                icon: const Icon(Icons.close, color: ColoresApp.atenuado),
              ),
        filled: true,
        fillColor: ColoresApp.sobrePrimario,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(TemaApp.radioGrande),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }
}
