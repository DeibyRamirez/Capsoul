import 'package:flutter/material.dart';

import '../../../../nucleo/tema/colores_app.dart';
import '../../../../nucleo/tema/tema_app.dart';
import '../../../elementos/dominio/tipo_elemento.dart';

/// Botones "Foto | Video | Nota de voz | Nota" para agregar recuerdos.
class BotonesAgregarElemento extends StatelessWidget {
  const BotonesAgregarElemento({
    super.key,
    required this.alElegir,
    this.habilitado = true,
  });

  final ValueChanged<TipoElemento> alElegir;
  final bool habilitado;

  static const _iconos = {
    TipoElemento.foto: Icons.photo_camera_outlined,
    TipoElemento.video: Icons.videocam_outlined,
    TipoElemento.audio: Icons.mic_none_outlined,
    TipoElemento.texto: Icons.edit_outlined,
    TipoElemento.musica: Icons.music_note_outlined,
  };

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final tipo in TipoElemento.values) ...[
          Expanded(
            child: _BotonAgregar(
              icono: _iconos[tipo] ?? Icons.add,
              etiqueta: tipo.etiqueta,
              alTocar: habilitado ? () => alElegir(tipo) : null,
            ),
          ),
          if (tipo != TipoElemento.values.last) const SizedBox(width: 8),
        ],
      ],
    );
  }
}

class _BotonAgregar extends StatelessWidget {
  const _BotonAgregar({
    required this.icono,
    required this.etiqueta,
    required this.alTocar,
  });

  final IconData icono;
  final String etiqueta;
  final VoidCallback? alTocar;

  @override
  Widget build(BuildContext context) {
    final color = alTocar == null ? ColoresApp.atenuado : ColoresApp.primario;
    return Material(
      color: ColoresApp.acento.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(TemaApp.radioMediano),
      child: InkWell(
        borderRadius: BorderRadius.circular(TemaApp.radioMediano),
        onTap: alTocar,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 72),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icono, color: color),
                const SizedBox(height: 6),
                Text(
                  etiqueta,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: color,
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
