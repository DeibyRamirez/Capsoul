import 'package:flutter/material.dart';

import '../../../../nucleo/formato/fechas.dart';
import '../../../../nucleo/tema/colores_app.dart';
import '../../../../nucleo/tema/tema_app.dart';
import '../../../elementos/dominio/validador_medios.dart';
import '../../dominio/recuerdo.dart';
import 'miniatura_recuerdo_firmada.dart';

/// Tarjeta de la rejilla de recuerdos. Con [seleccionado] distinto de `null`
/// muestra la marca de selección (pantalla "Elegir recuerdos").
class TarjetaRecuerdo extends StatelessWidget {
  const TarjetaRecuerdo({
    super.key,
    required this.recuerdo,
    required this.alTocar,
    this.seleccionado,
  });

  final Recuerdo recuerdo;
  final VoidCallback alTocar;
  final bool? seleccionado;

  @override
  Widget build(BuildContext context) {
    final duracion = recuerdo.duracion;
    final marcado = seleccionado ?? false;
    return Semantics(
      button: true,
      selected: seleccionado,
      label: '${recuerdo.tipo.etiqueta}: ${recuerdo.nombre}',
      child: Material(
        color: ColoresApp.sobrePrimario,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(TemaApp.radioGrande),
          side: BorderSide(
            color: ColoresApp.atenuado.withValues(alpha: 0.12),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: alTocar,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AspectRatio(
                aspectRatio: 1,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    MiniaturaRecuerdoFirmada(recuerdo: recuerdo),
                    if (duracion != null)
                      Positioned(
                        right: 6,
                        bottom: 6,
                        child: _Etiqueta(formatearDuracion(duracion)),
                      ),
                    if (seleccionado != null)
                      Positioned(
                        top: 6,
                        right: 6,
                        child: _MarcaSeleccion(marcado: marcado),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recuerdo.nombre,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: ColoresApp.sobreSuperficie,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      formatearFechaCorta(recuerdo.fechaRecuerdo),
                      style: const TextStyle(
                        fontSize: 12,
                        color: ColoresApp.atenuado,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Etiqueta extends StatelessWidget {
  const _Etiqueta(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: ColoresApp.primario.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        texto,
        style: const TextStyle(fontSize: 11, color: ColoresApp.sobrePrimario),
      ),
    );
  }
}

class _MarcaSeleccion extends StatelessWidget {
  const _MarcaSeleccion({required this.marcado});

  final bool marcado;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: marcado
            ? ColoresApp.acento
            : ColoresApp.primario.withValues(alpha: 0.3),
        border: Border.all(color: ColoresApp.sobrePrimario, width: 2),
      ),
      child: marcado
          ? const Icon(Icons.check, size: 16, color: ColoresApp.sobrePrimario)
          : null,
    );
  }
}
