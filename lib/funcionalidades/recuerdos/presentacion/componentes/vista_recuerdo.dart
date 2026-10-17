import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../../../../nucleo/tema/colores_app.dart';
import '../../../../nucleo/tema/tema_app.dart';
import '../../../elementos/dominio/nota_serializada.dart';
import '../../../elementos/dominio/tipo_elemento.dart';
import '../../dominio/aspecto_medio.dart';
import '../../dominio/recuerdo.dart';
import 'miniatura_recuerdo_firmada.dart';
import '../../../musica/presentacion/componentes/overlay_musica_foto.dart';
import '../../../musica/presentacion/componentes/vista_recuerdo_musica.dart';
import 'reproductores_medio.dart';

/// Contenido completo de un recuerdo: foto, reproductor de video o de audio,
/// o el texto de la nota.
class VistaRecuerdo extends StatelessWidget {
  const VistaRecuerdo({super.key, required this.recuerdo});

  final Recuerdo recuerdo;

  @override
  Widget build(BuildContext context) {
    return switch (recuerdo.tipo) {
      TipoElemento.texto => _NotaRecuerdo(recuerdo: recuerdo),
      TipoElemento.foto => ClipRRect(
          borderRadius: BorderRadius.circular(TemaApp.radioGrande),
          child: _contenidoFoto(recuerdo),
        ),
      TipoElemento.musica => _contenidoMusica(context, recuerdo),
      TipoElemento.video => ClipRRect(
          borderRadius: BorderRadius.circular(TemaApp.radioGrande),
          child: ReproductorVideoRecuerdo(recuerdo: recuerdo),
        ),
      TipoElemento.audio => ReproductorAudioRecuerdo(recuerdo: recuerdo),
    };
  }

  Widget _contenidoFoto(Recuerdo recuerdo) {
    final musica = recuerdo.musica;
    if (recuerdo.tieneMusica && musica != null) {
      return AspectRatio(
        aspectRatio: aspectoMedio(
          tipo: TipoElemento.foto,
          ancho: recuerdo.ancho,
          alto: recuerdo.alto,
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            FotoCompleta(recuerdo: recuerdo),
            OverlayMusicaFoto(referencia: musica),
          ],
        ),
      );
    }
    return FotoCompleta(recuerdo: recuerdo);
  }

  Widget _contenidoMusica(BuildContext context, Recuerdo recuerdo) {
    final musica = recuerdo.musica;
    if (musica == null) {
      return Card(
        color: ColoresApp.sobrePrimario,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            'No se pudo cargar la canción.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: ColoresApp.atenuado,
                ),
          ),
        ),
      );
    }
    return VistaRecuerdoMusica(
      referencia: musica,
      recuerdo: recuerdo,
    );
  }
}

/// Miniatura de respaldo con proporción 4:3 (mientras carga o sin medio).
class MarcoMiniatura extends StatelessWidget {
  const MarcoMiniatura({super.key, required this.recuerdo});

  final Recuerdo recuerdo;

  @override
  Widget build(BuildContext context) => AspectRatio(
        aspectRatio: aspectoMedio(
          tipo: recuerdo.tipo,
          ancho: recuerdo.ancho,
          alto: recuerdo.alto,
        ),
        child: MiniaturaRecuerdoFirmada(recuerdo: recuerdo, tamanoIcono: 48),
      );
}

class _NotaRecuerdo extends StatelessWidget {
  const _NotaRecuerdo({required this.recuerdo});

  final Recuerdo recuerdo;

  @override
  Widget build(BuildContext context) {
    final nota = NotaSerializada.parse(recuerdo.contenidoTexto);
    final fam = nota.estilo.esPlayfair()
        ? TemaApp.fuenteTitulos
        : TemaApp.fuenteUi;
    return Card(
      color: nota.estilo.colorFondo(),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: MarkdownBody(
          data: nota.cuerpo.isEmpty ? ' ' : nota.cuerpo,
          selectable: true,
          styleSheet: MarkdownStyleSheet(
            p: TextStyle(
              fontSize: 16,
              height: 1.5,
              fontFamily: fam,
              color: ColoresApp.textoPrincipal,
            ),
          ),
        ),
      ),
    );
  }
}
