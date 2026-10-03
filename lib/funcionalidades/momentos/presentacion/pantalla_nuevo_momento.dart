import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../nucleo/componentes/avisos_emergentes.dart';
import '../../../nucleo/componentes/boton_principal.dart';
import '../../../nucleo/enrutador/rutas_app.dart';
import '../../../nucleo/tema/colores_app.dart';
import '../../../nucleo/tema/tema_app.dart';
import '../../capsulas/aplicacion/proveedores_capsulas.dart';
import '../../capsulas/presentacion/componentes/tarjeta_recuerdo_elegido.dart';
import '../../recuerdos/aplicacion/proveedores_recuerdos.dart';
import '../../recuerdos/dominio/filtro_recuerdos.dart';
import '../../recuerdos/dominio/recuerdo.dart';
import '../../recuerdos/presentacion/componentes/barra_filtros_recuerdos.dart';
import '../../recuerdos/presentacion/componentes/miniatura_recuerdo_firmada.dart';
import '../../recuerdos/presentacion/pantalla_elegir_recuerdos.dart';
import '../aplicacion/controlador_nuevo_momento.dart';
import '../dominio/validador_momento.dart';

/// "Nuevo momento": nombre, descripción, recuerdos (todos los de un filtro
/// rápido o elegidos a mano) y portada.
class PantallaNuevoMomento extends ConsumerStatefulWidget {
  const PantallaNuevoMomento({super.key});

  @override
  ConsumerState<PantallaNuevoMomento> createState() =>
      _EstadoPantallaNuevoMomento();
}

class _EstadoPantallaNuevoMomento extends ConsumerState<PantallaNuevoMomento> {
  final _titulo = TextEditingController();
  final _descripcion = TextEditingController();
  FiltroRecuerdos _filtro = FiltroRecuerdos.todos;
  bool _agregandoFiltro = false;

  ControladorNuevoMomento get _controlador =>
      ref.read(proveedorControladorNuevoMomento.notifier);

  @override
  void dispose() {
    _titulo.dispose();
    _descripcion.dispose();
    super.dispose();
  }

  DateTime get _hoy => ref.read(proveedorReloj)();

  void _filtroRapido(FiltroRecuerdos Function(DateTime hoy) crear) {
    final nuevo = crear(_hoy).conTipos(_filtro.tipos);
    setState(() => _filtro = nuevo == _filtro ? _filtro.conFechas(null, null) : nuevo);
  }

  Future<void> _agregarTodosDelFiltro() async {
    setState(() => _agregandoFiltro = true);
    try {
      final lista = await ref.read(proveedorRecuerdos(_filtro).future);
      if (!mounted) return;
      final agregados = _controlador.agregar(lista);
      mostrarAvisoInformativo(
        context,
        agregados == 0
            ? 'No hay recuerdos nuevos en este filtro.'
            : agregados == 1
                ? 'Se agregó 1 recuerdo.'
                : 'Se agregaron $agregados recuerdos.',
      );
    } catch (error) {
      if (mounted) mostrarAvisoError(context, error);
    } finally {
      if (mounted) setState(() => _agregandoFiltro = false);
    }
  }

  Future<void> _elegirAMano() async {
    final estado = ref.read(proveedorControladorNuevoMomento);
    final elegidos = await context.push<List<Recuerdo>>(
      RutasApp.elegirRecuerdos,
      extra: ParametrosElegirRecuerdos(
        titulo: 'Recuerdos para el momento',
        yaElegidos: estado.idsElegidos,
        maximo: estado.disponibles,
        filtroInicial: _filtro,
      ),
    );
    if (elegidos != null && mounted) _controlador.agregar(elegidos);
  }

  Future<void> _guardar() async {
    FocusScope.of(context).unfocus();
    final id = await _controlador.guardar(
      titulo: _titulo.text,
      descripcion: _descripcion.text,
    );
    if (id == null || !mounted) return;
    mostrarAvisoInformativo(context, 'Tu momento quedó guardado.');
    context.pushReplacement(RutasApp.detalleMomentoDe(id));
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(proveedorControladorNuevoMomento, (anterior, siguiente) {
      final error = siguiente.error;
      if (error != null && error != anterior?.error) {
        mostrarAvisoError(context, error);
        _controlador.limpiarError();
      }
    });
    final estado = ref.watch(proveedorControladorNuevoMomento);
    final hoy = ref.watch(proveedorReloj)();
    final ocupado = estado.guardando;
    final semana = FiltroRecuerdos.ultimosDias(7, hoy).conTipos(_filtro.tipos);
    final mes = FiltroRecuerdos.ultimosDias(30, hoy).conTipos(_filtro.tipos);
    final anio = FiltroRecuerdos.esteAnio(hoy).conTipos(_filtro.tipos);

    return Scaffold(
      appBar: AppBar(title: const Text('Nuevo momento')),
      body: SafeArea(
        child: ListView(
          key: const Key('formulario-momento'),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            TextField(
              key: const Key('campo-nombre-momento'),
              controller: _titulo,
              enabled: !ocupado,
              maxLength: ValidadorMomento.caracteresMaxTitulo,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Nombre',
                hintText: 'Ej.: Vacaciones en Cartagena',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              key: const Key('campo-descripcion-momento'),
              controller: _descripcion,
              enabled: !ocupado,
              minLines: 2,
              maxLines: 5,
              maxLength: ValidadorMomento.caracteresMaxDescripcion,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Descripción (opcional)',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 12),
            const _Titulo('Agregar recuerdos'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('Últimos 7 días'),
                  selected: _filtro == semana,
                  onSelected: (_) =>
                      _filtroRapido((h) => FiltroRecuerdos.ultimosDias(7, h)),
                ),
                ChoiceChip(
                  label: const Text('Últimos 30 días'),
                  selected: _filtro == mes,
                  onSelected: (_) =>
                      _filtroRapido((h) => FiltroRecuerdos.ultimosDias(30, h)),
                ),
                ChoiceChip(
                  label: const Text('Este año'),
                  selected: _filtro == anio,
                  onSelected: (_) => _filtroRapido(FiltroRecuerdos.esteAnio),
                ),
              ],
            ),
            const SizedBox(height: 8),
            BarraFiltrosRecuerdos(
              filtro: _filtro,
              hoy: hoy,
              alCambiar: (filtro) => setState(() => _filtro = filtro),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    key: const Key('boton-agregar-filtro'),
                    onPressed:
                        ocupado || _agregandoFiltro ? null : _agregarTodosDelFiltro,
                    icon: const Icon(Icons.playlist_add),
                    label: const Text('Agregar todos'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    key: const Key('boton-elegir-a-mano'),
                    onPressed: ocupado ? null : _elegirAMano,
                    icon: const Icon(Icons.touch_app_outlined),
                    label: const Text('Elegir a mano'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _Titulo(
              'Recuerdos (${estado.recuerdos.length}/'
              '${ValidadorMomento.recuerdosMax})',
            ),
            const SizedBox(height: 8),
            if (estado.recuerdos.isEmpty)
              const Text(
                'Aún no agregaste recuerdos.',
                style: TextStyle(color: ColoresApp.atenuado),
              ),
            for (final recuerdo in estado.recuerdos)
              TarjetaRecuerdoElegido(
                key: ValueKey(recuerdo.id),
                recuerdo: recuerdo,
                alQuitar: ocupado ? null : () => _controlador.quitar(recuerdo.id),
              ),
            if (estado.visuales.isNotEmpty) ...[
              const SizedBox(height: 12),
              const _Titulo('Portada'),
              const SizedBox(height: 8),
              SizedBox(
                height: 84,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: estado.visuales.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, indice) {
                    final recuerdo = estado.visuales[indice];
                    final elegida = recuerdo.id == estado.portadaId;
                    return Semantics(
                      selected: elegida,
                      button: true,
                      label: 'Portada: ${recuerdo.nombre}',
                      child: GestureDetector(
                        key: ValueKey('portada-${recuerdo.id}'),
                        onTap: ocupado
                            ? null
                            : () => _controlador.elegirPortada(recuerdo.id),
                        child: Container(
                          width: 84,
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            borderRadius:
                                BorderRadius.circular(TemaApp.radioPequeno + 3),
                            border: Border.all(
                              color: elegida
                                  ? ColoresApp.acento
                                  : Colors.transparent,
                              width: 3,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius:
                                BorderRadius.circular(TemaApp.radioPequeno),
                            child: MiniaturaRecuerdoFirmada(
                              recuerdo: recuerdo,
                              tamanoIcono: 22,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
            const SizedBox(height: 28),
            BotonPrincipal(
              etiqueta: 'Guardar momento',
              cargando: ocupado,
              alPresionar: _guardar,
            ),
          ],
        ),
      ),
    );
  }
}

class _Titulo extends StatelessWidget {
  const _Titulo(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) => Text(
        texto,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: ColoresApp.primario,
              fontWeight: FontWeight.w700,
            ),
      );
}
