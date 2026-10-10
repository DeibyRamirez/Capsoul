import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../../../nucleo/componentes/avisos_emergentes.dart';
import '../../../../nucleo/tema/colores_app.dart';
import '../../dominio/referencia_musica.dart';
import '../abrir_plataformas_musica.dart';

/// Accesos externos para escuchar la pista completa (no preview in-app).
class EnlacesEscucharCompleto extends StatelessWidget {
  const EnlacesEscucharCompleto({
    super.key,
    required this.referencia,
  });

  final ReferenciaMusica referencia;

  static const _tamanoBoton = 52.0;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Escuchar canción completa',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: esquema.onSurface,
              ),
        ),
        const SizedBox(height: 12),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 16,
          runSpacing: 8,
          children: [
            _BotonPlataforma(
              etiqueta: 'Spotify',
              icono: FontAwesomeIcons.spotify,
              color: const Color(0xFF1DB954),
              alPresionar: () => _abrir(
                context,
                'Spotify',
                () => abrirEnSpotifyDesdeReferencia(referencia),
              ),
            ),
            _BotonPlataforma(
              etiqueta: 'Deezer',
              icono: FontAwesomeIcons.deezer,
              color: const Color(0xFFA238FF),
              alPresionar: () => _abrir(
                context,
                'Deezer',
                () => abrirEnDeezer(referencia),
              ),
            ),
            _BotonPlataforma(
              etiqueta: 'YouTube',
              icono: FontAwesomeIcons.youtube,
              color: const Color(0xFFFF0000),
              alPresionar: () => _abrir(
                context,
                'YouTube',
                () => abrirEnYoutube(
                  titulo: referencia.titulo,
                  artista: referencia.artista,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _abrir(
    BuildContext context,
    String plataforma,
    Future<bool> Function() abrir,
  ) async {
    final ok = await abrir();
    if (!ok && context.mounted) {
      mostrarAvisoError(context, 'No se pudo abrir $plataforma.');
    }
  }
}

class _BotonPlataforma extends StatelessWidget {
  const _BotonPlataforma({
    required this.etiqueta,
    required this.icono,
    required this.color,
    required this.alPresionar,
  });

  final String etiqueta;
  final IconData icono;
  final Color color;
  final VoidCallback alPresionar;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Escuchar en $etiqueta',
      child: Tooltip(
        message: etiqueta,
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
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: ColoresApp.atenuado,
                        fontSize: 10,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
