import 'package:flutter/material.dart';

import '../../../../nucleo/tema/colores_app.dart';
import '../../../../nucleo/tema/degradados_capsoul.dart';
import '../../../../nucleo/tema/tema_app.dart';
import '../../../../nucleo/componentes/cielo_nocturno.dart';
import '../heroes_capsula.dart';
import 'miniatura_imagen_capsula.dart';

/// Cabecera del detalle sobre fondo claro: boton atras y una tarjeta
/// medianoche con el cielo de luciernagas, imagen de la cápsula, título,
/// horizonte y candado con la fecha de apertura.
class CabeceraCapsula extends StatelessWidget {
  const CabeceraCapsula({
    super.key,
    required this.capsulaId,
    required this.titulo,
    required this.horizonte,
    required this.fechaApertura,
    required this.cuentaRegresiva,
    required this.sellada,
    this.imagenClave,
  });

  final String capsulaId;
  final String titulo;
  final String? horizonte;

  /// "13 ago 2046".
  final String? fechaApertura;
  final Widget? cuentaRegresiva;
  final bool sellada;
  final String? imagenClave;

  @override
  Widget build(BuildContext context) {
    final estilos = Theme.of(context).textTheme;
    const blanco = ColoresApp.sobrePrimario;
    final horizonte = this.horizonte;
    final fechaApertura = this.fechaApertura;
    final cuentaRegresiva = this.cuentaRegresiva;
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: DegradadosCapsoul.suave),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const BackButton(color: ColoresApp.textoPrincipal),
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(TemaApp.radioGrande),
                  child: CieloNocturno(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 16, 10, 16),
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
                                    fontFamily: TemaApp.fuenteTitulos,
                                    fontWeight: FontWeight.w600,
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
                          MiniaturaImagenCapsula(
                            imagenClave: imagenClave,
                            ancho: 96,
                            conCandado: sellada,
                            heroTag: HeroesCapsula.imagen(capsulaId),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
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
        Icon(
          sellada ? Icons.lock_outline : Icons.lock_open_outlined,
          color: blanco,
          size: 22,
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              sellada ? 'Abrir en' : 'Se abrió el',
              style: TextStyle(
                color: blanco.withValues(alpha: 0.8),
                fontSize: 12,
              ),
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
