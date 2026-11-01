import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../../../nucleo/componentes/avisos_emergentes.dart';
import '../../../../nucleo/tema/colores_app.dart';
import '../../aplicacion/proveedores_musica.dart';
import '../../dominio/referencia_musica.dart';

/// Botones para escuchar la canción completa en otras apps.
class EnlacesEscucharCompleto extends ConsumerWidget {
  const EnlacesEscucharCompleto({super.key, required this.referencia});

  final ReferenciaMusica referencia;

  static const _tamanoBoton = 64.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final abridor = ref.read(proveedorAbridorEnlacesMusica);
    final esquema = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Escuchar canción completa',
          textAlign: TextAlign.center,
          style: Theme.of(context)
              .textTheme
              .titleSmall
              ?.copyWith(fontWeight: FontWeight.w600, color: esquema.onSurface),
        ),
        const SizedBox(height: 12),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 16,
          runSpacing: 8,
          children: [
            _BotonPlataforma(
              etiqueta: 'Deezer',
              semantica: 'Abrir en Deezer',
              icono: FontAwesomeIcons.deezer,
              color: ColoresApp.appleMusic,
              alPresionar: () => _abrir(
                context,
                ref,
                'Deezer',
                () => abridor.abrirEnDeezer(referencia),
              ),
            ),
            _BotonPlataforma(
              etiqueta: 'Spotify',
              semantica: 'Buscar en Spotify',
              icono: FontAwesomeIcons.spotify,
              color: ColoresApp.spotify,
              alPresionar: () => _abrir(
                context,
                ref,
                'Spotify',
                () => abridor.abrirEnSpotify(referencia),
              ),
            ),
            _BotonPlataforma(
              etiqueta: 'YouTube',
              semantica: 'Buscar en YouTube',
              icono: FontAwesomeIcons.youtube,
              color: ColoresApp.youtube,
              alPresionar: () => _abrir(
                context,
                ref,
                'YouTube',
                () => abridor.abrirEnYoutube(referencia),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _abrir(
    BuildContext context,
    WidgetRef ref,
    String plataforma,
    Future<bool> Function() abrir,
  ) async {
    await ref.read(proveedorCoordinadorPreviewMusica).pausarTodo();
    final ok = await abrir();
    if (!ok && context.mounted) {
      mostrarAvisoInformativo(context, 'No se pudo abrir $plataforma.');
    }
  }
}

class _BotonPlataforma extends StatelessWidget {
  const _BotonPlataforma({
    required this.etiqueta,
    required this.semantica,
    required this.icono,
    required this.color,
    required this.alPresionar,
  });

  final String etiqueta;
  final String semantica;
  final FaIconData icono;
  final Color color;
  final VoidCallback alPresionar;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semantica,
      excludeSemantics: true,
      child: Tooltip(
        message: semantica,
        child: InkWell(
          onTap: alPresionar,
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            width: EnlacesEscucharCompleto._tamanoBoton,
            height: EnlacesEscucharCompleto._tamanoBoton,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FaIcon(icono, color: color, size: 28),
                const SizedBox(height: 4),
                Text(
                  etiqueta,
                  style: Theme.of(context)
                      .textTheme
                      .labelSmall
                      ?.copyWith(color: ColoresApp.atenuado, fontSize: 10),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
