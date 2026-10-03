import 'package:flutter/material.dart';

import '../../../../nucleo/formato/fechas.dart';
import '../../../../nucleo/tema/colores_app.dart';
import '../../../elementos/dominio/tipo_elemento.dart';
import '../../dominio/filtro_recuerdos.dart';
import '../../dominio/validador_recuerdo.dart';

/// Chips de filtro: tipo (Fotos, Videos, Notas de voz, Notas) y rango de
/// fechas del recuerdo.
class BarraFiltrosRecuerdos extends StatelessWidget {
  const BarraFiltrosRecuerdos({
    super.key,
    required this.filtro,
    required this.hoy,
    required this.alCambiar,
  });

  final FiltroRecuerdos filtro;
  final DateTime hoy;
  final ValueChanged<FiltroRecuerdos> alCambiar;

  static String etiquetaPlural(TipoElemento tipo) => switch (tipo) {
        TipoElemento.foto => 'Fotos',
        TipoElemento.video => 'Videos',
        TipoElemento.audio => 'Notas de voz',
        TipoElemento.texto => 'Notas',
      };

  Future<void> _elegirFechas(BuildContext context) async {
    final ultimo = FiltroRecuerdos.soloDia(hoy);
    final desde = filtro.desde;
    final hasta = filtro.hasta;
    final rango = await showDateRangePicker(
      context: context,
      helpText: 'Fechas de los recuerdos',
      saveText: 'Aplicar',
      cancelText: 'Cancelar',
      firstDate: ValidadorRecuerdo.primeraFecha,
      lastDate: ultimo,
      initialDateRange: desde != null && hasta != null
          ? DateTimeRange(start: desde, end: hasta)
          : null,
    );
    if (rango == null) return;
    alCambiar(filtro.conFechas(rango.start, rango.end));
  }

  String _textoFechas() {
    final desde = filtro.desde;
    final hasta = filtro.hasta;
    if (desde == null && hasta == null) return 'Fechas';
    if (desde != null && hasta != null) {
      return '${formatearFechaCorta(desde)} – ${formatearFechaCorta(hasta)}';
    }
    return desde != null
        ? 'Desde ${formatearFechaCorta(desde)}'
        : 'Hasta ${formatearFechaCorta(hasta!)}';
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          ChoiceChip(
            label: const Text('Todos'),
            selected: filtro.tipos.isEmpty,
            onSelected: (_) => alCambiar(filtro.conTipos(const {})),
          ),
          for (final tipo in TipoElemento.values) ...[
            const SizedBox(width: 8),
            FilterChip(
              label: Text(etiquetaPlural(tipo)),
              selected: filtro.tipos.contains(tipo),
              onSelected: (_) => alCambiar(filtro.alternarTipo(tipo)),
            ),
          ],
          const SizedBox(width: 8),
          InputChip(
            key: const Key('filtro-fechas'),
            avatar: const Icon(
              Icons.date_range_outlined,
              size: 18,
              color: ColoresApp.acento,
            ),
            label: Text(_textoFechas()),
            selected: filtro.tieneFechas,
            onPressed: () => _elegirFechas(context),
            onDeleted: filtro.tieneFechas
                ? () => alCambiar(filtro.conFechas(null, null))
                : null,
            deleteButtonTooltipMessage: 'Quitar fechas',
          ),
        ],
      ),
    );
  }
}
