import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../nucleo/enrutador/rutas_app.dart';
import '../../../nucleo/errores/fallo_app.dart';
import '../../../nucleo/tema/colores_app.dart';
import '../aplicacion/proveedores_momentos.dart';
import 'componentes/tarjeta_momento.dart';

/// Pestaña "Momentos": rejilla de los momentos del usuario.
class PantallaMomentos extends ConsumerWidget {
  const PantallaMomentos({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final momentos = ref.watch(proveedorMomentos);
    return Scaffold(
      appBar: AppBar(title: const Text('Momentos')),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'nuevo-momento',
        onPressed: () => context.push(RutasApp.nuevoMomento),
        icon: const Icon(Icons.add),
        label: const Text('Nuevo momento'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(proveedorMomentos);
          await ref.read(proveedorMomentos.future);
        },
        child: momentos.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _Mensaje(
            texto: mensajeParaUsuario(error),
            accion: OutlinedButton(
              onPressed: () => ref.invalidate(proveedorMomentos),
              child: const Text('Reintentar'),
            ),
          ),
          data: (lista) => lista.isEmpty
              ? const _Mensaje(
                  texto: 'Aún no tienes momentos. Junta varios recuerdos '
                      'bajo un mismo nombre: un viaje, un cumpleaños, un año.',
                )
              : GridView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.8,
                  ),
                  itemCount: lista.length,
                  itemBuilder: (context, indice) {
                    final momento = lista[indice];
                    return TarjetaMomento(
                      key: ValueKey(momento.id),
                      momento: momento,
                      alTocar: () =>
                          context.push(RutasApp.detalleMomentoDe(momento.id)),
                    );
                  },
                ),
        ),
      ),
    );
  }
}

class _Mensaje extends StatelessWidget {
  const _Mensaje({required this.texto, this.accion});

  final String texto;
  final Widget? accion;

  @override
  Widget build(BuildContext context) {
    final boton = accion;
    return ListView(
      padding: const EdgeInsets.all(32),
      children: [
        const SizedBox(height: 80),
        const Icon(
          Icons.auto_awesome_mosaic_outlined,
          size: 48,
          color: ColoresApp.acento,
        ),
        const SizedBox(height: 12),
        Text(
          texto,
          textAlign: TextAlign.center,
          style: const TextStyle(color: ColoresApp.atenuado),
        ),
        if (boton != null) ...[const SizedBox(height: 16), Center(child: boton)],
      ],
    );
  }
}
