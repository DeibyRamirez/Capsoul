import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../nucleo/tema/colores_app.dart';
import '../../dominio/tipo_elemento.dart';
import '../importar_medio_desde_dispositivo.dart';

/// Origen al crear un recuerdo con archivo multimedia.
enum OrigenMedio { capturar, dispositivo }

/// Hoja inferior: capturar en el momento o elegir del dispositivo.
Future<OrigenMedio?> mostrarHojaOrigenMedio(
  BuildContext context,
  TipoElemento tipo,
) {
  final opciones = switch (tipo) {
    TipoElemento.foto => ('Tomar foto', 'Elegir de la galería'),
    TipoElemento.video => ('Grabar video', 'Elegir video'),
    TipoElemento.audio => ('Grabar nota de voz', 'Elegir archivo de audio'),
    _ => null,
  };
  if (opciones == null) return Future.value(null);
  final (capturar, dispositivo) = opciones;

  return showModalBottomSheet<OrigenMedio>(
    context: context,
    showDragHandle: true,
    builder: (contexto) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              tipo.etiqueta,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: ColoresApp.primario,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.photo_camera_outlined, color: ColoresApp.acento),
            title: Text(capturar),
            onTap: () => Navigator.of(contexto).pop(OrigenMedio.capturar),
          ),
          ListTile(
            leading: const Icon(Icons.folder_outlined, color: ColoresApp.acento),
            title: Text(dispositivo),
            onTap: () => Navigator.of(contexto).pop(OrigenMedio.dispositivo),
          ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
}

IconData iconoImportarDesdeDispositivo(TipoElemento tipo) => switch (tipo) {
      TipoElemento.foto => Icons.photo_library_outlined,
      TipoElemento.video => Icons.video_library_outlined,
      TipoElemento.audio => Icons.audio_file_outlined,
      _ => Icons.folder_outlined,
    };

String etiquetaImportarDesdeDispositivo(TipoElemento tipo) => switch (tipo) {
      TipoElemento.foto => 'Galería',
      TipoElemento.video => 'Elegir video',
      TipoElemento.audio => 'Elegir audio',
      _ => 'Archivos',
    };

/// Botón de la barra de captura para importar desde el dispositivo.
class AccionImportarMedio extends ConsumerWidget {
  const AccionImportarMedio({super.key, required this.tipo});

  final TipoElemento tipo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      icon: Icon(iconoImportarDesdeDispositivo(tipo)),
      tooltip: etiquetaImportarDesdeDispositivo(tipo),
      onPressed: () => importarMedioYPop(context, ref, tipo),
    );
  }
}
