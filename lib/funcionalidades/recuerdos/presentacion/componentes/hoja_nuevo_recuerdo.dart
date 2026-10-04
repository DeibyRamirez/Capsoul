import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../nucleo/enrutador/rutas_app.dart';
import '../../../../nucleo/tema/colores_app.dart';
import '../../../elementos/dominio/elemento_borrador.dart';
import '../../../elementos/dominio/tipo_elemento.dart';
import '../../dominio/recuerdo.dart';

/// Ruta de la pantalla de captura de cada tipo.
String rutaCaptura(TipoElemento tipo) => switch (tipo) {
      TipoElemento.foto => RutasApp.crearFoto,
      TipoElemento.video => RutasApp.crearVideo,
      TipoElemento.audio => RutasApp.crearAudio,
      TipoElemento.texto => RutasApp.crearEscribir,
    };

IconData iconoDeTipo(TipoElemento tipo) => switch (tipo) {
      TipoElemento.foto => Icons.photo_camera_outlined,
      TipoElemento.video => Icons.videocam_outlined,
      TipoElemento.audio => Icons.mic_none_outlined,
      TipoElemento.texto => Icons.edit_outlined,
    };

/// Captura un elemento de [tipo] y abre "Guardar recuerdo". Devuelve el
/// recuerdo guardado o `null` si el usuario cancela.
Future<Recuerdo?> capturarRecuerdo(
  BuildContext context,
  TipoElemento tipo,
) async {
  final borrador = await context.push<ElementoBorrador>(rutaCaptura(tipo));
  if (borrador == null || !context.mounted) return null;
  return context.push<Recuerdo>(RutasApp.guardarRecuerdo, extra: borrador);
}

/// Hoja inferior "Nuevo recuerdo": elige el tipo.
Future<TipoElemento?> elegirTipoRecuerdo(BuildContext context) {
  return showModalBottomSheet<TipoElemento>(
    context: context,
    showDragHandle: true,
    builder: (contexto) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text(
              'Nuevo recuerdo',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: ColoresApp.primario,
              ),
            ),
          ),
          for (final tipo in TipoElemento.values)
            ListTile(
              leading: Icon(iconoDeTipo(tipo), color: ColoresApp.acento),
              title: Text(tipo.etiqueta),
              onTap: () => Navigator.of(contexto).pop(tipo),
            ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
}
