import 'package:flutter/material.dart';

import '../errores/fallo_app.dart';

/// Muestra un SnackBar flotante de error con el mensaje en español de [error].
void mostrarAvisoError(BuildContext context, Object? error) {
  final mensajero = ScaffoldMessenger.of(context);
  mensajero
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(mensajeParaUsuario(error))));
}

/// Muestra un SnackBar flotante informativo.
void mostrarAvisoInformativo(BuildContext context, String mensaje) {
  final mensajero = ScaffoldMessenger.of(context);
  mensajero
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(mensaje)));
}
