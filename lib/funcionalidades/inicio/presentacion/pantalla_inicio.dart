import 'package:flutter/material.dart';

import '../../../nucleo/tema/colores_app.dart';

/// Pestaña "Inicio": saludo y la cúpula de vidrio característica de Capsoul.
class PantallaInicio extends StatelessWidget {
  const PantallaInicio({super.key});

  @override
  Widget build(BuildContext context) {
    final estilosTexto = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Hola',
                style: estilosTexto.headlineMedium?.copyWith(
                  color: ColoresApp.primario,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Bienvenido a Capsoul',
                style: estilosTexto.titleMedium?.copyWith(
                  color: ColoresApp.atenuado,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Pequeñas herencias, grandes recuerdos',
                style: estilosTexto.bodyMedium?.copyWith(
                  color: ColoresApp.acento,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const Spacer(),
              const _MarcadorCupulaVidrio(),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

class _MarcadorCupulaVidrio extends StatelessWidget {
  const _MarcadorCupulaVidrio();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 220,
        height: 220,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              ColoresApp.acento.withValues(alpha: 0.35),
              ColoresApp.primario.withValues(alpha: 0.55),
              ColoresApp.primario,
            ],
          ),
          border: Border.all(
            color: ColoresApp.bordeCupula,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: ColoresApp.primario.withValues(alpha: 0.25),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Container(
          margin: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: ColoresApp.vidrioCupula,
            border: Border.all(
              color: ColoresApp.sobrePrimario.withValues(alpha: 0.35),
            ),
          ),
          child: const Center(
            child: Icon(
              Icons.auto_awesome,
              color: ColoresApp.sobrePrimario,
              size: 48,
            ),
          ),
        ),
      ),
    );
  }
}
