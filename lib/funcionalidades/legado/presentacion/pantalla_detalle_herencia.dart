import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../nucleo/componentes/avisos_emergentes.dart';
import '../../../nucleo/componentes/cabecera_detalle_capsoul.dart';
import '../../../nucleo/componentes/pantalla_capsoul.dart';
import '../../../nucleo/enrutador/rutas_app.dart';
import '../../../nucleo/tema/colores_app.dart';
import '../../autenticacion/aplicacion/proveedores_autenticacion.dart';
import '../../capsulas/aplicacion/proveedores_capsulas.dart';
import '../../capsulas/presentacion/componentes/miniatura_imagen_capsula.dart';
import '../../capsulas/presentacion/heroes_capsula.dart';
import '../aplicacion/proveedores_legado.dart';
import '../dominio/estado_herencia.dart';

class PantallaDetalleHerencia extends ConsumerWidget {
  const PantallaDetalleHerencia({super.key, required this.herenciaId});

  final String herenciaId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detalle = ref.watch(proveedorDetalleHerencia(herenciaId));
    final uid = ref.watch(proveedorEstadoAutenticacion).value?.uid;
    final ahora = ref.watch(proveedorReloj)();
    return PantallaCapsoul(
      cuerpo: Column(
        children: [
          const CabeceraDetalleCapsoul(
            titulo: 'Detalle de legado',
            subtitulo: 'Pequeña herencia',
          ),
          Expanded(
            child: detalle.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) =>
                  const Center(child: Text('No pudimos cargar la herencia.')),
              data: (d) {
                final h = d.herencia;
                final meta = h.metadatos;
                final esDueno = uid != null && uid == h.propietarioId;
                final verContenido =
                    meta.tipoActivo != null ||
                    meta.titular != null ||
                    meta.valorAproximado != null;
                final editable = esDueno && h.sePuedeEditar(ahora: ahora);
                return ListView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  children: [
                    const SizedBox(height: 16),

                    Expanded(
                      child: Text(
                        h.titulo,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: ColoresApp.acento.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(h.etiquetaEstado(ahora: ahora)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (!verContenido && h.estado != EstadoHerencia.liberada)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 16),
                        child: Text(
                          'Esta herencia sigue sellada. Verás el contenido cuando se active.',
                        ),
                      ),
                    _fila('Activo', meta.tipoActivo),
                    _fila('Titular', meta.titular),
                    _fila(
                      'Valor aproximado',
                      meta.valorAproximado == null
                          ? null
                          : '${meta.valorFormateado} ${meta.moneda}',
                    ),
                    _fila('Instrucciones', meta.instrucciones),
                    if (h.descripcion != null)
                      _fila('Descripción', h.descripcion),
                    const SizedBox(height: 16),
                    Text('Cápsulas vinculadas (${d.capsulas.length})'),
                    for (final c in d.capsulas)
                      ListTile(
                        key: ValueKey(c.capsulaId),
                        contentPadding: EdgeInsets.zero,
                        isThreeLine: true,
                        leading: MiniaturaImagenCapsula(
                          imagenClave: c.imagenClave,
                          ancho: 48,
                          conCandado: c.estado != 'liberada',
                          heroTag: HeroesCapsula.imagen(c.capsulaId),
                        ),
                        title: Text(c.titulo),
                        subtitle: Text(
                          c.estado == 'liberada'
                              ? 'Lista para abrir'
                              : 'Respeta su fecha de apertura',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.push(
                          RutasApp.detalleCapsulaDe(c.capsulaId),
                        ),
                      ),
                    const SizedBox(height: 24),
                    if (editable)
                      FilledButton(
                        onPressed: () =>
                            context.push(RutasApp.editarHerenciaDe(herenciaId)),
                        child: const Text('Editar información'),
                      )
                    else if (esDueno)
                      const Text(
                        'Ya no se puede editar: fue abierta o llegó la fecha.',
                      ),
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: () async {
                        await ref
                            .read(proveedorRepositorioLegado)
                            .solicitarRespaldoLegal(herenciaId);
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
          ),
        ],
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
