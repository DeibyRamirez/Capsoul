import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../nucleo/componentes/fondo_capsoul.dart';
import '../../../nucleo/componentes/pantalla_capsoul.dart';
import '../../../nucleo/errores/fallo_app.dart';
import '../../../nucleo/tema/colores_app.dart';
import '../../../nucleo/tema/tema_app.dart';
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
    final estilos = Theme.of(context).textTheme;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      reto.completado
                          ? Icons.check_circle_outline
                          : Icons.auto_awesome_outlined,
                      color: ColoresApp.primario,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      reto.completado
                          ? 'Entrada completada'
                          : 'Entrada del Diario',
                      style: estilos.labelLarge?.copyWith(
                        color: ColoresApp.primario,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  reto.titulo,
                  style: estilos.headlineSmall?.copyWith(
                    fontFamily: TemaApp.fuenteTitulos,
                    fontWeight: FontWeight.w600,
                    color: ColoresApp.textoPrincipal,
                  ),
                ),
                if (reto.descripcion != null &&
                    reto.descripcion!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    reto.descripcion!,
                    style: estilos.bodyMedium?.copyWith(
                      color: ColoresApp.textoSecundario,
                    ),
                  ),
                ],
                if (reto.pasos.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Text(
                    'Pasos',
                    style: estilos.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  for (var i = 0; i < reto.pasos.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: ColoresApp.primario.withValues(
                                alpha: 0.10,
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '${i + 1}',
                              style: estilos.labelSmall?.copyWith(
                                color: ColoresApp.primario,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(top: 3),
                              child: Text(
                                reto.pasos[i],
                                style: estilos.bodyMedium?.copyWith(
                                  color: ColoresApp.textoSecundario,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: ColoresApp.fondoInicio,
                    borderRadius: BorderRadius.circular(TemaApp.radioMediano),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.verified_outlined,
                        size: 18,
                        color: ColoresApp.primario,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Esta entrada se marca automáticamente cuando '
                          'completas la acción en la app.',
                          style: estilos.bodySmall?.copyWith(
                            color: ColoresApp.atenuado,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
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
      const SnackBar(content: Text('No hay más entradas activas por ahora.')),
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
                titulo: 'Diario',
                subtitulo:
                    'Pequeños pasos que hoy construyen grandes recuerdos.',
                icono: Icons.auto_awesome_outlined,
                heroTag: HeroesInicio.retos,
              ),
              const SizedBox(height: 16),
              FiltrosRetos(seleccionado: tab, alCambiar: alCambiarTab),
              const SizedBox(height: 16),
              _ResumenProgreso(
                total: lista.length,
                completados: clasificacion.totalCompletados,
              ),
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
              mensaje: 'Próximamente podrás marcar entradas favoritas.',
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
          mensaje: 'No tienes entradas activas. ¡Buen trabajo!',
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
              titulo: 'Entradas semanales',
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
            _EncabezadoSeccion(titulo: 'Entradas especiales'),
            const SizedBox(height: 12),
            TarjetaRetoEspecial(
              reto: c.especial!,
              alTocar: () => alTocarReto(c.especial!),
            ),
            const SizedBox(height: 24),
          ],
          if (c.restoActivos.isNotEmpty)
            for (final (indice, grupo) in agruparRestoActivos(
              c.restoActivos,
            ).indexed) ...[
              KeyedSubtree(
                key: indice == 0 ? claveRestoActivos : null,
                child: _EncabezadoSeccion(titulo: grupo.titulo),
              ),
              const SizedBox(height: 12),
              ...grupo.retos.map(
                (r) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: TarjetaRetoSemanal(
                    reto: r,
                    indice: indice,
                    alTocar: () => alTocarReto(r),
                  ),
                ),
              ),
              const SizedBox(height: 14),
            ],
        ]),
      ),
    );
  }

  Widget _sliversCompletados(ClasificacionRetosUi c) {
    if (c.completados.isEmpty) {
      return const SliverFillRemaining(
        hasScrollBody: false,
        child: EstadoVacioRetos(
          mensaje: 'Aún no has completado ninguna entrada.',
        ),
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

class _ResumenProgreso extends StatelessWidget {
  const _ResumenProgreso({required this.total, required this.completados});

  final int total;
  final int completados;

  @override
  Widget build(BuildContext context) {
    final estilos = Theme.of(context).textTheme;
    final pendientes = (total - completados).clamp(0, total).toInt();
    final progreso = total == 0 ? 0.0 : (completados / total).clamp(0.0, 1.0);
    final mensaje = total == 0
        ? 'Aún no hay entradas disponibles.'
        : pendientes == 0
        ? 'Completaste todas las entradas.'
        : 'Te ${pendientes == 1 ? 'falta' : 'faltan'} $pendientes '
              '${pendientes == 1 ? 'entrada' : 'entradas'}.';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ColoresApp.tarjeta,
        borderRadius: BorderRadius.circular(TemaApp.radioGrande),
        border: Border.all(color: ColoresApp.bordeTarjeta),
        boxShadow: TemaApp.sombraTarjeta,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: ColoresApp.primario.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.auto_awesome_outlined,
                  size: 18,
                  color: ColoresApp.primario,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tu progreso',
                      style: estilos.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: ColoresApp.textoPrincipal,
                      ),
                    ),
                    Text(
                      mensaje,
                      style: estilos.bodySmall?.copyWith(
                        color: ColoresApp.atenuado,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$completados / $total',
                style: estilos.titleMedium?.copyWith(
                  color: ColoresApp.primario,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(TemaApp.radioPequeno),
            child: LinearProgressIndicator(
              value: progreso,
              minHeight: 8,
              backgroundColor: ColoresApp.fondoInicio,
              color: ColoresApp.primario,
            ),
          ),
        ],
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
