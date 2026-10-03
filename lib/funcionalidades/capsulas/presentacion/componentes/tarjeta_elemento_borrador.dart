import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../nucleo/componentes/onda_audio.dart';
import '../../../../nucleo/tema/colores_app.dart';
import '../../../../nucleo/tema/tema_app.dart';
import '../../../elementos/dominio/elemento_borrador.dart';
import '../../../elementos/dominio/tipo_elemento.dart';
import '../../../elementos/dominio/validador_medios.dart';

/// Fila de un elemento agregado a la cápsula, con vista previa y "Quitar".
class TarjetaElementoBorrador extends StatelessWidget {
  const TarjetaElementoBorrador({
    super.key,
    required this.elemento,
    required this.alQuitar,
  });

  final ElementoBorrador elemento;
  final VoidCallback? alQuitar;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      color: ColoresApp.sobrePrimario,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            _VistaPrevia(elemento: elemento),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    elemento.tipo.etiqueta,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: ColoresApp.sobreSuperficie,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _detalle(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: ColoresApp.atenuado),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Quitar',
              icon: const Icon(Icons.close),
              color: ColoresApp.atenuado,
              onPressed: alQuitar,
            ),
          ],
        ),
      ),
    );
  }

  String _detalle() {
    final duracion = elemento.duracion;
    return switch (elemento.tipo) {
      TipoElemento.texto => elemento.texto ?? '',
      TipoElemento.foto => formatearBytes(elemento.bytes),
      TipoElemento.video || TipoElemento.audio =>
        '${formatearDuracion(duracion ?? Duration.zero)} · '
            '${formatearBytes(elemento.bytes)}',
    };
  }
}

class _VistaPrevia extends StatelessWidget {
  const _VistaPrevia({required this.elemento});

  final ElementoBorrador elemento;

  static const double _lado = 56;

  @override
  Widget build(BuildContext context) {
    final ruta = elemento.rutaArchivo;
    final Widget contenido = switch (elemento.tipo) {
      TipoElemento.foto when ruta != null => Image.file(
          File(ruta),
          fit: BoxFit.cover,
          cacheWidth: 168,
          errorBuilder: (_, _, _) => const _Icono(Icons.photo_outlined),
        ),
      TipoElemento.foto => const _Icono(Icons.photo_outlined),
      TipoElemento.video => const _Icono(Icons.play_circle_outline),
      TipoElemento.audio => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: OndaAudio(
            color: ColoresApp.sobrePrimario,
            muestras: elemento.muestrasOnda,
            barras: 10,
            altura: 28,
            semilla: elemento.idLocal.hashCode,
          ),
        ),
      TipoElemento.texto => const _Icono(Icons.edit_note),
    };
    return ClipRRect(
      borderRadius: BorderRadius.circular(TemaApp.radioPequeno),
      child: Container(
        width: _lado,
        height: _lado,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [ColoresApp.acento, ColoresApp.primario],
          ),
        ),
        alignment: Alignment.center,
        child: contenido,
      ),
    );
  }
}

class _Icono extends StatelessWidget {
  const _Icono(this.icono);

  final IconData icono;

  @override
  Widget build(BuildContext context) =>
      Icon(icono, color: ColoresApp.sobrePrimario, size: 28);
}
