import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../nucleo/componentes/avisos_emergentes.dart';
import '../../../nucleo/componentes/cabecera_detalle_capsoul.dart';
import '../../../nucleo/componentes/pantalla_capsoul.dart';
import '../../../nucleo/formato/fechas.dart';
import '../../../nucleo/formato/valor_monetario.dart';
import '../../amistades/aplicacion/proveedores_amistades.dart';
import '../../amistades/dominio/amigo.dart';
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
  String? _personaConfianzaId;
  String? _personaConfianzaOriginal;
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
    _personaConfianzaId = h.personaConfianzaId;
    _personaConfianzaOriginal = h.personaConfianzaId;
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
      final repo = ref.read(proveedorRepositorioLegado);
      await repo.actualizarHerenciaSellada(
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
      final confianza = _personaConfianzaId;
      if (confianza != null &&
          confianza.isNotEmpty &&
          confianza != _personaConfianzaOriginal) {
        await repo.actualizarPersonaConfianzaHerencia(
          widget.herenciaId,
          confianza,
        );
      }
      ref.invalidate(proveedorDetalleHerencia(widget.herenciaId));
      ref.invalidate(proveedorGruposLegadoBeneficiario);
      ref.invalidate(proveedorHerenciasPorConfirmar);
      ref.invalidate(proveedorHerenciasACuidado);
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

  String _nombreConfianza(List<Amigo> amigos) {
    final id = _personaConfianzaId;
    if (id == null || id.isEmpty) return 'Sin persona de confianza';
    for (final a in amigos) {
      if (a.usuarioId == id) {
        final arroba = a.nombreUsuario;
        return arroba == null || arroba.isEmpty
            ? a.nombreVisible
            : '${a.nombreVisible} (@$arroba)';
      }
    }
    return 'Persona de confianza';
  }

  Future<void> _elegirConfianza(List<Amigo> amigos) async {
    if (amigos.isEmpty) {
      mostrarAvisoInformativo(
        context,
        'Primero agrega amigos para elegir persona de confianza.',
      );
      return;
    }
    final elegido = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: Text('Persona de confianza de esta herencia'),
            ),
            for (final a in amigos)
              ListTile(
                leading: CircleAvatar(
                  child: Text(
                    a.nombreVisible.trim().isEmpty
                        ? '?'
                        : a.nombreVisible.trim().substring(0, 1).toUpperCase(),
                  ),
                ),
                title: Text(a.nombreVisible),
                subtitle: a.nombreUsuario != null
                    ? Text('@${a.nombreUsuario}')
                    : null,
                trailing: _personaConfianzaId == a.usuarioId
                    ? const Icon(Icons.check)
                    : null,
                onTap: () => Navigator.pop(ctx, a.usuarioId),
              ),
          ],
        ),
      ),
    );
    if (elegido == null || !mounted) return;
    setState(() => _personaConfianzaId = elegido);
  }

  @override
  Widget build(BuildContext context) {
    final detalle = ref.watch(proveedorDetalleHerencia(widget.herenciaId));
    final amigos = ref.watch(proveedorMisAmigos).value ?? const <Amigo>[];
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
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.shield_outlined),
                      title: const Text('Persona de confianza'),
                      subtitle: Text(
                        _nombreConfianza(amigos),
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _elegirConfianza(amigos),
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
