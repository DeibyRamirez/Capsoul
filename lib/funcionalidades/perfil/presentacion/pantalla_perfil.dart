import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../nucleo/componentes/avisos_emergentes.dart';
import '../../../nucleo/componentes/pantalla_capsoul.dart';
import '../../../nucleo/enrutador/rutas_app.dart';
import '../../../nucleo/tema/colores_app.dart';
import '../../../nucleo/tema/tema_app.dart';
import '../../autenticacion/aplicacion/proveedores_autenticacion.dart';
import '../../autenticacion/presentacion/validadores_autenticacion.dart';
import '../../inicio/aplicacion/proveedores_inicio.dart';
import '../../inicio/dominio/resumen_inicio.dart';
import '../../recuerdos/aplicacion/proveedores_recuerdos.dart';
import '../../recuerdos/dominio/filtro_recuerdos.dart';
import '../aplicacion/controlador_perfil.dart';
import 'componentes/encabezado_perfil.dart';
import 'componentes/fila_destacados_perfil.dart';
import 'componentes/rejilla_elementos_perfil.dart';

/// Pestaña "Yo": perfil con cabecera estilo Instagram y rejilla de recuerdos.
class PantallaPerfil extends ConsumerWidget {
  const PantallaPerfil({super.key});

  Future<void> _editarNombre(
    BuildContext context,
    WidgetRef ref,
    String nombreActual,
  ) async {
    final nombreNuevo = await showDialog<String>(
      context: context,
      builder: (_) => _DialogoEditarNombre(nombreInicial: nombreActual),
    );
    if (nombreNuevo == null || nombreNuevo.trim() == nombreActual) return;
    final guardado = await ref
        .read(proveedorControladorPerfil.notifier)
        .actualizarNombreVisible(nombreNuevo);
    if (guardado && context.mounted) {
      mostrarAvisoInformativo(context, 'Nombre actualizado');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<AsyncValue<void>>(proveedorControladorPerfil, (_, siguiente) {
      if (siguiente is AsyncError) mostrarAvisoError(context, siguiente.error);
    });

    final usuarioSesion = ref.watch(proveedorEstadoAutenticacion).value;
    final perfilAsincrono = ref.watch(proveedorPerfilUsuarioActual);
    final perfil = perfilAsincrono.value;
    final ocupado = ref.watch(proveedorControladorPerfil).isLoading;
    final resumen =
        ref.watch(proveedorResumenInicio).value ?? ResumenInicio.vacio;
    final recuerdosAsincrono =
        ref.watch(proveedorRecuerdos(FiltroRecuerdos.todos));

    final nombre =
        perfil?.nombreVisible ?? usuarioSesion?.nombreVisible ?? 'Sin nombre';
    final nombreLimpio = nombre.trim();
    final inicial =
        nombreLimpio.isEmpty ? '?' : nombreLimpio[0].toUpperCase();

    return PantallaCapsoul(
      cuerpo: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(proveedorRecuerdos(FiltroRecuerdos.todos));
            ref.invalidate(proveedorResumenInicio);
            await Future.wait([
              ref.read(proveedorRecuerdos(FiltroRecuerdos.todos).future),
              ref.read(proveedorResumenInicio.future),
            ]);
          },
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _BarraSuperior(
                  alCrear: () => context.push(RutasApp.crear),
                ),
              ),
              if (perfilAsincrono.isLoading && perfil == null)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: LinearProgressIndicator(),
                  ),
                ),
              SliverToBoxAdapter(
                child: EncabezadoPerfil(
                  nombre: nombre,
                  inicial: inicial,
                  resumen: resumen,
                  publicaciones: resumen.recuerdos,
                  ocupado: ocupado,
                  alEditar: () => _editarNombre(context, ref, nombre),
                  alCerrarSesion: () => ref
                      .read(proveedorControladorPerfil.notifier)
                      .cerrarSesion(),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 12)),
              SliverToBoxAdapter(
                child: FilaDestacadosPerfil(
                  alTocar: (etiqueta) => mostrarAvisoInformativo(
                    context,
                    '$etiqueta: próximamente',
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 8)),
              recuerdosAsincrono.when(
                loading: () => const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(48),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),
                error: (_, _) => const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Text(
                      'No pudimos cargar tus recuerdos.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: ColoresApp.atenuado),
                    ),
                  ),
                ),
                data: (lista) => SliverToBoxAdapter(
                  child: RejillaElementosPerfil(recuerdos: lista),
                ),
              ),
            ],
          ),
        ),
    );
  }
}

class _BarraSuperior extends StatelessWidget {
  const _BarraSuperior({required this.alCrear});

  final VoidCallback alCrear;

  @override
  Widget build(BuildContext context) {
    final estilos = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 4),
      child: Row(
        children: [
          const Icon(Icons.lock_outline, size: 18, color: ColoresApp.primario),
          const SizedBox(width: 6),
          Text(
            'cápsoul',
            style: estilos.titleLarge?.copyWith(
              color: ColoresApp.primario,
              fontWeight: FontWeight.w800,
            ),
          ),
          const Spacer(),
          // IconButton(
          //   tooltip: 'Crear',
          //   onPressed: alCrear,
          //   icon: const Icon(Icons.add_box_outlined),
          // ),
          // IconButton(
          //   tooltip: 'Menú',
          //   onPressed: () {},
          //   icon: const Icon(Icons.menu),
          // ),
        ],
      ),
    );
  }
}

class _DialogoEditarNombre extends StatefulWidget {
  const _DialogoEditarNombre({required this.nombreInicial});

  final String nombreInicial;

  @override
  State<_DialogoEditarNombre> createState() => _EstadoDialogoEditarNombre();
}

class _EstadoDialogoEditarNombre extends State<_DialogoEditarNombre> {
  final _claveFormulario = GlobalKey<FormState>();
  late final TextEditingController _controlador =
      TextEditingController(text: widget.nombreInicial);

  @override
  void dispose() {
    _controlador.dispose();
    super.dispose();
  }

  void _guardar() {
    if (!(_claveFormulario.currentState?.validate() ?? false)) return;
    Navigator.of(context).pop(_controlador.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(TemaApp.radioGrande),
      ),
      title: const Text('Editar nombre'),
      content: Form(
        key: _claveFormulario,
        child: TextFormField(
          controller: _controlador,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(labelText: 'Nombre'),
          validator: ValidadoresAutenticacion.nombreVisible,
          onFieldSubmitted: (_) => _guardar(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _guardar,
          style: FilledButton.styleFrom(minimumSize: const Size(96, 48)),
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}
