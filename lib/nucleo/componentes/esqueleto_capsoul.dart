import 'package:flutter/material.dart';

import '../tema/colores_app.dart';
import '../tema/espaciado_app.dart';
import '../tema/tema_app.dart';

/// Bloque gris estático. Sin ticker: un esqueleto animado en cada celda
/// competiría con el cielo y con el desplazamiento.
class EsqueletoCapsoul extends StatelessWidget {
  const EsqueletoCapsoul({
    super.key,
    this.ancho,
    this.alto = 16,
    this.radio = TemaApp.radioPequeno,
  });

  final double? ancho;
  final double alto;
  final double radio;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: ancho,
      height: alto,
      decoration: BoxDecoration(
        color: ColoresApp.azul100,
        borderRadius: BorderRadius.circular(radio),
      ),
    );
  }
}

/// Rejilla de carga para Momentos y Recuerdos.
class EsqueletoRejillaCapsoul extends StatelessWidget {
  const EsqueletoRejillaCapsoul({super.key, this.celdas = 4});

  final int celdas;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        EspaciadoApp.md,
        EspaciadoApp.sm,
        EspaciadoApp.md,
        EspaciadoApp.lg,
      ),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: EspaciadoApp.sm,
        crossAxisSpacing: EspaciadoApp.sm,
        childAspectRatio: 0.8,
      ),
      itemCount: celdas,
      itemBuilder: (_, _) => const _TarjetaEsqueleto(),
    );
  }
}

class SliverEsqueletoRejillaCapsoul extends StatelessWidget {
  const SliverEsqueletoRejillaCapsoul({super.key, this.celdas = 4});

  final int celdas;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(
        EspaciadoApp.md,
        EspaciadoApp.sm,
        EspaciadoApp.md,
        EspaciadoApp.lg,
      ),
      sliver: SliverGrid.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: EspaciadoApp.sm,
          crossAxisSpacing: EspaciadoApp.sm,
          childAspectRatio: 0.8,
        ),
        itemCount: celdas,
        itemBuilder: (_, _) => const _TarjetaEsqueleto(),
      ),
    );
  }
}

class _TarjetaEsqueleto extends StatelessWidget {
  const _TarjetaEsqueleto();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        color: ColoresApp.tarjeta,
        borderRadius: BorderRadius.all(Radius.circular(TemaApp.radioGrande)),
        border: Border.fromBorderSide(BorderSide(color: ColoresApp.bordeTarjeta)),
      ),
      child: Padding(
        padding: EdgeInsets.all(EspaciadoApp.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: ColoresApp.azul100,
                  borderRadius: BorderRadius.all(
                    Radius.circular(TemaApp.radioMediano),
                  ),
                ),
              ),
            ),
            SizedBox(height: EspaciadoApp.sm),
            EsqueletoCapsoul(ancho: 96, alto: 12),
            SizedBox(height: EspaciadoApp.xs),
            EsqueletoCapsoul(ancho: 64, alto: 10),
          ],
        ),
      ),
    );
  }
}
