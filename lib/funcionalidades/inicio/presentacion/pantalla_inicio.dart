import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../nucleo/componentes/avisos_emergentes.dart';
import '../../../nucleo/enrutador/rutas_app.dart';
import '../../../nucleo/tema/colores_app.dart';
import '../aplicacion/proveedores_inicio.dart';
import '../dominio/resumen_inicio.dart';
import 'componentes/banner_frase_inicio.dart';
import 'componentes/encabezado_inicio.dart';
import 'componentes/escena_frasco_inicio.dart';
import 'componentes/tarjeta_seccion_inicio.dart';

/// Pestaña "Inicio": la cápsula de vidrio, "Guardar algo hoy", las cuatro
/// secciones con sus conteos y la frase de Capsoul.
class PantallaInicio extends ConsumerWidget {
  const PantallaInicio({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resumen =
        ref.watch(proveedorResumenInicio).value ?? ResumenInicio.vacio;
    final estilos = Theme.of(context).textTheme;

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              ColoresApp.acento.withValues(alpha: 0.18),
              ColoresApp.superficie,
            ],
          ),
        ),
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: () => ref.refresh(proveedorResumenInicio.future),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                EncabezadoInicio(
                  alTocarCampana: () => mostrarAvisoInformativo(
                    context,
                    'Los avisos llegarán pronto.',
                  ),
                ),
                const EscenaFrascoInicio(),
                Center(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(220, 52),
                      shape: const StadiumBorder(),
                    ),
                    onPressed: () => context.push(RutasApp.crear),
                    icon: const Icon(Icons.add),
                    label: const Text('Guardar algo hoy'),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '¿Qué quieres dejar para el futuro?',
                  textAlign: TextAlign.center,
                  style: estilos.bodyMedium?.copyWith(
                    color: ColoresApp.atenuado,
                  ),
                ),
                const SizedBox(height: 20),
                _RejillaSecciones(resumen: resumen),
                const SizedBox(height: 16),
                const BannerFraseInicio(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RejillaSecciones extends StatelessWidget {
  const _RejillaSecciones({required this.resumen});

  final ResumenInicio resumen;

  @override
  Widget build(BuildContext context) {
    final tarjetas = [
      TarjetaSeccionInicio(
        icono: Icons.photo_camera_outlined,
        titulo: 'Recuerdos',
        descripcion: 'Tu banco de recuerdos.',
        conteo: resumen.recuerdos,
        etiquetaConteo: etiquetaConteo(
          resumen.recuerdos,
          'recuerdo guardado',
          'recuerdos guardados',
        ),
        ilustracion: const IlustracionSeccion(icono: Icons.photo_outlined),
        alTocar: () => context.go(RutasApp.momentos),
      ),
      TarjetaSeccionInicio(
        icono: Icons.flag_outlined,
        titulo: 'Retos',
        descripcion: 'Pequeños pasos, grandes cambios.',
        conteo: resumen.retosActivos,
        etiquetaConteo: etiquetaConteo(
          resumen.retosActivos,
          'reto activo',
          'retos activos',
        ),
        ilustracion: const IlustracionSeccion(icono: Icons.terrain_outlined),
        alTocar: () =>
            mostrarAvisoInformativo(context, 'Los retos llegarán pronto.'),
      ),
      TarjetaSeccionInicio(
        icono: Icons.lock_outline,
        titulo: 'Cápsulas',
        descripcion: 'Guarda hoy, abre en el futuro.',
        conteo: resumen.capsulas,
        etiquetaConteo: etiquetaConteo(
          resumen.capsulas,
          'cápsula creada',
          'cápsulas creadas',
        ),
        ilustracion: const IlustracionSeccion(icono: Icons.hourglass_bottom),
        alTocar: () => context.push(RutasApp.capsulas),
      ),
      TarjetaSeccionInicio(
        icono: Icons.card_giftcard_outlined,
        titulo: 'Pequeñas herencias',
        descripcion: 'Deja algo de ti para quien más amas.',
        conteo: resumen.herencias,
        etiquetaConteo: etiquetaConteo(
          resumen.herencias,
          'herencia creada',
          'herencias creadas',
        ),
        ilustracion: const IlustracionSeccion(icono: Icons.redeem_outlined),
        alTocar: () => context.go(RutasApp.legado),
      ),
    ];
    // Rejilla 2×2 de alto natural: con letra grande las tarjetas crecen en
    // vez de desbordarse.
    return Column(
      children: [
        _FilaTarjetas(izquierda: tarjetas[0], derecha: tarjetas[1]),
        const SizedBox(height: 12),
        _FilaTarjetas(izquierda: tarjetas[2], derecha: tarjetas[3]),
      ],
    );
  }
}

/// "1 cápsula creada" / "5 cápsulas creadas".
String etiquetaConteo(int conteo, String singular, String plural) =>
    conteo == 1 ? singular : plural;

class _FilaTarjetas extends StatelessWidget {
  const _FilaTarjetas({required this.izquierda, required this.derecha});

  final Widget izquierda;
  final Widget derecha;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: izquierda),
          const SizedBox(width: 12),
          Expanded(child: derecha),
        ],
      ),
    );
  }
}
