import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../nucleo/componentes/avisos_emergentes.dart';
import '../aplicacion/proveedores_legado.dart';

class PantallaInstruccionesLegado extends ConsumerStatefulWidget {
  const PantallaInstruccionesLegado({super.key});

  @override
  ConsumerState<PantallaInstruccionesLegado> createState() =>
      _PantallaInstruccionesLegadoState();
}

class _PantallaInstruccionesLegadoState extends ConsumerState<PantallaInstruccionesLegado> {
  final _ctrl = TextEditingController();
  bool _cargado = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    try {
      await ref.read(proveedorRepositorioLegado).guardarInstrucciones(_ctrl.text);
      ref.invalidate(proveedorInstruccionesLegado);
      ref.invalidate(proveedorResumenLegado);
      if (mounted) {
        mostrarAvisoInformativo(context, 'Instrucciones guardadas.');
        context.pop();
      }
    } catch (e) {
      if (mounted) mostrarAvisoError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(proveedorInstruccionesLegado);
    async.whenData((texto) {
      if (!_cargado) {
        _ctrl.text = texto ?? '';
        _cargado = true;
      }
    });
    return Scaffold(
      appBar: AppBar(title: const Text('Mis instrucciones')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _ctrl,
              maxLines: 12,
              decoration: const InputDecoration(
                hintText: 'Lo que quiero que sepan…',
                border: OutlineInputBorder(),
              ),
            ),
            const Spacer(),
            FilledButton(
              onPressed: _guardar,
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }
}
