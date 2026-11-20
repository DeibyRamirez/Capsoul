import 'package:flutter/material.dart';

import '../../../../nucleo/componentes/tarjeta_capsoul.dart';
import '../../../../nucleo/formato/fechas.dart';
import '../../../../nucleo/tema/colores_app.dart';
import '../../../../nucleo/tema/tema_app.dart';
import '../../dominio/herencia_recibida.dart';

/// Tarjeta de una herencia recibida: lo que alguien puso en tus manos.
///
/// El medallón cambia de sellado a abierto y el título usa la tipografía de
/// marca para mantener la emoción de Capsoul.
class TarjetaHerenciaRecibida extends StatelessWidget {
  const TarjetaHerenciaRecibida({
    super.key,
    required this.herencia,
    this.alTocar,
  });

  final HerenciaRecibida herencia;
  final VoidCallback? alTocar;

  @override
  Widget build(BuildContext context) {
    final estilos = Theme.of(context).textTheme;
    final abierta = herencia.contenidoVisible;
    final fecha = herencia.fechaActivacion;

    return TarjetaCapsoul(
      alTocar: alTocar,
      child: Row(
        children: [
          _MedallonHerencia(abierta: abierta),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  herencia.titulo,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: estilos.titleMedium?.copyWith(
                    fontFamily: TemaApp.fuenteTitulos,
                    color: ColoresApp.primario,
                    fontWeight: FontWeight.w700,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${herencia.propietarioNombre} te lo confió',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: estilos.bodySmall?.copyWith(
                    color: ColoresApp.atenuado,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _EtiquetaEstado(abierta: abierta),
                    if (herencia.nCapsulas > 0)
                      _DatoHerencia(
                        icono: Icons.inventory_2_outlined,
                        texto:
                            '${herencia.nCapsulas} cápsula'
                            '${herencia.nCapsulas == 1 ? '' : 's'}',
                      ),
                  ],
                ),
                if (!abierta && fecha != null) ...[
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 1),
                        child: Icon(
                          Icons.event_outlined,
                          size: 14,
                          color: ColoresApp.atenuado,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'Se abre el ${formatearFechaCorta(fecha)}',
                          style: estilos.labelSmall?.copyWith(
                            color: ColoresApp.atenuado,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 6),
          const Icon(Icons.chevron_right, color: ColoresApp.atenuado, size: 20),
        ],
      ),
    );
  }
}

/// Medallón medianoche con candado dorado mientras la herencia siga sellada.
class _MedallonHerencia extends StatelessWidget {
  const _MedallonHerencia({required this.abierta});

  final bool abierta;

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
          colors: abierta
              ? [ColoresApp.fondoInicio, ColoresApp.tarjeta]
              : [ColoresApp.medianoche, ColoresApp.primario],
        ),
        border: Border.all(
          color: abierta
              ? ColoresApp.bordeTarjeta
              : ColoresApp.dorado.withValues(alpha: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: ColoresApp.primario.withValues(alpha: 0.16),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Icon(
        abierta ? Icons.lock_open_rounded : Icons.lock_outline_rounded,
        size: 25,
        color: abierta ? ColoresApp.primario : ColoresApp.doradoClaro,
      ),
    );
  }
}

class _EtiquetaEstado extends StatelessWidget {
  const _EtiquetaEstado({required this.abierta});

  final bool abierta;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: abierta
            ? ColoresApp.primario.withValues(alpha: 0.10)
            : ColoresApp.fondoInicio,
        borderRadius: BorderRadius.circular(TemaApp.radioPildora),
        border: Border.all(
          color: abierta ? Colors.transparent : ColoresApp.bordeTarjeta,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            abierta ? Icons.lock_open_rounded : Icons.lock_outline_rounded,
            size: 13,
            color: ColoresApp.primario,
          ),
          const SizedBox(width: 4),
          Text(
            abierta ? 'Abierta' : 'Sellada',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: ColoresApp.primario,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _DatoHerencia extends StatelessWidget {
  const _DatoHerencia({required this.icono, required this.texto});

  final IconData icono;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icono, size: 14, color: ColoresApp.atenuado),
        const SizedBox(width: 4),
        Text(
          texto,
          style: Theme.of(context).textTheme.labelSmall
              ?.copyWith(color: ColoresApp.atenuado),
        ),
      ],
    );
  }
}
