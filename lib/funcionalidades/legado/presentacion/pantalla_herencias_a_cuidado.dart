import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../nucleo/componentes/cabecera_detalle_capsoul.dart';
import '../../../nucleo/componentes/pantalla_capsoul.dart';
import '../../../nucleo/componentes/tarjeta_capsoul.dart';
import '../../../nucleo/enrutador/rutas_app.dart';
import '../../../nucleo/formato/fechas.dart';
import '../../../nucleo/tema/colores_app.dart';
import '../aplicacion/proveedores_legado.dart';
import '../dominio/acceso_herencia.dart';
import '../dominio/estado_herencia.dart';

/// Legados donde el usuario es la persona de confianza.
class PantallaHerenciasACuidado extends ConsumerWidget {
  const PantallaHerenciasACuidado({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cuidado = ref.watch(proveedorHerenciasACuidado);
    return PantallaCapsoul(
      usarAreaSegura: false,
      cuerpo: Column(
        children: [
          const CabeceraDetalleCapsoul(
            titulo: 'Legados a mi cuidado',
            subtitulo: 'Herencia donde eres persona de confianza',
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(proveedorHerenciasACuidado);
                await ref.read(proveedorHerenciasACuidado.future);
              },
              child: cuidado.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, _) => ListView(
                  padding: const EdgeInsets.all(24),
                  children: const [
                    Text(
                      'No pudimos cargar los legados a tu cuidado.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
                data: (lista) {
                  if (lista.isEmpty) {
                    return ListView(
                      padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
                      children: const [
                        Icon(
                          Icons.shield_outlined,
                          size: 56,
                          color: ColoresApp.atenuado,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Todavía no custodias ningún legado',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Cuando alguien te elija como persona de confianza, '
                          'la herencia aparecerá aquí.',
                          textAlign: TextAlign.center,
                        ),
                      ],
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                    itemCount: lista.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, i) {
                      final h = lista[i];
                      return _TarjetaACuidado(
                        herencia: h,
                        alTocar: () => context.push(
                          h.accesoActivo
                              ? RutasApp.detalleHerenciaDe(h.id)
                              : RutasApp.desbloquearHerenciaDe(h.id),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TarjetaACuidado extends StatelessWidget {
  const _TarjetaACuidado({required this.herencia, required this.alTocar});

  final HerenciaACuidado herencia;
  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) {
    final abierta = herencia.estado == EstadoHerencia.liberada;
    final fecha = herencia.fechaActivacion;
    return TarjetaCapsoul(
      alTocar: alTocar,
      icono: abierta ? Icons.lock_open_outlined : Icons.lock_outline,
      titulo: herencia.titulo,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${herencia.propietarioNombre} te eligió como persona de confianza.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: ColoresApp.atenuado,
                ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _Etiqueta(
                texto: abierta ? 'Abierta' : 'Sellada',
                icono: abierta ? Icons.lock_open_outlined : Icons.lock_outline,
              ),
              if (herencia.accesoActivo)
                const _Etiqueta(
                  texto: 'Desbloqueada',
                  icono: Icons.key_outlined,
                )
              else if (abierta)
                const _Etiqueta(
                  texto: 'Pide tu código',
                  icono: Icons.mark_email_unread_outlined,
                ),
              if (herencia.nCapsulas > 0)
                _Etiqueta(
                  texto: '${herencia.nCapsulas} cápsula'
                      '${herencia.nCapsulas == 1 ? '' : 's'}',
                  icono: Icons.inventory_2_outlined,
                ),
            ],
          ),
          if (!abierta && fecha != null) ...[
            const SizedBox(height: 8),
            Text(
              'Se abre el ${formatearFechaCorta(fecha)}. '
              'Ese día recibirás el código por correo.',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: ColoresApp.atenuado,
                  ),
            ),
          ],
          if (abierta && !herencia.accesoActivo) ...[
            const SizedBox(height: 8),
            Text(
              'La herencia ya está abierta. Ingresa el código que enviamos '
              'a tu correo para ver el contenido y ayudar.',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: ColoresApp.atenuado,
                  ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Etiqueta extends StatelessWidget {
  const _Etiqueta({required this.texto, required this.icono});

  final String texto;
  final IconData icono;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: ColoresApp.fondoInicio,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: ColoresApp.bordeTarjeta),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icono, size: 13, color: ColoresApp.primario),
          const SizedBox(width: 4),
          Text(
            texto,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: ColoresApp.primario,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}
