/// Reglas de `usuarios.nombre_usuario` (alineadas con la migración 000010).
abstract final class ValidadorNombreUsuario {
  static const int longitudMin = 3;
  static const int longitudMax = 30;

  static final RegExp _patron = RegExp(r'^[a-z0-9_]+$');

  static String normalizar(String entrada) {
    var texto = entrada.trim();
    if (texto.startsWith('@')) texto = texto.substring(1);
    return texto.toLowerCase().replaceAll(RegExp(r'[^a-z0-9_]'), '');
  }

  static String? validar(String? valor) {
    final texto = normalizar(valor ?? '');
    if (texto.isEmpty) return 'Elige tu usuario con @';
    if (texto.length < longitudMin) {
      return 'Mínimo $longitudMin caracteres (letras, números o _)';
    }
    if (texto.length > longitudMax) {
      return 'Máximo $longitudMax caracteres';
    }
    if (!_patron.hasMatch(texto)) {
      return 'Solo letras minúsculas, números y guion bajo';
    }
    return null;
  }
}
