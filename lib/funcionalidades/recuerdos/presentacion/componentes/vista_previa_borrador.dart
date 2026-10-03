import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../nucleo/componentes/onda_audio.dart';
import '../../../../nucleo/tema/colores_app.dart';
import '../../../../nucleo/tema/tema_app.dart';
import '../../../elementos/dominio/elemento_borrador.dart';
import '../../../elementos/dominio/tipo_elemento.dart';
import '../../../elementos/dominio/validador_medios.dart';

/// Vista previa grande de lo recién capturado (antes de guardarlo).
class VistaPreviaBorrador extends StatelessWidget {
  const VistaPreviaBorrador({super.key, required this.elemento});

  final ElementoBorrador elemento;

  @override
  Widget build(BuildContext context) {
    final ruta = elemento.rutaArchivo;
    final duracion = elemento.duracion;
    final Widget contenido = switch (elemento.tipo) {
      TipoElemento.foto when ruta != null => Image.file(
          File(ruta),
          fit: BoxFit.cover,
          cacheWidth: 900,
          errorBuilder: (_, _, _) => const _Icono(Icons.photo_outlined),
        ),
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
      TipoElemento.texto => Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            elemento.texto ?? '',
            maxLines: 8,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: ColoresApp.sobrePrimario,
              fontStyle: FontStyle.italic,
              height: 1.4,
            ),
          ),
        ),
    };
    final detalle = switch (elemento.tipo) {
      TipoElemento.texto => '${contarCaracteres(elemento.texto ?? '')} caracteres',
      TipoElemento.foto => formatearBytes(elemento.bytes),
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
            child: DecoratedBox(
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
      ],
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
