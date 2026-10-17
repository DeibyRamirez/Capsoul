import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../nucleo/componentes/avisos_emergentes.dart';
import '../../../nucleo/tema/colores_app.dart';
import '../aplicacion/proveedores_legado.dart';

class PantallaDetalleHerencia extends ConsumerWidget {
  const PantallaDetalleHerencia({super.key, required this.herenciaId});

  final String herenciaId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detalle = ref.watch(proveedorDetalleHerencia(herenciaId));
    return Scaffold(
      appBar: AppBar(title: const Text('Detalle de legado')),
      body: detalle.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const Center(child: Text('No pudimos cargar la herencia.')),
        data: (d) {
          final h = d.herencia;
          final meta = h.metadatos;
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      h.titulo,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                  if (h.estado.requiereRevision)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: ColoresApp.acento.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text('Requiere revisión'),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              _fila('Activo', meta.tipoActivo),
              _fila('Titular', meta.titular),
              _fila('Valor aproximado', meta.valorAproximado),
              _fila('Instrucciones', meta.instrucciones),
              if (h.descripcion != null) _fila('Descripción', h.descripcion),
              const SizedBox(height: 16),
              Text('Cápsulas vinculadas (${d.capsulas.length})'),
              for (final c in d.capsulas)
                ListTile(
                  title: Text(c.titulo),
                  subtitle: Text(c.estado),
                ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () {
                  mostrarAvisoInformativo(context, 'Edición: próximamente en borrador.');
                },
                child: const Text('Editar información'),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () async {
                  await ref.read(proveedorRepositorioLegado).solicitarRespaldoLegal(herenciaId);
                  if (context.mounted) {
                    mostrarAvisoInformativo(
                      context,
                      'Solicitud registrada. Capsoul Legal te contactará.',
                    );
                  }
                },
                child: const Text('Consultar con Capsoul Legal'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _fila(String etiqueta, String? valor) {
    if (valor == null || valor.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(etiqueta, style: const TextStyle(fontWeight: FontWeight.w600)),
          Text(valor),
        ],
      ),
    );
  }
}
