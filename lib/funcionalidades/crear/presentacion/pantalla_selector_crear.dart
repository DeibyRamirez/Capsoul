import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../nucleo/componentes/app_bar_capsoul.dart';
import '../../../nucleo/componentes/pantalla_capsoul.dart';
import '../../../nucleo/enrutador/rutas_app.dart';
import '../../elementos/dominio/tipo_elemento.dart';
import '../../recuerdos/presentacion/componentes/hoja_nuevo_recuerdo.dart';
import 'componentes/opciones_crear_comunes.dart';

/// Selector que abre el botón `+`: una cápsula nueva o un recuerdo nuevo
/// (Video, Audio, Escribir, Foto) que se guarda en el banco de recuerdos.
class PantallaSelectorCrear extends StatelessWidget {
  const PantallaSelectorCrear({super.key});

  /// Captura y guarda el recuerdo; si se guardó, reemplaza el selector por
  /// el banco de recuerdos.
  static Future<void> _nuevoRecuerdo(
    BuildContext context,
    TipoElemento tipo,
  ) async {
    final recuerdo = await capturarRecuerdo(context, tipo);
    if (recuerdo == null || !context.mounted) return;
    context.pushReplacement(RutasApp.recuerdos);
  }

  @override
  Widget build(BuildContext context) {
    return PantallaCapsoul(
      appBar: AppBarCapsoul(
        titulo: const Text('Crear'),
        automaticallyImplyLeading: false,
        acciones: [
          IconButton(
            icon: const Icon(Icons.close),
            tooltip: 'Cerrar',
            onPressed: () => context.pop(),
          ),
        ],
      ),
      cuerpo: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          OpcionCrear(
            icono: Icons.hourglass_bottom,
            titulo: 'Cápsula del tiempo',
            subtitulo: 'Guarda hoy, abre en el futuro',
            destacada: true,
            alTocar: () => context.pushReplacement(RutasApp.crearCapsula),
          ),
          OpcionCrear(
            icono: Icons.auto_awesome_mosaic_outlined,
            titulo: 'Momento',
            subtitulo: 'Junta varios recuerdos bajo un nombre',
            alTocar: () => context.pushReplacement(RutasApp.nuevoMomento),
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
            icono: Icons.music_note,
            titulo: 'Musica',
            subtitulo: 'Escucha tus pistas guardadas',
            alTocar: () => _nuevoRecuerdo(context, TipoElemento.musica),
          ),
        ],
      ),
    );
  }
}
