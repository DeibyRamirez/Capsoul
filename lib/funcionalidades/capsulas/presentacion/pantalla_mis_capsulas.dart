import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../nucleo/componentes/encabezado_seccion_capsoul.dart';
import '../../../nucleo/componentes/frasco_luminoso.dart';
import '../../../nucleo/componentes/pantalla_capsoul.dart';
import '../../../nucleo/componentes/pildoras_seleccion_capsoul.dart';
import '../../../nucleo/enrutador/rutas_app.dart';
import '../../../nucleo/errores/fallo_app.dart';
import '../../../nucleo/tema/colores_app.dart';
import '../../autenticacion/aplicacion/proveedores_autenticacion.dart';
import '../aplicacion/proveedores_capsulas.dart';
import '../dominio/capsula.dart';
import '../dominio/capsula_recibida.dart';
import 'componentes/tarjeta_capsula_lista.dart';
import 'vista_capsulas_tab.dart';

/// Listado unificado: cápsulas propias y recibidas.
class PantallaMisCapsulas extends ConsumerStatefulWidget {
  const PantallaMisCapsulas({
    super.key,
    this.vistaInicial = VistaCapsulasTab.misCapsulas,
  });

  final VistaCapsulasTab vistaInicial;

  @override
  ConsumerState<PantallaMisCapsulas> createState() => _PantallaMisCapsulasState();
}

class _PantallaMisCapsulasState extends ConsumerState<PantallaMisCapsulas> {
  late VistaCapsulasTab _tab;

  @override
  void initState() {
    super.initState();
    _tab = widget.vistaInicial;
  }

  Future<void> _refrescar() async {
    if (_tab == VistaCapsulasTab.misCapsulas) {
      ref.invalidate(proveedorMisCapsulas);
      await ref.read(proveedorMisCapsulas.future);
    } else {
      ref.invalidate(proveedorCapsulasRecibidas);
      await ref.read(proveedorCapsulasRecibidas.future);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ahora = ref.watch(proveedorReloj)();
    final uid = ref.watch(
      proveedorEstadoAutenticacion.select((e) => e.value?.uid),
    );
    final misCapsulas = ref.watch(proveedorMisCapsulas);
    final recibidas = ref.watch(proveedorCapsulasRecibidas);

    final encabezado = _tab == VistaCapsulasTab.misCapsulas
        ? EncabezadoSeccionCapsoul(
            titulo: 'Mis cápsulas',
            subtitulo: 'Hoy las guardas, mañana alguien las abrirá.',
            icono: Icons.inventory_2_outlined,
            iconoTitulo: FrascoLuminoso(tamano: 32, brillo: 0.7),
          )
        : const EncabezadoSeccionCapsoul(
            titulo: 'Para mí',
            subtitulo: 'Cápsulas que otros prepararon para ti.',
            icono: Icons.inbox_outlined,
          );

    return PantallaCapsoul(
      cuerpo: RefreshIndicator(
        onRefresh: _refrescar,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: encabezado),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: PildorasSeleccionCapsoul<VistaCapsulasTab>(
                  opciones: VistaCapsulasTab.values,
                  seleccionado: _tab,
                  alCambiar: (t) => setState(() => _tab = t),
                  etiqueta: (t) => switch (t) {
                    VistaCapsulasTab.misCapsulas => 'Mis cápsulas',
                    VistaCapsulasTab.paraMi => 'Para mí',
                  },
                ),
              ),
            ),
            if (_tab == VistaCapsulasTab.misCapsulas)
              ..._sliversMisCapsulas(misCapsulas, ahora, uid)
            else
              ..._sliversRecibidas(recibidas, ahora),
            const SliverPadding(padding: EdgeInsets.only(bottom: 96)),
          ],
        ),
      ),
    );
  }

  List<Widget> _sliversMisCapsulas(
    AsyncValue<List<Capsula>> capsulas,
    DateTime ahora,
    String? uid,
  ) {
    return capsulas.when(
      loading: () => const [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(child: CircularProgressIndicator()),
        ),
      ],
      error: (error, _) => [
        SliverFillRemaining(
          hasScrollBody: false,
          child: _Aviso(
            mensaje: mensajeParaUsuario(error),
            etiquetaAccion: 'Reintentar',
            alTocar: () => ref.invalidate(proveedorMisCapsulas),
          ),
        ),
      ],
      data: (lista) {
        if (lista.isEmpty) {
          return [
            SliverFillRemaining(
              hasScrollBody: false,
              child: _Aviso(
                mensaje: 'Aún no tienes cápsulas. Guarda hoy algo para '
                    'abrirlo en el futuro.',
                etiquetaAccion: 'Crear mi primera cápsula',
                alTocar: () => context.push(RutasApp.crearCapsula),
              ),
            ),
          ];
        }
        return [
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList.separated(
              itemCount: lista.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, i) => TarjetaCapsulaLista.propia(
                key: ValueKey(lista[i].id),
                capsula: lista[i],
                ahora: ahora,
                uidActual: uid,
              ),
            ),
          ),
        ];
      },
    );
  }

  List<Widget> _sliversRecibidas(
    AsyncValue<List<CapsulaRecibida>> recibidas,
    DateTime ahora,
  ) {
    return recibidas.when(
      loading: () => const [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(child: CircularProgressIndicator()),
        ),
      ],
      error: (error, _) => [
        SliverFillRemaining(
          hasScrollBody: false,
          child: _Aviso(
            mensaje: mensajeParaUsuario(error),
            etiquetaAccion: 'Reintentar',
            alTocar: () => ref.invalidate(proveedorCapsulasRecibidas),
          ),
        ),
      ],
      data: (lista) {
        if (lista.isEmpty) {
          return [
            const SliverFillRemaining(
              hasScrollBody: false,
              child: _Aviso(
                mensaje: 'Aún no tienes cápsulas de otras personas. '
                    'Cuando alguien te envíe una, aparecerá aquí.',
                etiquetaAccion: '',
                alTocar: null,
              ),
            ),
          ];
        }
        return [
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList.separated(
              itemCount: lista.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, i) => TarjetaCapsulaLista.recibida(
                key: ValueKey(lista[i].id),
                recibida: lista[i],
                ahora: ahora,
              ),
            ),
          ),
        ];
      },
    );
  }
}

class _Aviso extends StatelessWidget {
  const _Aviso({
    required this.mensaje,
    required this.etiquetaAccion,
    required this.alTocar,
  });

  final String mensaje;
  final String etiquetaAccion;
  final VoidCallback? alTocar;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const FrascoLuminoso(tamano: 120, brillo: 0.6),
            const SizedBox(height: 16),
            Text(
              mensaje,
              textAlign: TextAlign.center,
              style: const TextStyle(color: ColoresApp.atenuado),
            ),
            if (etiquetaAccion.isNotEmpty && alTocar != null) ...[
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: alTocar,
                child: Text(etiquetaAccion),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
