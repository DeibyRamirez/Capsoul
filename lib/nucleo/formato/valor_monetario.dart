import 'package:flutter/services.dart';

/// Miles con punto cada tres dígitos (COP): `1250000` → `1.250.000`.
String formatearMiles(String crudo) {
  final digitos = soloDigitos(crudo);
  if (digitos.isEmpty) return '';
  final buf = StringBuffer();
  for (var i = 0; i < digitos.length; i++) {
    if (i > 0 && (digitos.length - i) % 3 == 0) buf.write('.');
    buf.write(digitos[i]);
  }
  return buf.toString();
}

/// Quita todo lo que no sea 0-9.
String soloDigitos(String crudo) {
  final buf = StringBuffer();
  for (final r in crudo.runes) {
    if (r >= 48 && r <= 57) buf.writeCharCode(r);
  }
  return buf.toString();
}

/// Entero ≥ 0 o null si no hay dígitos.
int? parsearEnteroMiles(String crudo) {
  final digitos = soloDigitos(crudo);
  if (digitos.isEmpty) return null;
  return int.tryParse(digitos);
}

/// Teclado numérico: solo dígitos, puntos de miles al vuelo.
class FormateadorMilesInput extends TextInputFormatter {
  const FormateadorMilesInput();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final formateado = formatearMiles(newValue.text);
    return TextEditingValue(
      text: formateado,
      selection: TextSelection.collapsed(offset: formateado.length),
    );
  }
}
