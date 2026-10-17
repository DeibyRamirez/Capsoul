import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../nucleo/componentes/avisos_emergentes.dart';
import '../../../../nucleo/enrutador/rutas_app.dart';
import '../../../../nucleo/errores/fallo_app.dart';
import '../../../../nucleo/tema/colores_app.dart';
import '../../../elementos/aplicacion/proveedores_elementos.dart';
import '../../../elementos/dominio/elemento_borrador.dart';
import '../../../elementos/dominio/tipo_elemento.dart';
import '../../../elementos/presentacion/componentes/hoja_origen_medio.dart';
import '../../../musica/dominio/referencia_musica.dart';
import '../../aplicacion/proveedores_recuerdos.dart';
import '../../dominio/recuerdo.dart';

/// Ruta de la pantalla de captura de cada tipo.
String rutaCaptura(TipoElemento tipo) => switch (tipo) {
      TipoElemento.foto => RutasApp.crearFoto,
      TipoElemento.video => RutasApp.crearVideo,
      TipoElemento.audio => RutasApp.crearAudio,
      TipoElemento.texto => RutasApp.crearEscribir,
      TipoElemento.musica => RutasApp.crearMusica,
    };

IconData iconoDeTipo(TipoElemento tipo) => switch (tipo) {
      TipoElemento.foto => Icons.photo_camera_outlined,
      TipoElemento.video => Icons.videocam_outlined,
      TipoElemento.audio => Icons.mic_none_outlined,
      TipoElemento.texto => Icons.edit_outlined,
      TipoElemento.musica => Icons.music_note_outlined,
    };

/// Contexto del árbol principal con GoRouter (no un modal u hoja inferior).
BuildContext? contextoNavegacionPrincipal(BuildContext context) {
  final router = GoRouter.maybeOf(context);
  if (router == null) return context.mounted ? context : null;
  final host = router.routerDelegate.navigatorKey.currentContext;
  if (host != null && host.mounted) return host;
  return context.mounted ? context : null;
}

/// Captura un elemento de [tipo] y abre "Guardar recuerdo". Devuelve el
/// recuerdo guardado o `null` si el usuario cancela.
///
/// [context] debe ser del shell (p. ej. tras cerrar [HojaOpcionesCrear]), no del
/// modal.
Future<Recuerdo?> capturarRecuerdo(
  BuildContext context,
  TipoElemento tipo,
) async {
  final nav = contextoNavegacionPrincipal(context);
  if (nav == null) {
    debugPrint(
      'Capsoul: capturarRecuerdo sin contexto de navegación válido.',
    );
    return null;
  }
  final contenedor = ProviderScope.containerOf(nav, listen: false);
  final ElementoBorrador? borrador;
  if (tipo == TipoElemento.musica) {
    final ref = await nav.push<ReferenciaMusica>(RutasApp.crearMusica);
    if (ref == null || !nav.mounted) return null;
    borrador = ElementoBorrador(
      idLocal: ElementoBorrador.nuevoIdLocal(),
      tipo: TipoElemento.musica,
      referenciaMusica: ref,
    );
  } else if (tipo == TipoElemento.foto ||
      tipo == TipoElemento.video ||
      tipo == TipoElemento.audio) {
    final origen = await mostrarHojaOrigenMedio(nav, tipo);
    if (origen == null || !nav.mounted) return null;
    if (origen == OrigenMedio.dispositivo) {
      try {
        borrador = await contenedor.read(proveedorImportadorMedios).importar(tipo);
      } on FalloApp catch (fallo) {
        if (nav.mounted) mostrarAvisoError(nav, fallo);
        return null;
      }
    } else {
      borrador = await nav.push<ElementoBorrador>(rutaCaptura(tipo));
    }
  } else {
    borrador = await nav.push<ElementoBorrador>(rutaCaptura(tipo));
  }
  if (borrador == null || !nav.mounted) return null;
  contenedor.read(proveedorBorradorRecuerdoPendiente.notifier).establecer(borrador);
  return nav.push<Recuerdo>(RutasApp.guardarRecuerdo, extra: borrador);
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
