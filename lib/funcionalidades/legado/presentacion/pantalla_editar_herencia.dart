import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../nucleo/componentes/avisos_emergentes.dart';
import '../../../nucleo/componentes/cabecera_detalle_capsoul.dart';
import '../../../nucleo/componentes/pantalla_capsoul.dart';
import '../../../nucleo/formato/fechas.dart';
import '../../../nucleo/formato/valor_monetario.dart';
import '../../capsulas/aplicacion/proveedores_capsulas.dart';
import '../aplicacion/proveedores_legado.dart';
import '../dominio/condicion_herencia.dart';
import '../dominio/fallo_legado.dart';
import '../dominio/metadatos_herencia.dart';

class PantallaEditarHerencia extends ConsumerStatefulWidget {
  const PantallaEditarHerencia({super.key, required this.herenciaId});

  final String herenciaId;

  @override
  ConsumerState<PantallaEditarHerencia> createState() =>
      _PantallaEditarHerenciaState();
}

class _PantallaEditarHerenciaState extends ConsumerState<PantallaEditarHerencia> {
  final _tituloCtrl = TextEditingController();
  final _descripcionCtrl = TextEditingController();
  final _tipoCtrl = TextEditingController();
  final _titularCtrl = TextEditingController();
  final _valorCtrl = TextEditingController();
  final _instruccionesCtrl = TextEditingController();
  DateTime? _fecha;
  bool _cargado = false;
  bool _guardando = false;

  @override
  void dispose() {
    _tituloCtrl.dispose();
    _descripcionCtrl.dispose();
    _tipoCtrl.dispose();
    _titularCtrl.dispose();
    _valorCtrl.dispose();
    _instruccionesCtrl.dispose();
    super.dispose();
  }

  void _rellenarSiHaceFalta() {
    if (_cargado) return;
    final detalle = ref.read(proveedorDetalleHerencia(widget.herenciaId)).value;
    if (detalle == null) return;
    final h = detalle.herencia;
    _tituloCtrl.text = h.titulo;
    _descripcionCtrl.text = h.descripcion ?? '';
    _tipoCtrl.text = h.metadatos.tipoActivo ?? '';
    _titularCtrl.text = h.metadatos.titular ?? '';
    _valorCtrl.text = h.metadatos.valorFormateado;
    _instruccionesCtrl.text = h.metadatos.instrucciones ?? '';
    _fecha = h.fechaActivacion;
    _cargado = true;
  }

  Future<void> _guardar() async {
    final valor = parsearEnteroMiles(_valorCtrl.text);
    if (_tituloCtrl.text.trim().isEmpty ||
        _tipoCtrl.text.trim().isEmpty ||
        _titularCtrl.text.trim().isEmpty ||
        _instruccionesCtrl.text.trim().isEmpty) {
      mostrarAvisoError(context, FalloLegado.campoObligatorio);
      return;
    }
    if (valor == null || valor <= 0) {
      mostrarAvisoError(context, FalloLegado.valorInvalido);
      return;
    }
    setState(() => _guardando = true);
    try {
      await ref.read(proveedorRepositorioLegado).actualizarHerenciaSellada(
            herenciaId: widget.herenciaId,
            titulo: _tituloCtrl.text.trim(),
            descripcion: _descripcionCtrl.text.trim(),
            metadatos: MetadatosHerencia(
              tipoActivo: _tipoCtrl.text.trim(),
              titular: _titularCtrl.text.trim(),
              valorAproximado: valor,
              instrucciones: _instruccionesCtrl.text.trim(),
            ),
            fechaActivacion: _fecha,
          );
      ref.invalidate(proveedorDetalleHerencia(widget.herenciaId));
      ref.invalidate(proveedorGruposLegadoBeneficiario);
      if (mounted) {
        mostrarAvisoInformativo(context, 'Herencia actualizada.');
        context.pop();
      }
    } catch (e) {
      if (mounted) mostrarAvisoError(context, e);
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final detalle = ref.watch(proveedorDetalleHerencia(widget.herenciaId));
    _rellenarSiHaceFalta();
    return PantallaCapsoul(
      cuerpo: Column(
        children: [
          const CabeceraDetalleCapsoul(
            titulo: 'Editar herencia',
            subtitulo: 'Solo mientras siga sellada',
          ),
          Expanded(
            child: detalle.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => const Center(child: Text('No se pudo cargar.')),
              data: (d) {
                final ahora = ref.watch(proveedorReloj)();
                if (!d.herencia.sePuedeEditar(ahora: ahora)) {
                  return const Center(
                    child: Text('Esta herencia ya no se puede editar.'),
                  );
                }
                return ListView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  children: [
                    TextField(
                      controller: _tituloCtrl,
                      decoration: const InputDecoration(labelText: 'Título *'),
                    ),
                    TextField(
                      controller: _descripcionCtrl,
                      minLines: 3,
                      maxLines: 5,
                      decoration:
                          const InputDecoration(labelText: 'Descripción *'),
                    ),
                    TextField(
                      controller: _tipoCtrl,
                      decoration: const InputDecoration(labelText: 'Tipo *'),
                    ),
                    TextField(
                      controller: _titularCtrl,
                      decoration: const InputDecoration(labelText: 'Titular *'),
                    ),
                    TextField(
                      controller: _valorCtrl,
                      keyboardType: TextInputType.number,
                      inputFormatters: const [FormateadorMilesInput()],
                      decoration: const InputDecoration(
                        labelText: 'Valor aproximado *',
                        prefixText: '\$ ',
                      ),
                    ),
                    TextField(
                      controller: _instruccionesCtrl,
                      minLines: 3,
                      maxLines: 6,
                      decoration: const InputDecoration(
                        labelText: 'Instrucciones *',
                      ),
                    ),
                    if (d.herencia.condicionActivacion ==
                        CondicionHerencia.fecha)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Fecha de activación'),
                        subtitle: Text(
                          _fecha == null
                              ? 'Elige un día futuro'
                              : formatearFechaCorta(_fecha!),
                        ),
                        trailing: const Icon(Icons.calendar_today_outlined),
                        onTap: () async {
                          final ahoraLocal = DateTime.now();
                          final manana = DateTime(
                            ahoraLocal.year,
                            ahoraLocal.month,
                            ahoraLocal.day + 1,
                          );
                          final elegida = await showDatePicker(
                            context: context,
                            firstDate: manana,
                            lastDate: DateTime(ahoraLocal.year + 100),
                            initialDate: _fecha ?? manana,
                          );
                          if (elegida != null) {
                            setState(() => _fecha = elegida);
                          }
                        },
                      ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _guardando ? null : _guardar,
                      child: _guardando
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Guardar cambios'),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
