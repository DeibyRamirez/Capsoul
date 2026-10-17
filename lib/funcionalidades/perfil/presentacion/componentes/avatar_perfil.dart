import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../nucleo/componentes/imagen_avatar_red.dart';
import '../../../../nucleo/tema/colores_app.dart';
import '../../aplicacion/proveedor_avatar_perfil.dart';

/// Avatar del perfil propio: foto firmada o inicial.
class AvatarPerfil extends ConsumerWidget {
  const AvatarPerfil({
    super.key,
    required this.inicial,
    this.fotoPublicId,
    this.radius = 42,
    this.alTocar,
  });

  final String inicial;
  final String? fotoPublicId;
  final double radius;
  final VoidCallback? alTocar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estilos = Theme.of(context).textTheme;
    final id = fotoPublicId?.trim();
    final tieneFoto = id != null && id.isNotEmpty;
    final urlsAsync = tieneFoto
        ? ref.watch(proveedorUrlsAvatarPerfil(id))
        : const AsyncData<UrlsAvatar?>(null);

    final fallback = Text(
      inicial,
      style: estilos.headlineMedium?.copyWith(
        color: ColoresApp.sobrePrimario,
        fontWeight: FontWeight.w700,
      ),
    );

    return Material(
      color: ColoresApp.primario,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: alTocar,
        child: CircleAvatar(
          key: ValueKey(id ?? 'sin-foto'),
          radius: radius,
          backgroundColor: ColoresApp.primario,
          foregroundColor: ColoresApp.sobrePrimario,
          child: urlsAsync.when(
            loading: () => SizedBox(
              width: radius,
              height: radius,
              child: const Padding(
                padding: EdgeInsets.all(10),
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: ColoresApp.sobrePrimario,
                ),
              ),
            ),
            error: (_, _) => fallback,
            data: (urls) {
              if (urls == null) return fallback;
              return ImagenAvatarRed(
                urlPrincipal: urls.principal,
                urlAlternativa: urls.alternativa,
                tamano: radius * 2,
                fallback: fallback,
              );
            },
          ),
        ),
      ),
    );
  }
}
