import 'dart:async';

import 'package:flutter/material.dart';

import '../../dominio/apertura_capsula.dart';

/// Texto "Faltan …" que se actualiza cada minuto. Avisa con [alLlegar]
/// cuando la fecha se cumple con la pantalla abierta.
class CuentaRegresiva extends StatefulWidget {
  const CuentaRegresiva({
    super.key,
    required this.fechaApertura,
    required this.reloj,
    this.alLlegar,
  });

  final DateTime fechaApertura;
  final DateTime Function() reloj;
  final VoidCallback? alLlegar;

  @override
  State<CuentaRegresiva> createState() => _EstadoCuentaRegresiva();
}

class _EstadoCuentaRegresiva extends State<CuentaRegresiva> {
  Timer? _temporizador;

  @override
  void initState() {
    super.initState();
    _temporizador = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!mounted) return;
      setState(() {});
      if (!widget.fechaApertura.isAfter(widget.reloj())) {
        _temporizador?.cancel();
        widget.alLlegar?.call();
      }
    });
  }

  @override
  void dispose() {
    _temporizador?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(describirTiempoRestante(widget.reloj(), widget.fechaApertura));
  }
}
