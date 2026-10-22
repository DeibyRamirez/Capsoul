import 'package:flutter/material.dart';

import '../../../../nucleo/componentes/ilustracion_marca.dart';
import '../../../../nucleo/tema/colores_app.dart';
import '../../../../nucleo/tema/espaciado_app.dart';
import '../../../../nucleo/tema/tema_app.dart';
import '../../../../nucleo/tema/tipografia_app.dart';

/// Hero de Inicio: la acuarela clara, fundida con el fondo, y la frase
/// editorial. El texto queda fuera de la imagen para que escale sin recortarse.
class EscenaFrascoInicio extends StatelessWidget {
  const EscenaFrascoInicio({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(TemaApp.radioGrande),
          child: const AspectRatio(
            aspectRatio: 1.15,
            child: ColoredBox(
              color: ColoresApp.superficie,
              child: IlustracionMarca(
                ruta: IlustracionesMarca.heroCalma,
                alineacion: Alignment.center,
                fundirAbajo: true,
              ),
            ),
          ),
        ),
        const SizedBox(height: EspaciadoApp.sm),
        const _TextoManuscrito(),
      ],
    );
  }
}

class _TextoManuscrito extends StatelessWidget {
  const _TextoManuscrito();

  @override
  Widget build(BuildContext context) {
    final estilo = TipografiaApp.titular.copyWith(
      fontStyle: FontStyle.italic,
      fontWeight: FontWeight.w500,
      color: ColoresApp.primario,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Tu vida.', style: estilo),
        Text('Tus momentos.', style: estilo),
        Text('Tu legado.', style: estilo),
      ],
    );
  }
}
