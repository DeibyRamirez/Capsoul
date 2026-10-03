import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../nucleo/componentes/avisos_emergentes.dart';
import '../../../nucleo/componentes/boton_principal.dart';
import '../../../nucleo/formato/fechas.dart';
import '../../../nucleo/tema/colores_app.dart';
import '../../capsulas/aplicacion/proveedores_capsulas.dart';
import '../../elementos/dominio/elemento_borrador.dart';
import '../aplicacion/controlador_recuerdos.dart';
import '../dominio/filtro_recuerdos.dart';
import '../dominio/nuevo_recuerdo.dart';
import '../dominio/validador_recuerdo.dart';
import 'componentes/vista_previa_borrador.dart';

/// "Guardar recuerdo": vista previa, título opcional y fecha del recuerdo.
/// Al guardar sube el medio y vuelve con el [Recuerdo] creado.
class PantallaGuardarRecuerdo extends ConsumerStatefulWidget {
  const PantallaGuardarRecuerdo({super.key, required this.elemento});

  final ElementoBorrador elemento;

  @override
  ConsumerState<PantallaGuardarRecuerdo> createState() =>
      _EstadoPantallaGuardarRecuerdo();
}

class _EstadoPantallaGuardarRecuerdo
    extends ConsumerState<PantallaGuardarRecuerdo> {
  final _titulo = TextEditingController();
  late DateTime _fecha = FiltroRecuerdos.soloDia(ref.read(proveedorReloj)());

  @override
  void dispose() {
    _titulo.dispose();
    super.dispose();
  }

  Future<void> _elegirFecha() async {
    final hoy = FiltroRecuerdos.soloDia(ref.read(proveedorReloj)());
    final elegida = await showDatePicker(
      context: context,
      helpText: 'Fecha del recuerdo',
      cancelText: 'Cancelar',
      confirmText: 'Elegir',
      firstDate: ValidadorRecuerdo.primeraFecha,
      lastDate: hoy,
      initialDate: _fecha.isAfter(hoy) ? hoy : _fecha,
    );
    if (elegida != null && mounted) setState(() => _fecha = elegida);
  }

  Future<void> _guardar() async {
    FocusScope.of(context).unfocus();
    final recuerdo = await ref.read(proveedorControladorRecuerdos.notifier).guardar(
          NuevoRecuerdo(
            elemento: widget.elemento,
            fechaRecuerdo: _fecha,
            titulo: _titulo.text,
          ),
        );
    if (recuerdo == null || !mounted) return;
    mostrarAvisoInformativo(context, 'Guardado en tus recuerdos.');
    context.pop(recuerdo);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(proveedorControladorRecuerdos, (anterior, siguiente) {
      final error = siguiente.error;
      if (error != null && error != anterior?.error) {
        mostrarAvisoError(context, error);
        ref.read(proveedorControladorRecuerdos.notifier).limpiarError();
      }
    });
    final ocupado = ref.watch(
      proveedorControladorRecuerdos.select((estado) => estado.ocupado),
    );
    return Scaffold(
      appBar: AppBar(title: const Text('Guardar recuerdo')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            VistaPreviaBorrador(elemento: widget.elemento),
            const SizedBox(height: 20),
            TextField(
              key: const Key('campo-titulo-recuerdo'),
              controller: _titulo,
              enabled: !ocupado,
              maxLength: ValidadorRecuerdo.caracteresMaxTitulo,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Título (opcional)',
                hintText: 'Ej.: Cumpleaños de la abuela',
              ),
            ),
            const SizedBox(height: 8),
            InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Fecha del recuerdo',
                contentPadding: EdgeInsets.zero,
              ),
              child: ListTile(
                key: const Key('campo-fecha-recuerdo'),
                leading: const Icon(
                  Icons.event_outlined,
                  color: ColoresApp.acento,
                ),
                title: Text(formatearFechaCorta(_fecha)),
                trailing: const Icon(Icons.calendar_month_outlined),
                onTap: ocupado ? null : _elegirFecha,
              ),
            ),
            const SizedBox(height: 28),
            BotonPrincipal(
              etiqueta: 'Guardar recuerdo',
              cargando: ocupado,
              alPresionar: _guardar,
            ),
          ],
        ),
      ),
    );
  }
}
