import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../nucleo/componentes/avatar_usuario.dart';
import '../../../../nucleo/tema/colores_app.dart';
import '../../../amistades/dominio/amigo.dart';

/// Tres burbujas superpuestas con avatares de amigos.
class FilaAvataresAmigos extends ConsumerWidget {
  const FilaAvataresAmigos({
    super.key,
    required this.amigos,
    this.vacio = false,
  });

  final List<Amigo> amigos;
  final bool vacio;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visibles = vacio ? const <Amigo>[] : amigos.take(3).toList();
    final cantidad = vacio ? 3 : visibles.length;
    const tamano = 36.0;
    const paso = 22.0;
    final ancho = tamano + (cantidad - 1) * paso;

    return SizedBox(
      width: ancho,
      height: tamano,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (var i = 0; i < cantidad; i++)
            Positioned(
              left: i * paso,
              child: vacio
                  ? const _BurbujaVacia()
                  : Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: ColoresApp.tarjeta, width: 2),
                      ),
                      child: AvatarUsuario(
                        usuarioId: visibles[i].usuarioId,
                        nombreVisible: visibles[i].nombreVisible,
                        fotoPublicId: visibles[i].fotoPublicId,
                        radius: 16,
                      ),
                    ),
            ),
        ],
      ),
    );
  }
}

class _BurbujaVacia extends StatelessWidget {
  const _BurbujaVacia();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: ColoresApp.atenuado.withValues(alpha: 0.25),
        border: Border.all(color: ColoresApp.tarjeta, width: 2),
      ),
      child: Icon(Icons.person_outline, size: 18, color: ColoresApp.atenuado),
    );
  }
}
