import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../nucleo/componentes/avisos_emergentes.dart';
import '../../../nucleo/formato/fechas.dart';
import '../../../nucleo/formato/valor_monetario.dart';
import '../../../nucleo/tema/colores_app.dart';
import '../../amistades/aplicacion/proveedores_amistades.dart';
import '../../amistades/dominio/amigo.dart';
import '../../autenticacion/aplicacion/proveedores_autenticacion.dart';
import '../../capsulas/aplicacion/proveedores_capsulas.dart';
import '../../capsulas/dominio/capsula.dart';
import '../../capsulas/dominio/estado_capsula.dart';
import '../aplicacion/controlador_nueva_herencia.dart';
import '../aplicacion/proveedores_legado.dart';
import 'heroes_legado.dart';

class PantallaNuevaHerencia extends ConsumerStatefulWidget {
  const PantallaNuevaHerencia({super.key});

  @override
  ConsumerState<PantallaNuevaHerencia> createState() =>
      _PantallaNuevaHerenciaState();
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
    try {
      await ctrl.validarPasoActual();
    } catch (e) {
      if (mounted) mostrarAvisoError(context, e);
      return;
    }
    // Se relee el borrador: _persistirPasoActual acaba de guardar los campos
    // del paso. Usar `b` (lectura anterior) los borraría al avanzar.
    final actualizado = ref.read(proveedorControladorNuevaHerencia);
    if (actualizado.paso < BorradorNuevaHerencia.totalPasos - 1) {
      _pasoSincronizado = null;
      ctrl.actualizar(actualizado.copiar(paso: actualizado.paso + 1));
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
    final actualizado = ref.read(proveedorControladorNuevaHerencia);
    if (actualizado.paso > 0) {
      _pasoSincronizado = null;
      ctrl.actualizar(actualizado.copiar(paso: actualizado.paso - 1));
    }
  }

  String _nombreConfianza(
    BorradorNuevaHerencia b,
    List<Amigo> amigos,
    String? confianzaGlobalId,
  ) {
    final id = b.personaConfianzaUsuarioId ?? confianzaGlobalId;
    if (id == null || id.isEmpty) return 'Elige una persona de confianza';
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

  Future<void> _elegirConfianzaHerencia(
    BorradorNuevaHerencia b,
    List<Amigo> amigos,
    String? confianzaGlobalId,
  ) async {
    if (amigos.isEmpty) {
      mostrarAvisoInformativo(
        context,
        'Primero agrega amigos para elegir persona de confianza.',
      );
      return;
    }
    final global = _nombreConfianza(
      b.copiar(usarConfianzaGlobal: true),
      amigos,
      confianzaGlobalId,
    );
    final elegido = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: Text('Persona de confianza de esta herencia'),
            ),
            ListTile(
              leading: const Icon(Icons.people_outline),
              title: const Text('La misma de Mi legado'),
              subtitle: Text(global),
              trailing: b.personaConfianzaUsuarioId == null
                  ? const Icon(Icons.check)
                  : null,
              onTap: () => Navigator.pop(ctx, ''),
            ),
            const Divider(),
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
                trailing: b.personaConfianzaUsuarioId == a.usuarioId
                    ? const Icon(Icons.check)
                    : null,
                onTap: () => Navigator.pop(ctx, a.usuarioId),
              ),
          ],
        ),
      ),
    );
    if (elegido == null || !mounted) return;
    final ctrl = ref.read(proveedorControladorNuevaHerencia.notifier);
    final actual = ref.read(proveedorControladorNuevaHerencia);
    if (elegido.isEmpty) {
      ctrl.actualizar(actual.copiar(usarConfianzaGlobal: true));
    } else {
      ctrl.actualizar(
        actual.copiar(personaConfianzaUsuarioId: elegido),
      );
    }
  }

  Future<void> _finalizar() async {
    setState(() => _guardando = true);
    try {
      final b = ref.read(proveedorControladorNuevaHerencia);
      _persistirPasoActual(b);
      _cerrarTeclado();
      final id = await ref
          .read(proveedorControladorNuevaHerencia.notifier)
          .guardarYActivar();
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
    final uid = ref.watch(proveedorEstadoAutenticacion).value?.uid;
    final capsulas = (ref.watch(proveedorMisCapsulas).value ??
            const <Capsula>[])
        .where(
          (c) =>
              uid != null &&
              c.autorId == uid &&
              (c.estado == EstadoCapsula.programada ||
                  c.estado == EstadoCapsula.liberada),
        )
        .toList();
    final confianzaGlobalId =
        ref.watch(proveedorPersonaConfianzaLegadoId).value;

    _sincronizarControladoresConBorrador(borrador);

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Hero(
          tag: HeroesLegado.nuevaHerencia,
          child: Material(
            type: MaterialType.transparency,
            child: Text(
              'Nueva pequeña herencia',
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Paso $paso de ${BorradorNuevaHerencia.totalPasos}'),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: progreso,
                color: ColoresApp.primario,
              ),
              const SizedBox(height: 24),
              Expanded(
                child: _contenidoPaso(
                  borrador,
                  amigos,
                  capsulas,
                  confianzaGlobalId,
                ),
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
    String? confianzaGlobalId,
  ) {
    final ctrl = ref.read(proveedorControladorNuevaHerencia.notifier);
    switch (b.paso) {
      case 0:
        return _pasoDesplazable(
          pasoKey: const ValueKey('paso_descripcion'),
          children: [
            Text(
              '¿Qué quieres dejar?',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text(
              'Describe objetos, cuentas o recuerdos (obligatorio, máx. 300).',
            ),
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
              child: RadioGroup<String>(
                groupValue: b.beneficiarioUsuarioId,
                onChanged: (v) =>
                    ctrl.actualizar(b.copiar(beneficiarioUsuarioId: v)),
                child: ListView(
                  children: [
                    for (final a in amigos)
                      RadioListTile<String>(
                        value: a.usuarioId,
                        title: Text(a.nombreVisible),
                        subtitle: a.nombreUsuario != null
                            ? Text('@${a.nombreUsuario}')
                            : null,
                      ),
                  ],
                ),
              ),
            ),
          ],
        );
      case 2:
        return _pasoDesplazable(
          pasoKey: const ValueKey('paso_mensaje_personal'),
          children: [
            Text(
              'Mensaje personal',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text(
              'Unas palabras para quien reciba esta herencia (obligatorio).',
            ),
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
            Text(
              'Datos del activo',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text(
              'Todos los datos del activo son obligatorios. El valor es numérico.',
            ),
            const SizedBox(height: 16),
            TextField(
              key: const ValueKey('campo_tipo_activo'),
              controller: _tipoActivoCtrl,
              decoration: const InputDecoration(
                labelText: 'Tipo (CDT, objeto…) *',
              ),
            ),
            TextField(
              key: const ValueKey('campo_titular'),
              controller: _titularCtrl,
              decoration: const InputDecoration(labelText: 'Titular *'),
            ),
            TextField(
              key: const ValueKey('campo_valor_aproximado'),
              controller: _valorAproximadoCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: const [FormateadorMilesInput()],
              decoration: const InputDecoration(
                labelText: 'Valor aproximado *',
                hintText: '1.250.000',
                prefixText: '\$ ',
              ),
            ),
            TextField(
              key: const ValueKey('campo_instrucciones_activo'),
              controller: _instruccionesCtrl,
              minLines: 3,
              maxLines: 6,
              decoration: const InputDecoration(
                labelText: 'Instrucciones del activo *',
              ),
            ),
          ],
        );
      case 4:
        return _pasoDesplazable(
          pasoKey: const ValueKey('paso_fecha_apertura'),
          children: [
            const Text('Fecha de apertura'),
            const SizedBox(height: 8),
            const Text(
              'La herencia se abre automáticamente el día que elijas. '
              'Ese día el beneficiario recibe el aviso y la persona de '
              'confianza recibe un código por correo para ver el contenido '
              'y ayudar.',
            ),
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
            const SizedBox(height: 12),
            ListTile(
              key: const ValueKey('campo_persona_confianza_herencia'),
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.shield_outlined),
              title: const Text('Persona de confianza de esta herencia'),
              subtitle: Text(
                '${_nombreConfianza(b, amigos, confianzaGlobalId)}. '
                'Recibirá un código por correo cuando la herencia se abra.',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () =>
                  _elegirConfianzaHerencia(b, amigos, confianzaGlobalId),
            ),
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
                  if (capsulas.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Text(
                        'No tienes cápsulas propias programadas o abiertas '
                        'para vincular. Las cápsulas que te enviaron otras '
                        'personas no se pueden vincular.',
                      ),
                    ),
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
