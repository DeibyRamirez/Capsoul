import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../nucleo/componentes/avisos_emergentes.dart';
import '../../../nucleo/componentes/fondo_capsoul.dart';
import '../../../nucleo/componentes/pantalla_capsoul.dart';
import '../../../nucleo/enrutador/rutas_app.dart';
import '../../../nucleo/tema/colores_app.dart';
import '../../autenticacion/aplicacion/proveedores_autenticacion.dart';
import '../../capsulas/aplicacion/proveedores_capsulas.dart';
import '../../capsulas/dominio/avisos_capsulas.dart';
import '../../crear/presentacion/componentes/hoja_opciones_crear.dart';
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
    final resumenAsincrono = ref.watch(proveedorResumenInicio);
    ref.listen(proveedorResumenInicio, (anterior, siguiente) {
      if (!siguiente.hasError || !context.mounted) return;
      if (anterior?.hasError == true) return;
      mostrarAvisoError(
        context,
        siguiente.error ?? 'No se pudo cargar el resumen.',
      );
    });
    final resumen = resumenAsincrono.when(
      data: (datos) => datos,
      loading: () => resumenAsincrono.value ?? ResumenInicio.vacio,
      error: (_, _) => resumenAsincrono.value ?? ResumenInicio.vacio,
    );
    final estilos = Theme.of(context).textTheme;

    final uid = ref.watch(proveedorEstadoAutenticacion).value?.uid;
    final recibidas = ref.watch(proveedorCapsulasRecibidas).value ?? const [];
    final avisos = avisosCapsulasCompartidas(recibidas, uid);
    final textoBadge = textoBadgeAvisos(conteoAvisosSinLeer(avisos));

    return RefrescoAvisosAlVolver(
      child: PantallaCapsoul(
        tipoFondo: FondoCapsoulTipo.suave,
        cuerpo: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(proveedorResumenInicio);
            ref.invalidate(proveedorCapsulasRecibidas);
            await ref.read(proveedorResumenInicio.future);
            await ref.read(proveedorCapsulasRecibidas.future);
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              EncabezadoInicio(
                textoBadge: textoBadge,
                alTocarCampana: () => context.push(RutasApp.avisos),
              ),
              const SizedBox(height: 12),
              const EscenaFrascoInicio(),
              const SizedBox(height: 20),
              Center(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(220, 48),
                    shape: const StadiumBorder(),
                  ),
                  onPressed: () => HojaOpcionesCrear.mostrar(context),
                  icon: const Icon(Icons.add),
                  label: const Text('Guardar algo hoy'),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '¿Qué quieres dejar para el futuro?',
                textAlign: TextAlign.center,
                style: estilos.bodySmall?.copyWith(color: ColoresApp.atenuado),
              ),
              const SizedBox(height: 20),
              _RejillaSecciones(resumen: resumen),
              const SizedBox(height: 16),
              const BannerFraseInicio(),
            ],
          ),
        ),
      ),
    );
  }
}

/// Al volver del segundo plano se vuelve a contar el badge.
class RefrescoAvisosAlVolver extends ConsumerStatefulWidget {
  const RefrescoAvisosAlVolver({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<RefrescoAvisosAlVolver> createState() =>
      _EstadoRefrescoAvisosAlVolver();
}

class _EstadoRefrescoAvisosAlVolver
    extends ConsumerState<RefrescoAvisosAlVolver>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.invalidate(proveedorCapsulasRecibidas);
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
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
        alTocar: () => context.push(RutasApp.recuerdos),
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
        alTocar: () => context.push(RutasApp.retos),
      ),
      TarjetaSeccionInicio(
        icono: Icons.lock_outline,
        titulo: 'Cápsulas',
        descripcion: 'Guarda hoy, abre en el futuro.',
        conteo: resumen.capsulas,
        etiquetaConteo: etiquetaConteo(
          resumen.capsulas,
          'cápsula        creada',
          'cápsulas       creadas',
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
          'herencia        creada',
          'herencias       creadas',
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
        const SizedBox(height: 16),
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
          const SizedBox(width: 16),
          Expanded(child: derecha),
        ],
      ),
    );
  }
}
