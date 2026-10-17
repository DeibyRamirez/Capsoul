import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../nucleo/componentes/avisos_emergentes.dart';
import '../../../nucleo/formato/fechas.dart';
import '../../../nucleo/tema/colores_app.dart';
import '../../amistades/aplicacion/proveedores_amistades.dart';
import '../../amistades/dominio/amigo.dart';
import '../../capsulas/aplicacion/proveedores_capsulas.dart';
import '../../capsulas/dominio/capsula.dart';
import '../aplicacion/controlador_nueva_herencia.dart';
import '../dominio/condicion_herencia.dart';

class PantallaNuevaHerencia extends ConsumerStatefulWidget {
  const PantallaNuevaHerencia({super.key});

  @override
  ConsumerState<PantallaNuevaHerencia> createState() => _PantallaNuevaHerenciaState();
}

class _PantallaNuevaHerenciaState extends ConsumerState<PantallaNuevaHerencia> {
  final _descripcionCtrl = TextEditingController();
  final _mensajePersonalCtrl = TextEditingController();
  final _tipoActivoCtrl = TextEditingController();
  final _titularCtrl = TextEditingController();
  final _valorAproximadoCtrl = TextEditingController();
  final _instruccionesCtrl = TextEditingController();
  bool _guardando = false;
  int? _pasoSincronizado;

  @override
  void dispose() {
    _descripcionCtrl.dispose();
    _mensajePersonalCtrl.dispose();
    _tipoActivoCtrl.dispose();
    _titularCtrl.dispose();
    _valorAproximadoCtrl.dispose();
    _instruccionesCtrl.dispose();
    super.dispose();
  }

  void _cerrarTeclado() => FocusManager.instance.primaryFocus?.unfocus();

  void _persistirPasoActual(BorradorNuevaHerencia b) {
    final ctrl = ref.read(proveedorControladorNuevaHerencia.notifier);
    switch (b.paso) {
      case 0:
        ctrl.actualizar(b.copiar(descripcion: _descripcionCtrl.text));
      case 2:
        ctrl.actualizar(b.copiar(mensajePersonal: _mensajePersonalCtrl.text));
      case 3:
        ctrl.actualizar(
          b.copiar(
            tipoActivo: _tipoActivoCtrl.text,
            titular: _titularCtrl.text,
            valorAproximado: _valorAproximadoCtrl.text,
            instrucciones: _instruccionesCtrl.text,
          ),
        );
    }
  }

  void _sincronizarControladoresConBorrador(BorradorNuevaHerencia b) {
    if (_pasoSincronizado == b.paso) return;
    _pasoSincronizado = b.paso;
    switch (b.paso) {
      case 0:
        if (_descripcionCtrl.text != b.descripcion) {
          _descripcionCtrl.text = b.descripcion;
        }
      case 2:
        if (_mensajePersonalCtrl.text != b.mensajePersonal) {
          _mensajePersonalCtrl.text = b.mensajePersonal;
        }
      case 3:
        if (_tipoActivoCtrl.text != b.tipoActivo) {
          _tipoActivoCtrl.text = b.tipoActivo;
        }
        if (_titularCtrl.text != b.titular) {
          _titularCtrl.text = b.titular;
        }
        if (_valorAproximadoCtrl.text != b.valorAproximado) {
          _valorAproximadoCtrl.text = b.valorAproximado;
        }
        if (_instruccionesCtrl.text != b.instrucciones) {
          _instruccionesCtrl.text = b.instrucciones;
        }
    }
  }

  Future<void> _siguiente() async {
    final ctrl = ref.read(proveedorControladorNuevaHerencia.notifier);
    final b = ref.read(proveedorControladorNuevaHerencia);
    _persistirPasoActual(b);
    _cerrarTeclado();
    if (b.paso == 4) {
      try {
        await ctrl.validarCondicionActivacion();
      } catch (e) {
        if (mounted) mostrarAvisoError(context, e);
        return;
      }
    }
    if (b.paso < BorradorNuevaHerencia.totalPasos - 1) {
      _pasoSincronizado = null;
      ctrl.actualizar(b.copiar(paso: b.paso + 1));
    }
  }

  Future<void> _elegirFechaActivacion(BorradorNuevaHerencia b) async {
    final ahora = DateTime.now();
    final manana = DateTime(ahora.year, ahora.month, ahora.day + 1);
    final inicial = b.fechaActivacion ?? manana;
    final elegida = await showDatePicker(
      context: context,
      helpText: 'Fecha de activación del legado',
      cancelText: 'Cancelar',
      confirmText: 'Elegir',
      firstDate: manana,
      lastDate: DateTime(ahora.year + 100, 12, 31),
      initialDate: inicial.isBefore(manana) ? manana : inicial,
    );
    if (elegida == null || !mounted) return;
    final ctrl = ref.read(proveedorControladorNuevaHerencia.notifier);
    final actual = ref.read(proveedorControladorNuevaHerencia);
    ctrl.actualizar(
      actual.copiar(
        fechaActivacion: DateTime(elegida.year, elegida.month, elegida.day),
      ),
    );
  }

  void _atras() {
    final ctrl = ref.read(proveedorControladorNuevaHerencia.notifier);
    final b = ref.read(proveedorControladorNuevaHerencia);
    _persistirPasoActual(b);
    _cerrarTeclado();
    if (b.paso > 0) {
      _pasoSincronizado = null;
      ctrl.actualizar(b.copiar(paso: b.paso - 1));
    }
  }

  Future<void> _finalizar() async {
    setState(() => _guardando = true);
    try {
      final b = ref.read(proveedorControladorNuevaHerencia);
      _persistirPasoActual(b);
      _cerrarTeclado();
      final id = await ref.read(proveedorControladorNuevaHerencia.notifier).guardarYActivar();
      if (!mounted) return;
      if (id != null) {
        mostrarAvisoInformativo(context, 'Herencia creada y activada.');
        context.pop();
      } else {
        mostrarAvisoError(context, 'Elige un beneficiario.');
      }
    } catch (e) {
      if (mounted) mostrarAvisoError(context, e);
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final borrador = ref.watch(proveedorControladorNuevaHerencia);
    final paso = borrador.paso + 1;
    final progreso = paso / BorradorNuevaHerencia.totalPasos;
    final amigos = ref.watch(proveedorMisAmigos).value ?? const <Amigo>[];
    final capsulas = ref.watch(proveedorMisCapsulas).value ?? const <Capsula>[];

    _sincronizarControladoresConBorrador(borrador);

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(title: const Text('Nueva pequeña herencia')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Paso $paso de ${BorradorNuevaHerencia.totalPasos}'),
              const SizedBox(height: 8),
              LinearProgressIndicator(value: progreso, color: ColoresApp.primario),
              const SizedBox(height: 24),
              Expanded(
                child: _contenidoPaso(borrador, amigos, capsulas),
              ),
              const SizedBox(height: 16),
              if (borrador.paso > 0)
                OutlinedButton(onPressed: _atras, child: const Text('Atrás')),
              if (borrador.paso > 0) const SizedBox(height: 8),
              FilledButton(
                      onPressed: _guardando
                          ? null
                          : (borrador.paso == BorradorNuevaHerencia.totalPasos - 1
                              ? _finalizar
                              : _siguiente),
                      child: _guardando
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(
                              borrador.paso == BorradorNuevaHerencia.totalPasos - 1
                                  ? 'Activar legado'
                                  : 'Continuar',
                            ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pasoDesplazable({
    required Key pasoKey,
    required List<Widget> children,
  }) {
    return SingleChildScrollView(
      key: pasoKey,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _contenidoPaso(
    BorradorNuevaHerencia b,
    List<Amigo> amigos,
    List<Capsula> capsulas,
  ) {
    final ctrl = ref.read(proveedorControladorNuevaHerencia.notifier);
    switch (b.paso) {
      case 0:
        return _pasoDesplazable(
          pasoKey: const ValueKey('paso_descripcion'),
          children: [
            Text('¿Qué quieres dejar?', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            const Text('Describe objetos, cuentas o recuerdos (máx. 300 caracteres).'),
            const SizedBox(height: 16),
            TextField(
              key: const ValueKey('campo_descripcion'),
              controller: _descripcionCtrl,
              minLines: 4,
              maxLines: 8,
              maxLength: 300,
              decoration: const InputDecoration(
                hintText: 'Ej: CDT, llaves, instrucciones…',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        );
      case 1:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('¿Para quién?', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            Expanded(
              child: ListView(
                children: [
                  for (final a in amigos)
                    RadioListTile<String>(
                      value: a.usuarioId,
                      groupValue: b.beneficiarioUsuarioId,
                      onChanged: (v) => ctrl.actualizar(b.copiar(beneficiarioUsuarioId: v)),
                      title: Text(a.nombreVisible),
                      subtitle: a.nombreUsuario != null ? Text('@${a.nombreUsuario}') : null,
                    ),
                ],
              ),
            ),
          ],
        );
      case 2:
        return _pasoDesplazable(
          pasoKey: const ValueKey('paso_mensaje_personal'),
          children: [
            Text('Mensaje personal', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            const Text('Unas palabras para quien reciba esta herencia.'),
            const SizedBox(height: 16),
            TextField(
              key: const ValueKey('campo_mensaje_personal'),
              controller: _mensajePersonalCtrl,
              minLines: 5,
              maxLines: 10,
              decoration: const InputDecoration(
                labelText: 'Tu mensaje',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        );
      case 3:
        return _pasoDesplazable(
          pasoKey: const ValueKey('paso_metadatos_activo'),
          children: [
            Text('Datos del activo', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            const Text('Detalles del CDT, cuenta u objeto (opcional).'),
            const SizedBox(height: 16),
            TextField(
              key: const ValueKey('campo_tipo_activo'),
              controller: _tipoActivoCtrl,
              decoration: const InputDecoration(labelText: 'Tipo (CDT, objeto…)'),
            ),
            TextField(
              key: const ValueKey('campo_titular'),
              controller: _titularCtrl,
              decoration: const InputDecoration(labelText: 'Titular'),
            ),
            TextField(
              key: const ValueKey('campo_valor_aproximado'),
              controller: _valorAproximadoCtrl,
              decoration: const InputDecoration(labelText: 'Valor aproximado'),
            ),
            TextField(
              key: const ValueKey('campo_instrucciones_activo'),
              controller: _instruccionesCtrl,
              minLines: 3,
              maxLines: 6,
              decoration: const InputDecoration(labelText: 'Instrucciones del activo'),
            ),
          ],
        );
      case 4:
        return _pasoDesplazable(
          pasoKey: const ValueKey('paso_condicion'),
          children: [
            const Text('Condición de activación'),
            RadioListTile<CondicionHerencia>(
              value: CondicionHerencia.confirmacionConfianza,
              groupValue: b.condicion,
              onChanged: (v) => ctrl.actualizar(b.copiar(condicion: v)),
              title: const Text('Confirmación de persona de confianza'),
            ),
            RadioListTile<CondicionHerencia>(
              value: CondicionHerencia.fecha,
              groupValue: b.condicion,
              onChanged: (v) => ctrl.actualizar(b.copiar(condicion: v)),
              title: const Text('Fecha programada'),
            ),
            RadioListTile<CondicionHerencia>(
              value: CondicionHerencia.inactividad,
              groupValue: b.condicion,
              onChanged: (v) => ctrl.actualizar(b.copiar(condicion: v)),
              title: const Text('Tras inactividad'),
            ),
            if (b.condicion == CondicionHerencia.fecha) ...[
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Fecha de activación'),
                subtitle: Text(
                  b.fechaActivacion == null
                      ? 'Elige un día a partir de mañana'
                      : formatearFechaCorta(b.fechaActivacion!),
                ),
                trailing: const Icon(Icons.calendar_today_outlined),
                onTap: () => _elegirFechaActivacion(b),
              ),
            ],
          ],
        );
      default:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Vincular cápsulas (opcional)'),
            const SizedBox(height: 8),
            Expanded(
              child: ListView(
                children: [
                  for (final c in capsulas)
                    CheckboxListTile(
                      value: b.capsulaIds.contains(c.id),
                      onChanged: (checked) {
                        final ids = [...b.capsulaIds];
                        if (checked == true) {
                          ids.add(c.id);
                        } else {
                          ids.remove(c.id);
                        }
                        ctrl.actualizar(b.copiar(capsulaIds: ids));
                      },
                      title: Text(c.titulo),
                    ),
                ],
              ),
            ),
          ],
        );
    }
  }
}
