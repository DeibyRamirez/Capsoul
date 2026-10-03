import 'package:flutter/material.dart';

import '../../../../nucleo/componentes/frasco_luminoso.dart';
import '../../../../nucleo/tema/colores_app.dart';
import '../../../../nucleo/tema/tema_app.dart';
import 'cielo_nocturno.dart';

/// Cabecera del detalle: cielo nocturno, frasco, título, horizonte y
/// candado con la fecha de apertura.
class CabeceraCapsula extends StatelessWidget {
  const CabeceraCapsula({
    super.key,
    required this.titulo,
    required this.horizonte,
    required this.fechaApertura,
    required this.cuentaRegresiva,
    required this.sellada,
  });

  final String titulo;
  final String? horizonte;

  /// "13 ago 2046".
  final String? fechaApertura;
  final Widget? cuentaRegresiva;
  final bool sellada;

  @override
  Widget build(BuildContext context) {
    final estilos = Theme.of(context).textTheme;
    const blanco = ColoresApp.sobrePrimario;
    final horizonte = this.horizonte;
    final fechaApertura = this.fechaApertura;
    final cuentaRegresiva = this.cuentaRegresiva;
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(
        bottom: Radius.circular(TemaApp.radioGrande),
      ),
      child: CieloNocturno(
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const BackButton(color: blanco),
                Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              titulo,
                              style: estilos.headlineMedium?.copyWith(
                                color: blanco,
                                fontFamily: 'serif',
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (horizonte != null) ...[
                              const SizedBox(height: 6),
                              Text(
                                horizonte,
                                style: estilos.titleMedium?.copyWith(
                                  color: blanco.withValues(alpha: 0.85),
                                ),
                              ),
                            ],
                            const SizedBox(height: 20),
                            if (fechaApertura != null)
                              _FilaCandado(
                                fecha: fechaApertura,
                                sellada: sellada,
                              ),
                            if (cuentaRegresiva != null) ...[
                              const SizedBox(height: 8),
                              DefaultTextStyle.merge(
                                style: estilos.bodySmall?.copyWith(
                                  color: blanco.withValues(alpha: 0.8),
                                ),
                                child: cuentaRegresiva,
                              ),
                            ],
                          ],
                        ),
                      ),
                      FrascoLuminoso(
                        tamano: 130,
                        brillo: sellada ? 0.55 : 0.95,
                        conCandado: sellada,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FilaCandado extends StatelessWidget {
  const _FilaCandado({required this.fecha, required this.sellada});

  final String fecha;
  final bool sellada;

  @override
  Widget build(BuildContext context) {
    const blanco = ColoresApp.sobrePrimario;
    return Row(
      children: [
        Icon(sellada ? Icons.lock_outline : Icons.lock_open_outlined,
            color: blanco, size: 22),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              sellada ? 'Abrir en' : 'Se abrió el',
              style: TextStyle(color: blanco.withValues(alpha: 0.8), fontSize: 12),
            ),
            Text(
              fecha,
              style: const TextStyle(
                color: blanco,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
