import 'package:flutter/material.dart';

import '../../../../nucleo/tema/colores_app.dart';
import '../../../../nucleo/tema/tema_app.dart';

class TituloSeccionCrear extends StatelessWidget {
  const TituloSeccionCrear(this.texto, {super.key});

  final String texto;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 12, 4, 8),
        child: Text(
          texto,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: ColoresApp.primario,
          ),
        ),
      );
}

class OpcionCrear extends StatelessWidget {
  const OpcionCrear({
    super.key,
    required this.icono,
    required this.titulo,
    required this.subtitulo,
    required this.alTocar,
    this.destacada = false,
  });

  final IconData icono;
  final String titulo;
  final String subtitulo;
  final VoidCallback alTocar;
  final bool destacada;

  @override
  Widget build(BuildContext context) {
    final colorTexto =
        destacada ? ColoresApp.sobrePrimario : ColoresApp.sobreSuperficie;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: destacada ? ColoresApp.primario : null,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(TemaApp.radioMediano),
        ),
        leading: CircleAvatar(
          backgroundColor: destacada
              ? ColoresApp.sobrePrimario.withValues(alpha: 0.15)
              : ColoresApp.acento.withValues(alpha: 0.15),
          foregroundColor:
              destacada ? ColoresApp.sobrePrimario : ColoresApp.primario,
          child: Icon(icono),
        ),
        title: Text(
          titulo,
          style: TextStyle(fontWeight: FontWeight.w600, color: colorTexto),
        ),
        subtitle: Text(
          subtitulo,
          style: destacada
              ? TextStyle(color: colorTexto.withValues(alpha: 0.8))
              : null,
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: destacada ? ColoresApp.sobrePrimario : ColoresApp.atenuado,
        ),
        onTap: alTocar,
      ),
    );
  }
}
