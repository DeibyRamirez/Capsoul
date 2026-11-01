import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../nucleo/componentes/fondo_capsoul.dart';
import '../../../nucleo/componentes/pantalla_capsoul.dart';
import '../../../nucleo/errores/fallo_app.dart';
import '../../../nucleo/tema/colores_app.dart';
import '../aplicacion/proveedores_retos.dart';
import '../dominio/reto.dart';
import 'clasificacion_retos_ui.dart';
import '../../../nucleo/componentes/encabezado_seccion_capsoul.dart';
import '../../inicio/presentacion/heroes_inicio.dart';
import 'componentes/estado_vacio_retos.dart';
import 'componentes/filtros_retos.dart';
import 'componentes/item_reto_completado.dart';
import 'componentes/tarjeta_reto_diario.dart';
import 'componentes/tarjeta_reto_especial.dart';
import 'componentes/tarjeta_reto_semanal.dart';

class PantallaRetos extends ConsumerStatefulWidget {
  const PantallaRetos({super.key});

  @override
  ConsumerState<PantallaRetos> createState() => _PantallaRetosState();
}

class _PantallaRetosState extends ConsumerState<PantallaRetos> {
  FiltroRetosTab _tab = FiltroRetosTab.activos;
  final _scrollController = ScrollController();
  final _claveRestoActivos = GlobalKey();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _refrescar() async {
    ref.invalidate(proveedorListaRetos);
    await ref.read(proveedorListaRetos.future);
  }

  void _mostrarDetalleReto(Reto reto) {
    final tema = Theme.of(context);
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                reto.titulo,
                style: tema.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: ColoresApp.textoPrincipal,
                ),
              ),
              if (reto.descripcion != null && reto.descripcion!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  reto.descripcion!,
                  style: tema.textTheme.bodyMedium?.copyWith(
                    color: ColoresApp.textoSecundario,
                  ),
                ),
              ],
              if (reto.pasos.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  'Pasos',
                  style: tema.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                ...reto.pasos.map(
                  (paso) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      '• $paso',
                      style: tema.textTheme.bodyMedium?.copyWith(
                        color: ColoresApp.textoSecundario,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  void _verTodosSemanales() {
    final contexto = _claveRestoActivos.currentContext;
    if (contexto != null) {
      Scrollable.ensureVisible(
        contexto,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('No hay más retos activos por ahora.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final retos = ref.watch(proveedorListaRetos);
    return PantallaCapsoul(
      tipoFondo: FondoCapsoulTipo.plano,
      cuerpo: retos.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(mensajeParaUsuario(error)),
          ),
        ),
        data: (lista) => RefreshIndicator(
          onRefresh: _refrescar,
          child: _ContenidoRetos(
            lista: lista,
            tab: _tab,
            scrollController: _scrollController,
            claveRestoActivos: _claveRestoActivos,
            alCambiarTab: (t) => setState(() => _tab = t),
            alTocarReto: _mostrarDetalleReto,
            alVerTodosSemanales: _verTodosSemanales,
          ),
        ),
      ),
    );
  }
}

class _ContenidoRetos extends StatelessWidget {
  const _ContenidoRetos({
    required this.lista,
    required this.tab,
    required this.scrollController,
    required this.claveRestoActivos,
    required this.alCambiarTab,
    required this.alTocarReto,
    required this.alVerTodosSemanales,
  });

  final List<Reto> lista;
  final FiltroRetosTab tab;
  final ScrollController scrollController;
  final GlobalKey claveRestoActivos;
  final ValueChanged<FiltroRetosTab> alCambiarTab;
  final void Function(Reto) alTocarReto;
  final VoidCallback alVerTodosSemanales;

  @override
  Widget build(BuildContext context) {
    final clasificacion = clasificarRetosParaUi(lista);

    return CustomScrollView(
      controller: scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              const EncabezadoSeccionCapsoul(
                titulo: 'Retos',
                subtitulo:
                    'Pequeños pasos que hoy construyen grandes recuerdos.',
                icono: Icons.auto_awesome_outlined,
                heroTag: HeroesInicio.retos,
              ),
              const SizedBox(height: 16),
              FiltrosRetos(seleccionado: tab, alCambiar: alCambiarTab),
              const SizedBox(height: 16),
            ]),
          ),
        ),
        switch (tab) {
          FiltroRetosTab.activos => _sliversActivos(clasificacion),
          FiltroRetosTab.completados => _sliversCompletados(clasificacion),
          FiltroRetosTab.favoritos => const SliverFillRemaining(
            hasScrollBody: false,
            child: EstadoVacioRetos(
              icono: Icons.favorite_border,
              mensaje: 'Próximamente podrás marcar retos favoritos.',
            ),
          ),
        },
        const SliverPadding(padding: EdgeInsets.only(bottom: 32)),
      ],
    );
  }

  Widget _sliversActivos(ClasificacionRetosUi c) {
    final activosVacios =
        c.diario == null &&
        c.semanales.isEmpty &&
        c.restoActivos.isEmpty &&
        c.especial == null;

    if (activosVacios) {
      return const SliverFillRemaining(
        hasScrollBody: false,
        child: EstadoVacioRetos(
          mensaje: 'No tienes retos activos. ¡Buen trabajo!',
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          if (c.diario != null) ...[
            TarjetaRetoDiario(
              reto: c.diario!,
              alTocar: () => alTocarReto(c.diario!),
            ),
            const SizedBox(height: 24),
          ],
          if (c.semanales.isNotEmpty) ...[
            _EncabezadoSeccion(
              titulo: 'Retos semanales',
              accion: 'Ver todos',
              alAccion: alVerTodosSemanales,
            ),
            const SizedBox(height: 12),
            ...c.semanales.asMap().entries.map(
              (e) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: TarjetaRetoSemanal(
                  reto: e.value,
                  indice: e.key,
                  alTocar: () => alTocarReto(e.value),
                ),
              ),
            ),
            const SizedBox(height: 14),
          ],
          if (c.especial != null) ...[
            _EncabezadoSeccion(titulo: 'Retos especiales'),
            const SizedBox(height: 12),
            TarjetaRetoEspecial(
              reto: c.especial!,
              diaActual: c.totalCompletados,
              alTocar: () => alTocarReto(c.especial!),
            ),
            const SizedBox(height: 24),
          ],
          if (c.restoActivos.isNotEmpty) ...[
            KeyedSubtree(
              key: claveRestoActivos,
              child: _EncabezadoSeccion(titulo: 'Más retos'),
            ),
            const SizedBox(height: 12),
            ...c.restoActivos.map(
              (r) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: TarjetaRetoSemanal(
                  reto: r,
                  indice: 0,
                  alTocar: () => alTocarReto(r),
                ),
              ),
            ),
          ],
        ]),
      ),
    );
  }

  Widget _sliversCompletados(ClasificacionRetosUi c) {
    if (c.completados.isEmpty) {
      return const SliverFillRemaining(
        hasScrollBody: false,
        child: EstadoVacioRetos(mensaje: 'Aún no has completado ningún reto.'),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          ...c.completados.map(
            (r) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: ItemRetoCompletado(reto: r, alTocar: () => alTocarReto(r)),
            ),
          ),
        ]),
      ),
    );
  }
}

class _EncabezadoSeccion extends StatelessWidget {
  const _EncabezadoSeccion({required this.titulo, this.accion, this.alAccion});

  final String titulo;
  final String? accion;
  final VoidCallback? alAccion;

  @override
  Widget build(BuildContext context) {
    final estilos = Theme.of(context).textTheme;
    return Row(
      children: [
        Expanded(
          child: Text(
            titulo,
            style: estilos.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: ColoresApp.textoPrincipal,
            ),
          ),
        ),
        if (accion != null && alAccion != null)
          TextButton(onPressed: alAccion, child: Text(accion!)),
      ],
    );
  }
}
