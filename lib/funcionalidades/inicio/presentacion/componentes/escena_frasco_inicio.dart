import 'package:flutter/material.dart';

import '../../../../nucleo/componentes/cielo_nocturno.dart';
import '../../../../nucleo/componentes/frasco_luminoso.dart';
import '../../../../nucleo/tema/colores_app.dart';
import '../../../../nucleo/tema/tema_app.dart';

/// La cápsula de vidrio iluminada con recuerdos dentro y el texto
/// manuscrito "Tu vida. Tus momentos. Tu legado.", dentro de una tarjeta
/// medianoche con el cielo de luciernagas (la cupula de vidrio necesita
/// fondo oscuro para leerse).
class EscenaFrascoInicio extends StatelessWidget {
  const EscenaFrascoInicio({super.key});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(TemaApp.radioGrande),
      child: CieloNocturno(
        brillo: 0.9,
        child: SizedBox(
          height: 270,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned(
                bottom: 8,
                child: Container(
                  width: 240,
                  height: 28,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.all(
                      Radius.elliptical(240, 28),
                    ),
                    gradient: RadialGradient(
                      colors: [
                        ColoresApp.doradoClaro.withValues(alpha: 0.30),
                        ColoresApp.doradoClaro.withValues(alpha: 0),
                      ],
                    ),
                  ),
                ),
              ),
              const FrascoLuminoso(
                tamano: 250,
                brillo: 0.9,
                conRecuerdos: true,
                conCandado: true,
              ),
              const Positioned(right: 12, top: 70, child: _TextoManuscrito()),
            ],
          ),
        ),
      ),
    );
  }
}

class _TextoManuscrito extends StatelessWidget {
  const _TextoManuscrito();

  @override
  Widget build(BuildContext context) {
    final estilo = Theme.of(context).textTheme.titleMedium?.copyWith(
      color: ColoresApp.sobrePrimario.withValues(alpha: 0.95),
      fontStyle: FontStyle.italic,
      fontFamily: TemaApp.fuenteTitulos,
      fontWeight: FontWeight.w400,
      height: 1.5,
      shadows: const [Shadow(blurRadius: 4, color: ColoresApp.sombraTexto)],
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Tu vida.', style: estilo),
        Text('Tus momentos.', style: estilo),
        Text('Tu legado.', style: estilo),
        const SizedBox(height: 4),
        Icon(Icons.favorite_border, size: 16, color: ColoresApp.doradoClaro),
      ],
    );
  }
}
