import 'package:flutter/material.dart';

import '../../dominio/recuerdo.dart';
import 'miniatura_recuerdo.dart';

/// [MiniaturaRecuerdo] que, para fotos y videos, carga la miniatura firmada
/// del servidor (Edge Function `firmar-medio`).
class MiniaturaRecuerdoFirmada extends StatelessWidget {
  const MiniaturaRecuerdoFirmada({
    super.key,
    required this.recuerdo,
    this.tamanoIcono = 30,
  });

  final Recuerdo recuerdo;
  final double tamanoIcono;

  @override
  Widget build(BuildContext context) =>
      MiniaturaRecuerdo(recuerdo: recuerdo, tamanoIcono: tamanoIcono);
}
