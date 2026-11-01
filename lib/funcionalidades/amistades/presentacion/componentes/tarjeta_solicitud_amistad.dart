import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../nucleo/componentes/avatar_usuario.dart';
import '../../../../nucleo/componentes/avisos_emergentes.dart';
import '../../../../nucleo/tema/colores_app.dart';
import '../../../../nucleo/tema/tema_app.dart';
import '../../aplicacion/proveedores_amistades.dart';
import '../../dominio/amigo.dart';

/// Solicitud pendiente con los botones Aceptar y Rechazar.
class TarjetaSolicitudAmistad extends ConsumerStatefulWidget {
  const TarjetaSolicitudAmistad({super.key, required this.solicitud});

  final SolicitudAmistad solicitud;

  @override
  ConsumerState<TarjetaSolicitudAmistad> createState() =>
      _EstadoTarjetaSolicitudAmistad();
}

class _EstadoTarjetaSolicitudAmistad
    extends ConsumerState<TarjetaSolicitudAmistad> {
  var _ocupada = false;

  Future<void> _responder(bool aceptar) async {
    if (_ocupada) return;
    setState(() => _ocupada = true);
    final solicitud = widget.solicitud;
    try {
      final repositorio = ref.read(proveedorRepositorioAmistades);
      if (aceptar) {
        await repositorio.aceptarSolicitud(solicitud.id);
      } else {
        await repositorio.rechazarSolicitud(solicitud.id);
      }
      if (!mounted) return;
      refrescarAmistades(ref.invalidate);
      mostrarAvisoInformativo(
        context,
        aceptar
            ? 'Aceptaste a ${solicitud.solicitanteNombre}.'
            : 'Rechazaste la solicitud de ${solicitud.solicitanteNombre}.',
      );
    } catch (error) {
      if (mounted) mostrarAvisoError(context, error);
    } finally {
      if (mounted) setState(() => _ocupada = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final solicitud = widget.solicitud;
    final estilos = Theme.of(context).textTheme;
    return Card(
      key: Key('tarjeta-solicitud-${solicitud.id}'),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                AvatarUsuario(
                  usuarioId: solicitud.solicitanteId,
                  nombreVisible: solicitud.solicitanteNombre,
                  fotoPublicId: solicitud.solicitanteFotoPublicId,
                  radius: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        solicitud.solicitanteNombre,
                        style: estilos.titleMedium?.copyWith(
                          color: ColoresApp.primario,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Quiere ser tu amigo',
                        style: estilos.bodyMedium?.copyWith(
                          color: ColoresApp.textoSecundario,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    key: Key('boton-rechazar-solicitud-${solicitud.id}'),
                    onPressed: _ocupada ? null : () => _responder(false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: ColoresApp.primario,
                      minimumSize: const Size.fromHeight(TemaApp.altoBoton),
                      shape: const StadiumBorder(),
                    ),
                    child: const Text('Rechazar'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton(
                    key: Key('boton-aceptar-solicitud-${solicitud.id}'),
                    onPressed: _ocupada ? null : () => _responder(true),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(TemaApp.altoBoton),
                      shape: const StadiumBorder(),
                    ),
                    child: const Text('Aceptar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
