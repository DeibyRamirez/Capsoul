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
import '../../inicio/presentacion/heroes_inicio.dart';
import '../aplicacion/proveedores_capsulas.dart';
import '../dominio/capsula.dart';
import '../dominio/capsula_recibida.dart';
import '../dominio/clasificador_capsulas.dart';
import 'componentes/tarjeta_capsula_lista.dart';
import 'vista_capsulas_tab.dart';

/// Listado de cápsulas en tres categorías, sin repetir la misma en dos pestañas.
class PantallaMisCapsulas extends ConsumerStatefulWidget {
  const PantallaMisCapsulas({
    super.key,
    this.vistaInicial = VistaCapsulasTab.misCapsulas,
  });

  final VistaCapsulasTab vistaInicial;

  @override
  ConsumerState<PantallaMisCapsulas> createState() =>
      _PantallaMisCapsulasState();
}

class _PantallaMisCapsulasState extends ConsumerState<PantallaMisCapsulas> {
  late VistaCapsulasTab _tab;

  @override
  void initState() {
    super.initState();
    _tab = widget.vistaInicial;
  }

  Future<void> _refrescar() async {
    if (_tab == VistaCapsulasTab.paraMi) {
      ref.invalidate(proveedorCapsulasRecibidas);
      await ref.read(proveedorCapsulasRecibidas.future);
      return;
    }
    ref.invalidate(proveedorMisCapsulas);
    await ref.read(proveedorMisCapsulas.future);
  }

  @override
  Widget build(BuildContext context) {
    final ahora = ref.watch(proveedorReloj)();
    final uid = ref.watch(
      proveedorEstadoAutenticacion.select((e) => e.value?.uid),
    );
    final misCapsulas = ref.watch(proveedorMisCapsulas);
    final recibidas = ref.watch(proveedorCapsulasRecibidas);

    return PantallaCapsoul(
      cuerpo: RefreshIndicator(
        onRefresh: _refrescar,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _encabezado(_tab)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: PildorasSeleccionCapsoul<VistaCapsulasTab>(
                  opciones: VistaCapsulasTab.values,
                  seleccionado: _tab,
                  alCambiar: (t) => setState(() => _tab = t),
                  etiqueta: _etiqueta,
                ),
              ),
            ),
            ...switch (_tab) {
              VistaCapsulasTab.misCapsulas => _sliversPropias(
                misCapsulas,
                ahora,
                filtrar: capsulasEnviadas,
                vacio:
                    'Aún no tienes cápsulas. Guarda hoy algo para '
                    'abrirlo en el futuro.',
                accion: 'Crear mi primera cápsula',
              ),
              VistaCapsulasTab.paraMiMismo => _sliversPropias(
                misCapsulas,
                ahora,
                filtrar: capsulasParaMiMismo,
                vacio:
                    'Aún no tienes cápsulas solo para ti. '
                    'Activa «También para mí» al crear una.',
                accion: 'Crear una cápsula para mí',
              ),
              VistaCapsulasTab.paraMi => _sliversRecibidas(
                recibidas,
                ahora,
                uid,
              ),
            },
            const SliverPadding(padding: EdgeInsets.only(bottom: 96)),
          ],
        ),
      ),
    );
  }

  List<Widget> _sliversPropias(
    AsyncValue<List<Capsula>> capsulas,
    DateTime ahora, {
    required List<Capsula> Function(List<Capsula>) filtrar,
    required String vacio,
    required String accion,
  }) {
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
        final visibles = filtrar(lista);
        if (visibles.isEmpty) {
          return [
            SliverFillRemaining(
              hasScrollBody: false,
              child: _Aviso(
                mensaje: vacio,
                etiquetaAccion: accion,
                alTocar: () => context.push(RutasApp.crearCapsula),
              ),
            ),
          ];
        }
        return [
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList.separated(
              itemCount: visibles.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, i) => TarjetaCapsulaLista.propia(
                key: ValueKey(visibles[i].id),
                capsula: visibles[i],
                ahora: ahora,
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
    String? uid,
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
        final visibles = recibidasDeOtrasPersonas(lista, uid);
        if (visibles.isEmpty) {
          return [
            const SliverFillRemaining(
              hasScrollBody: false,
              child: _Aviso(
                mensaje:
                    'Aún no tienes cápsulas de otras personas. '
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
              itemCount: visibles.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, i) => TarjetaCapsulaLista.recibida(
                key: ValueKey(visibles[i].id),
                recibida: visibles[i],
                ahora: ahora,
              ),
            ),
          ),
        ];
      },
    );
  }
}

Widget _encabezado(VistaCapsulasTab tab) => switch (tab) {
  VistaCapsulasTab.misCapsulas => EncabezadoSeccionCapsoul(
    titulo: 'Mis cápsulas',
    subtitulo: 'Hoy las guardas, mañana alguien las abrirá.',
    icono: Icons.inventory_2_outlined,
    iconoTitulo: FrascoLuminoso(tamano: 32, brillo: 0.7),
    heroTag: HeroesInicio.capsulas,
  ),
  VistaCapsulasTab.paraMiMismo => const EncabezadoSeccionCapsoul(
    titulo: 'Para mí mismo',
    subtitulo: 'Cápsulas que guardaste solo para ti.',
    icono: Icons.person_outline,
  ),
  VistaCapsulasTab.paraMi => const EncabezadoSeccionCapsoul(
    titulo: 'Para mí',
    subtitulo: 'Cápsulas que otros prepararon para ti.',
    icono: Icons.inbox_outlined,
  ),
};

String _etiqueta(VistaCapsulasTab tab) => switch (tab) {
  VistaCapsulasTab.misCapsulas => 'Mis cápsulas',
  VistaCapsulasTab.paraMiMismo => 'Para mí mismo',
  VistaCapsulasTab.paraMi => 'Para mí',
};

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
              OutlinedButton(onPressed: alTocar, child: Text(etiquetaAccion)),
            ],
          ],
        ),
      ),
    );
  }
}
