import 'package:flutter/material.dart';

import 'package:go_router/go_router.dart';



import '../../../../nucleo/enrutador/rutas_app.dart';

import '../../../../nucleo/tema/colores_app.dart';

import '../../../../nucleo/tema/tema_app.dart';

import '../../../elementos/dominio/tipo_elemento.dart';

import '../../../recuerdos/presentacion/componentes/hoja_nuevo_recuerdo.dart';

import 'opciones_crear_comunes.dart';



/// Contexto del shell (árbol con GoRouter), no del modal de la hoja.

BuildContext? contextoHostTrasCerrarHoja(BuildContext contextoHoja) {

  final router = GoRouter.maybeOf(contextoHoja);

  if (router == null) return null;

  final host = router.routerDelegate.navigatorKey.currentContext;

  if (host != null && host.mounted) return host;

  return contextoHoja.mounted ? contextoHoja : null;

}



/// Opciones de crear para hoja inferior animada.

class HojaOpcionesCrear extends StatelessWidget {

  const HojaOpcionesCrear({super.key});



  static Future<void> mostrar(BuildContext context) {

    return showModalBottomSheet<void>(

      context: context,

      isScrollControlled: true,

      backgroundColor: Colors.transparent,

      builder: (contexto) => DraggableScrollableSheet(

        initialChildSize: 0.72,

        minChildSize: 0.4,

        maxChildSize: 0.92,

        builder: (_, controlador) => DecoratedBox(

          decoration: const BoxDecoration(

            color: ColoresApp.tarjeta,

            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),

          ),

          child: Column(

            children: [

              const SizedBox(height: 8),

              Container(

                width: 40,

                height: 4,

                decoration: BoxDecoration(

                  color: ColoresApp.atenuado.withValues(alpha: 0.4),

                  borderRadius: BorderRadius.circular(2),

                ),

              ),

              Expanded(

                child: ListView(

                  controller: controlador,

                  padding: const EdgeInsets.all(16),

                  children: const [

                    Text(

                      'Guardar algo hoy',

                      style: TextStyle(

                        fontSize: 20,

                        fontWeight: FontWeight.w700,

                        color: ColoresApp.primario,

                        fontFamily: TemaApp.fuenteTitulos,

                      ),

                    ),

                    SizedBox(height: 12),

                    HojaOpcionesCrear(),

                  ],

                ),

              ),

            ],

          ),

        ),

      ),

    );

  }



  @override

  Widget build(BuildContext context) {

    return Column(

      children: [

        OpcionCrear(

          icono: Icons.hourglass_bottom,

          titulo: 'Cápsula del tiempo',

          subtitulo: 'Guarda hoy, abre en el futuro',

          destacada: true,

          alTocar: () => _cerrarHojaYNavegar(

            context,

            (host) => host.push(RutasApp.crearCapsula),

          ),

        ),

        OpcionCrear(

          icono: Icons.auto_awesome_mosaic_outlined,

          titulo: 'Momento',

          subtitulo: 'Junta varios recuerdos bajo un nombre',

          alTocar: () => _cerrarHojaYNavegar(

            context,

            (host) => host.push(RutasApp.nuevoMomento),

          ),

        ),

        const TituloSeccionCrear('Nuevo recuerdo'),

        OpcionCrear(

          icono: Icons.videocam_outlined,

          titulo: 'Video',

          subtitulo: 'Graba un recuerdo en video (hasta 60 s)',

          alTocar: () => _nuevoRecuerdo(context, TipoElemento.video),

        ),

        OpcionCrear(

          icono: Icons.mic_none_outlined,

          titulo: 'Audio',

          subtitulo: 'Deja un mensaje de voz (hasta 5 min)',

          alTocar: () => _nuevoRecuerdo(context, TipoElemento.audio),

        ),

        OpcionCrear(

          icono: Icons.edit_outlined,

          titulo: 'Escribir',

          subtitulo: 'Escribe una nota o carta',

          alTocar: () => _nuevoRecuerdo(context, TipoElemento.texto),

        ),

        OpcionCrear(

          icono: Icons.photo_outlined,

          titulo: 'Foto',

          subtitulo: 'Guarda una imagen especial',

          alTocar: () => _nuevoRecuerdo(context, TipoElemento.foto),

        ),

        OpcionCrear(

          icono: Icons.music_note_outlined,

          titulo: 'Musica',

          subtitulo: 'Busca la pista de tu canción favorita',

          alTocar: () => _nuevoRecuerdo(context, TipoElemento.musica),

        ),

      ],

    );

  }



  static void _cerrarHojaYNavegar(

    BuildContext contextoHoja,

    void Function(BuildContext host) navegar,

  ) {

    final host = contextoHostTrasCerrarHoja(contextoHoja);

    Navigator.of(contextoHoja).pop();

    if (host == null || !host.mounted) return;

    navegar(host);

  }



  static Future<void> _nuevoRecuerdo(

    BuildContext contextoHoja,

    TipoElemento tipo,

  ) async {

    final host = contextoHostTrasCerrarHoja(contextoHoja);

    Navigator.of(contextoHoja).pop();

    if (host == null || !host.mounted) return;

    final recuerdo = await capturarRecuerdo(host, tipo);

    if (recuerdo == null || !host.mounted) return;

    host.push(RutasApp.recuerdos);

  }

}


