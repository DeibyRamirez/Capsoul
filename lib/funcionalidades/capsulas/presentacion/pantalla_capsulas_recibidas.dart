import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../nucleo/componentes/frasco_luminoso.dart';
import '../../../nucleo/componentes/pantalla_capsoul.dart';
import '../../../nucleo/enrutador/rutas_app.dart';
import '../../../nucleo/errores/fallo_app.dart';
import '../../../nucleo/tema/colores_app.dart';
import '../aplicacion/proveedores_capsulas.dart';
import '../dominio/apertura_capsula.dart';
import '../dominio/capsula_recibida.dart';

/// Cápsulas enviadas a este usuario como destinatario.
class PantallaCapsulasRecibidas extends ConsumerWidget {
  const PantallaCapsulasRecibidas({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recibidas = ref.watch(proveedorCapsulasRecibidas);
    final ahora = ref.watch(proveedorReloj)();
    return PantallaCapsoul(
      appBar: AppBar(title: const Text('Para mí')),
      cuerpo: recibidas.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(mensajeParaUsuario(error), textAlign: TextAlign.center),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () => ref.invalidate(proveedorCapsulasRecibidas),
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          ),
        ),
        data: (lista) => lista.isEmpty
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'Aún no tienes cápsulas de otras personas. '
                    'Cuando alguien te envíe una, aparecerá aquí.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: ColoresApp.atenuado),
                  ),
                ),
              )
            : RefreshIndicator(
                onRefresh: () => ref.refresh(proveedorCapsulasRecibidas.future),
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                  itemCount: lista.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, i) => _FilaRecibida(
                    recibida: lista[i],
                    ahora: ahora,
                    alTocar: () => context.push(
                      RutasApp.detalleCapsulaDe(lista[i].id),
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}

class _FilaRecibida extends StatelessWidget {
  const _FilaRecibida({
    required this.recibida,
    required this.ahora,
    required this.alTocar,
  });

  final CapsulaRecibida recibida;
  final DateTime ahora;
  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) {
    final liberada = recibida.estaLiberada;
    final fecha = recibida.fechaApertura;
    final subtitulo = liberada
        ? 'De ${recibida.autorNombre}'
        : 'De ${recibida.autorNombre} · se abre el ${formatearFechaCorta(fecha)}';
    return Card(
      color: ColoresApp.sobrePrimario,
      child: ListTile(
        onTap: alTocar,
        leading: FrascoLuminoso(
          tamano: 52,
          brillo: liberada ? 0.95 : 0.45,
          conCandado: !liberada,
        ),
        title: Text(
          recibida.tituloVisible,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(subtitulo),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
