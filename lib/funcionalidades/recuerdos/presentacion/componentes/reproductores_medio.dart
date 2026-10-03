import 'package:flutter/material.dart';

import '../../dominio/recuerdo.dart';
import 'vista_recuerdo.dart';

/// Foto a tamaño completo (URL firmada de `firmar-medio`).
class FotoCompleta extends StatelessWidget {
  const FotoCompleta({super.key, required this.recuerdo});

  final Recuerdo recuerdo;

  @override
  Widget build(BuildContext context) => MarcoMiniatura(recuerdo: recuerdo);
}

/// Reproductor de video del recuerdo.
class ReproductorVideoRecuerdo extends StatelessWidget {
  const ReproductorVideoRecuerdo({super.key, required this.recuerdo});

  final Recuerdo recuerdo;

  @override
  Widget build(BuildContext context) => MarcoMiniatura(recuerdo: recuerdo);
}

/// Reproductor de la nota de voz con su onda.
class ReproductorAudioRecuerdo extends StatelessWidget {
  const ReproductorAudioRecuerdo({super.key, required this.recuerdo});

  final Recuerdo recuerdo;

  @override
  Widget build(BuildContext context) => MarcoMiniatura(recuerdo: recuerdo);
}
