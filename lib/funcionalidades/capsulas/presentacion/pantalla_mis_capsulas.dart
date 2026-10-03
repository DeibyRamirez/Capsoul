import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../nucleo/componentes/frasco_luminoso.dart';
import '../../../nucleo/enrutador/rutas_app.dart';
import '../../../nucleo/errores/fallo_app.dart';
import '../../../nucleo/tema/colores_app.dart';
import '../aplicacion/proveedores_capsulas.dart';
import '../dominio/apertura_capsula.dart';
import '../dominio/capsula.dart';

/// Lista de las cápsulas creadas por el usuario.
class PantallaMisCapsulas extends ConsumerWidget {
  const PantallaMisCapsulas({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final capsulas = ref.watch(proveedorMisCapsulas);
    final ahora = ref.watch(proveedorReloj)();
    return Scaffold(
      appBar: AppBar(title: const Text('Mis cápsulas')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(RutasApp.crearCapsula),
        icon: const Icon(Icons.add),
        label: const Text('Nueva cápsula'),
      ),
      body: capsulas.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _Aviso(
          mensaje: mensajeParaUsuario(error),
          etiquetaAccion: 'Reintentar',
          alTocar: () => ref.invalidate(proveedorMisCapsulas),
        ),
        data: (lista) => lista.isEmpty
            ? _Aviso(
                mensaje: 'Aún no tienes cápsulas. Guarda hoy algo para '
                    'abrirlo en el futuro.',
                etiquetaAccion: 'Crear mi primera cápsula',
                alTocar: () => context.push(RutasApp.crearCapsula),
              )
            : RefreshIndicator(
                onRefresh: () => ref.refresh(proveedorMisCapsulas.future),
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                  itemCount: lista.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, i) => _FilaCapsula(
                    key: ValueKey(lista[i].id),
                    capsula: lista[i],
                    ahora: ahora,
                  ),
                ),
              ),
      ),
    );
  }
}

class _FilaCapsula extends StatelessWidget {
  const _FilaCapsula({super.key, required this.capsula, required this.ahora});

  final Capsula capsula;
  final DateTime ahora;

  @override
  Widget build(BuildContext context) {
    final fecha = capsula.fechaApertura;
    final lista = fecha != null && !fecha.isAfter(ahora);
    return Card(
      color: ColoresApp.sobrePrimario,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        leading: FrascoLuminoso(
          tamano: 52,
          brillo: lista ? 0.95 : 0.5,
          conCandado: !lista,
        ),
        title: Text(
          capsula.titulo,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          fecha == null
              ? 'Sin fecha de apertura'
              : (lista
                  ? 'Lista para abrir'
                  : 'Abre el ${formatearFechaCorta(fecha)}'),
        ),
        trailing: const Icon(Icons.chevron_right, color: ColoresApp.atenuado),
        onTap: () => context.push(RutasApp.detalleCapsulaDe(capsula.id)),
      ),
    );
  }
}

class _Aviso extends StatelessWidget {
  const _Aviso({
    required this.mensaje,
    required this.etiquetaAccion,
    required this.alTocar,
  });

  final String mensaje;
  final String etiquetaAccion;
  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const FrascoLuminoso(tamano: 120, brillo: 0.6),
            const SizedBox(height: 16),
            Text(
              mensaje,
              textAlign: TextAlign.center,
              style: const TextStyle(color: ColoresApp.atenuado),
            ),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: alTocar, child: Text(etiquetaAccion)),
          ],
        ),
      ),
    );
  }
}
