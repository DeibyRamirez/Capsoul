import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../nucleo/componentes/frasco_luminoso.dart';
import '../../../../nucleo/enrutador/rutas_app.dart';
import '../../../../nucleo/tema/colores_app.dart';
import '../../../../nucleo/tema/tema_app.dart';
import '../../dominio/apertura_capsula.dart';
import '../../dominio/capsula.dart';
import '../../dominio/capsula_recibida.dart';
import '../../dominio/estado_capsula.dart';
import '../../dominio/estado_visible_capsula.dart';

class TarjetaCapsulaLista extends StatelessWidget {
  const TarjetaCapsulaLista.propia({
    super.key,
    required this.capsula,
    required this.ahora,
  }) : recibida = null;

  const TarjetaCapsulaLista.recibida({
    super.key,
    required this.recibida,
    required this.ahora,
  }) : capsula = null;

  final Capsula? capsula;
  final CapsulaRecibida? recibida;
  final DateTime ahora;

  @override
  Widget build(BuildContext context) {
    if (recibida != null) {
      final r = recibida!;
      return _TarjetaContenido(
        id: r.id,
        titulo: r.tituloVisible,
        descripcion: 'De ${r.autorNombre}',
        presentacion: presentarEstadoCapsula(
          estado: r.estado,
          abierta: r.estaAbierta,
          fechaApertura: r.fechaApertura,
          ahora: ahora,
        ),
        puedeEditar: false,
      );
    }

    final c = capsula!;
    final descripcion = _descripcionPropia(c);
    return _TarjetaContenido(
      id: c.id,
      titulo: c.titulo,
      descripcion: descripcion,
      presentacion: presentarEstadoCapsula(
        estado: c.estado,
        abierta: c.abiertaEn != null,
        fechaApertura: c.fechaApertura,
        ahora: ahora,
      ),
      puedeEditar: c.estado == EstadoCapsula.borrador ||
          c.estado == EstadoCapsula.programada,
    );
  }

  static String? _descripcionPropia(Capsula c) {
    final mensaje = c.mensaje?.trim();
    if (mensaje != null && mensaje.isNotEmpty) return mensaje;
    final fecha = c.fechaApertura;
    if (fecha != null) {
      return describirHorizonte(c.creadoEn, fecha);
    }
    return null;
  }
}

class _TarjetaContenido extends StatelessWidget {
  const _TarjetaContenido({
    required this.id,
    required this.titulo,
    required this.descripcion,
    required this.presentacion,
    required this.puedeEditar,
  });

  final String id;
  final String titulo;
  final String? descripcion;
  final PresentacionEstadoCapsula presentacion;
  final bool puedeEditar;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final abierta = !presentacion.conCandado;
    final detalle = presentacion.detalle;
    final aviso = presentacion.aviso;

    return Material(
      color: ColoresApp.tarjeta,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(TemaApp.radioGrande),
        side: const BorderSide(color: ColoresApp.bordeTarjeta),
      ),
      child: InkWell(
        onTap: () => context.push(RutasApp.detalleCapsulaDe(id)),
        borderRadius: BorderRadius.circular(TemaApp.radioGrande),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FrascoLuminoso(
                tamano: 60,
                brillo: presentacion.brilla ? 0.95 : 0.5,
                conCandado: presentacion.conCandado,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            titulo,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: tema.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: ColoresApp.textoPrincipal,
                            ),
                          ),
                        ),
                        PopupMenuButton<String>(
                          icon: const Icon(
                            Icons.more_horiz,
                            color: ColoresApp.atenuado,
                          ),
                          onSelected: (valor) {
                            switch (valor) {
                              case 'detalle':
                                context.push(RutasApp.detalleCapsulaDe(id));
                              case 'editar':
                                context.push(RutasApp.editarCapsulaDe(id));
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'detalle',
                              child: Text('Ver detalle'),
                            ),
                            if (puedeEditar)
                              const PopupMenuItem(
                                value: 'editar',
                                child: Text('Editar'),
                              ),
                          ],
                        ),
                      ],
                    ),
                    if (descripcion != null && descripcion!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        descripcion!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: tema.textTheme.bodySmall?.copyWith(
                          color: ColoresApp.textoSecundario,
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    Text(
                      'Estado',
                      style: tema.textTheme.labelSmall?.copyWith(
                        color: ColoresApp.atenuado,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            presentacion.visible.etiqueta,
                            style: tema.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: ColoresApp.textoPrincipal,
                            ),
                          ),
                        ),
                        if (!abierta)
                          const Icon(
                            Icons.lock_outline,
                            size: 18,
                            color: ColoresApp.atenuado,
                          ),
                      ],
                    ),
                    if (detalle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        detalle,
                        style: tema.textTheme.bodySmall?.copyWith(
                          color: ColoresApp.textoSecundario,
                        ),
                      ),
                    ],
                    if (aviso != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        aviso,
                        style: tema.textTheme.labelSmall?.copyWith(
                          color: ColoresApp.acento,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
