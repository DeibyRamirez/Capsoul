import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';



import '../../funcionalidades/perfil/aplicacion/proveedor_avatar_perfil.dart';

import '../tema/colores_app.dart';

import 'imagen_avatar_red.dart';



/// Avatar circular con URL firmada o inicial del nombre.

class AvatarUsuario extends ConsumerWidget {

  const AvatarUsuario({

    super.key,

    required this.usuarioId,

    required this.nombreVisible,

    this.fotoPublicId,

    this.radius = 18,

  });



  final String usuarioId;

  final String nombreVisible;

  final String? fotoPublicId;

  final double radius;



  static String _inicial(String nombre) {

    final limpio = nombre.trim();

    if (limpio.isEmpty) return '?';

    return limpio[0].toUpperCase();

  }



  Widget _textoInicial(String inicial) {

    return Text(

      inicial,

      style: TextStyle(

        fontWeight: FontWeight.w700,

        color: ColoresApp.primario,

        fontSize: radius * 0.9,

      ),

    );

  }



  @override

  Widget build(BuildContext context, WidgetRef ref) {

    final inicial = _inicial(nombreVisible);

    final id = fotoPublicId?.trim();

    final clave = (usuarioId: usuarioId, fotoPublicId: id);

    final urlsAsync = id != null && id.isNotEmpty

        ? ref.watch(proveedorUrlsAvatarUsuario(clave))

        : const AsyncData<UrlsAvatar?>(null);



    final fallback = _textoInicial(inicial);



    return CircleAvatar(

      radius: radius,

      backgroundColor: ColoresApp.acento.withValues(alpha: 0.2),

      child: urlsAsync.when(

        loading: () => SizedBox(

          width: radius,

          height: radius,

          child: const Padding(

            padding: EdgeInsets.all(6),

            child: CircularProgressIndicator(strokeWidth: 2),

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

    );

  }

}


