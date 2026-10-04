import 'package:flutter/material.dart';

import '../../../../nucleo/tema/colores_app.dart';
import '../../../../nucleo/tema/tema_app.dart';

/// Círculos de destacados (Retos, Cápsulas, Herencias, Recuerdos).
class FilaDestacadosPerfil extends StatelessWidget {
  const FilaDestacadosPerfil({super.key, this.alTocar});

  final void Function(String etiqueta)? alTocar;

  static const _destacados = <({String etiqueta, IconData icono, Color fondo})>[
    (etiqueta: 'Retos', icono: Icons.flag_outlined, fondo: Color(0xFFB8D4E8)),
    (etiqueta: 'Cápsulas', icono: Icons.lock_outline, fondo: Color(0xFFB8D4E8)),
    (
      etiqueta: 'Herencias',
      icono: Icons.card_giftcard_outlined,
      fondo: Color(0xFFC8E6C9),
    ),
    (
      etiqueta: 'Recuerdos',
      icono: Icons.favorite_outline,
      fondo: Color(0xFFF8BBD0),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _destacados.length,
        separatorBuilder: (_, _) => const SizedBox(width: 14),
        itemBuilder: (context, indice) {
          final item = _destacados[indice];
          return _Destacado(
            etiqueta: item.etiqueta,
            icono: item.icono,
            fondo: item.fondo,
            alTocar: () => alTocar?.call(item.etiqueta),
          );
        },
      ),
    );
  }
}

class _Destacado extends StatelessWidget {
  const _Destacado({
    required this.etiqueta,
    required this.icono,
    required this.fondo,
    this.alTocar,
  });

  final String etiqueta;
  final IconData icono;
  final Color fondo;
  final VoidCallback? alTocar;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Destacado $etiqueta',
      child: InkWell(
        onTap: alTocar,
        borderRadius: BorderRadius.circular(TemaApp.radioGrande),
        child: SizedBox(
          width: 72,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: fondo,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: ColoresApp.atenuado.withValues(alpha: 0.25),
                  ),
                ),
                child: Icon(icono, color: ColoresApp.primario),
              ),
              const SizedBox(height: 6),
              Text(
                etiqueta,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 11, color: ColoresApp.primario),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
