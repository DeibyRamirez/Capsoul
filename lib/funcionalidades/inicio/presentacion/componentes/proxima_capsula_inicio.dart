import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../nucleo/enrutador/rutas_app.dart';
import '../../../../nucleo/tema/colores_app.dart';
import '../../../../nucleo/tema/espaciado_app.dart';
import '../../../../nucleo/tema/tema_app.dart';
import '../../../../nucleo/tema/tipografia_app.dart';
import '../../../capsulas/aplicacion/proveedores_capsulas.dart';
import '../../../capsulas/dominio/capsula.dart';
import '../../../capsulas/dominio/estado_capsula.dart';
import '../../../capsulas/presentacion/componentes/cuenta_regresiva.dart';

/// "Próxima cápsula" con su cuenta regresiva en un widget aparte, para que
/// el minuto del reloj no reconstruya Inicio.
class ProximaCapsulaInicio extends ConsumerWidget {
  const ProximaCapsulaInicio({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final capsulas = ref.watch(proveedorMisCapsulas);
    final reloj = ref.watch(proveedorReloj);
    return capsulas.when(
      loading: () => const _Marco(
        child: Text(
          'Buscando tu próxima cápsula…',
          style: TipografiaApp.cuerpoPequeno,
        ),
      ),
      error: (_, _) => const SizedBox.shrink(),
      data: (lista) {
        final ahora = reloj();
        final futuras = [
          for (final capsula in lista)
            if (_esProxima(capsula, ahora)) capsula,
        ]..sort(
            (a, b) => a.fechaApertura!.compareTo(b.fechaApertura!),
          );
        if (futuras.isEmpty) {
          return const _Marco(
            child: Text(
              'Cuando selles una cápsula, la cuenta regresiva vivirá aquí.',
              style: TipografiaApp.cuerpoPequeno,
            ),
          );
        }
        final proxima = futuras.first;
        final fecha = proxima.fechaApertura!;
        return _Marco(
          alTocar: () => context.push(RutasApp.detalleCapsulaDe(proxima.id)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Próxima cápsula', style: TipografiaApp.etiqueta),
              const SizedBox(height: EspaciadoApp.xxs),
              Text(proxima.titulo, style: TipografiaApp.titular),
              const SizedBox(height: EspaciadoApp.xs),
              CuentaRegresiva(
                fechaApertura: fecha,
                reloj: reloj,
                estilo: TipografiaApp.displayCompacto.copyWith(
                  color: ColoresApp.primario,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  static bool _esProxima(Capsula capsula, DateTime ahora) {
    final fecha = capsula.fechaApertura;
    if (fecha == null || !fecha.isAfter(ahora)) return false;
    return capsula.estado == EstadoCapsula.programada ||
        capsula.estado == EstadoCapsula.borrador;
  }
}

class _Marco extends StatelessWidget {
  const _Marco({required this.child, this.alTocar});

  final Widget child;
  final VoidCallback? alTocar;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ColoresApp.tarjeta,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(TemaApp.radioGrande),
        side: const BorderSide(color: ColoresApp.bordeTarjeta),
      ),
      clipBehavior: Clip.hardEdge,
      child: InkWell(
        onTap: alTocar,
        child: Padding(
          padding: const EdgeInsets.all(EspaciadoApp.md),
          child: child,
        ),
      ),
    );
  }
}
