import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../nucleo/componentes/onda_audio.dart';
import '../../../../nucleo/tema/colores_app.dart';
import '../../../../nucleo/tema/tema_app.dart';
import '../../../elementos/dominio/elemento_borrador.dart';
import '../../../elementos/dominio/nota_serializada.dart';
import '../../../elementos/dominio/tipo_elemento.dart';
import '../../../elementos/dominio/validador_medios.dart';
import 'vista_nota_compacta.dart';
import '../../../musica/dominio/referencia_musica.dart';
import '../../../musica/presentacion/componentes/reproductor_preview_musica.dart';

/// Vista previa grande de lo recién capturado (antes de guardarlo).
class VistaPreviaBorrador extends StatelessWidget {
  const VistaPreviaBorrador({
    super.key,
    required this.elemento,
    this.alQuitarMusica,
  });

  final ElementoBorrador elemento;
  final VoidCallback? alQuitarMusica;

  @override
  Widget build(BuildContext context) {
    final ruta = elemento.rutaArchivo;
    final duracion = elemento.duracion;
    final Widget contenido = switch (elemento.tipo) {
      TipoElemento.foto when ruta != null => _ImagenFotoRecuerdo(ruta: ruta),
      TipoElemento.foto => const _Icono(Icons.photo_outlined),
      TipoElemento.video => const _Icono(Icons.play_circle_outline),
      TipoElemento.audio => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: OndaAudio(
            color: ColoresApp.sobrePrimario,
            muestras: elemento.muestrasOnda,
            barras: 32,
            altura: 64,
            semilla: elemento.idLocal.hashCode,
          ),
        ),
      TipoElemento.texto => const SizedBox.shrink(),
      TipoElemento.musica => _VistaMusicaBorrador(
          referencia: elemento.referenciaMusica,
        ),
    };
    final detalle = switch (elemento.tipo) {
      TipoElemento.texto =>
        '${NotaSerializada.longitudCuerpoVisible(elemento.texto)} caracteres',
      TipoElemento.foto => formatearBytes(elemento.bytes),
      TipoElemento.musica => elemento.referenciaMusica?.etiquetaCorta ?? 'Música',
      TipoElemento.video || TipoElemento.audio =>
        '${formatearDuracion(duracion ?? Duration.zero)} · '
            '${formatearBytes(elemento.bytes)}',
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(TemaApp.radioGrande),
          child: AspectRatio(
            aspectRatio: 4 / 3,
            child: elemento.tipo == TipoElemento.texto
                ? VistaNotaCompacta(
                    contenidoTexto: elemento.texto,
                    tamanoFuente: 14,
                    rellenar: false,
                  )
                : DecoratedBox(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [ColoresApp.acento, ColoresApp.primario],
                      ),
                    ),
                    child: Center(child: contenido),
                  ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${elemento.tipo.etiqueta} · $detalle',
          style: const TextStyle(color: ColoresApp.atenuado),
        ),
        if (elemento.tipo == TipoElemento.foto &&
            elemento.referenciaMusica != null) ...[
          const SizedBox(height: 12),
          ReproductorPreviewMusica(
            referencia: elemento.referenciaMusica!,
            alQuitar: alQuitarMusica,
          ),
        ],
      ],
    );
  }
}

class _VistaMusicaBorrador extends StatelessWidget {
  const _VistaMusicaBorrador({required this.referencia});

  final ReferenciaMusica? referencia;

  @override
  Widget build(BuildContext context) {
    final ref = referencia;
    if (ref == null) return const _Icono(Icons.music_note_outlined);
    final url = ref.portadaUrl;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (url != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(url, width: 120, height: 120, fit: BoxFit.cover),
          )
        else
          const _Icono(Icons.album_outlined),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: ReproductorPreviewMusica(referencia: ref),
        ),
      ],
    );
  }
}

/// Foto del borrador tal como está en disco (sin espejo de preview de cámara).
class _ImagenFotoRecuerdo extends StatelessWidget {
  const _ImagenFotoRecuerdo({required this.ruta});

  final String ruta;

  @override
  Widget build(BuildContext context) {
    return Image.file(
      File(ruta),
      fit: BoxFit.cover,
      cacheWidth: 900,
      errorBuilder: (_, _, _) => const _Icono(Icons.photo_outlined),
    );
  }
}

class _Icono extends StatelessWidget {
  const _Icono(this.icono);

  final IconData icono;

  @override
  Widget build(BuildContext context) =>
      Icon(icono, color: ColoresApp.sobrePrimario, size: 56);
}
