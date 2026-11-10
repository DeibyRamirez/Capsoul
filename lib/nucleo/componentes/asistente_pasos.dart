import 'package:flutter/material.dart';

import '../tema/colores_app.dart';

/// Asistente de varios pasos con indicador y botones Siguiente / Atrás.
class AsistentePasos extends StatefulWidget {
  const AsistentePasos({
    super.key,
    required this.etiquetasPasos,
    required this.pasos,
    required this.alTerminar,
    this.etiquetaFinal = 'Guardar',
    this.deshabilitado = false,
    this.cargando = false,
  });

  final List<String> etiquetasPasos;
  final List<Widget> pasos;
  final VoidCallback alTerminar;
  final String etiquetaFinal;
  final bool deshabilitado;
  final bool cargando;

  @override
  State<AsistentePasos> createState() => _EstadoAsistentePasos();
}

class _EstadoAsistentePasos extends State<AsistentePasos> {
  final _pagina = PageController();
  int _indice = 0;

  @override
  void dispose() {
    _pagina.dispose();
    super.dispose();
  }

  void _siguiente() {
    if (_indice >= widget.pasos.length - 1) {
      widget.alTerminar();
      return;
    }
    _pagina.nextPage(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
    setState(() => _indice++);
  }

  void _atras() {
    if (_indice == 0) return;
    _pagina.previousPage(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
    setState(() => _indice--);
  }

  @override
  Widget build(BuildContext context) {
    final ultimo = _indice >= widget.pasos.length - 1;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              for (var i = 0; i < widget.etiquetasPasos.length; i++) ...[
                if (i > 0)
                  Expanded(
                    child: Divider(
                      color: i <= _indice
                          ? ColoresApp.acento
                          : ColoresApp.bordeTarjeta,
                      thickness: 2,
                    ),
                  ),
                Semantics(
                  header: true,
                  label:
                      'Paso ${i + 1}: ${widget.etiquetasPasos[i]}',
                  selected: i == _indice,
                  child: Chip(
                    label: Text(widget.etiquetasPasos[i]),
                    backgroundColor: i == _indice
                        ? ColoresApp.acento.withValues(alpha: 0.15)
                        : null,
                    side: BorderSide(
                      color: i <= _indice
                          ? ColoresApp.acento
                          : ColoresApp.bordeTarjeta,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        Expanded(
          child: PageView(
            controller: _pagina,
            physics: const NeverScrollableScrollPhysics(),
            onPageChanged: (i) => setState(() => _indice = i),
            children: widget.pasos,
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Row(
            children: [
              if (_indice > 0)
                TextButton(
                  onPressed: widget.cargando ? null : _atras,
                  child: const Text('Atrás'),
                ),
              const Spacer(),
              FilledButton(
                onPressed: widget.deshabilitado || widget.cargando
                    ? null
                    : _siguiente,
                child: widget.cargando
                    ? const SizedBox.square(
                        dimension: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(ultimo ? widget.etiquetaFinal : 'Siguiente'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
