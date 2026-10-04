/// Validadores de formulario en español compartidos por las pantallas de
/// autenticación y de perfil.
abstract final class ValidadoresAutenticacion {
  static const int longitudMinimaContrasena = 8;
  static const int longitudMaximaNombre = 60;

  static final RegExp _patronCorreo = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  static String? correo(String? valor) {
    final texto = valor?.trim() ?? '';
    if (texto.isEmpty) return 'Ingresa tu correo electrónico';
    if (!_patronCorreo.hasMatch(texto)) {
      return 'Ingresa un correo electrónico válido';
    }
    return null;
  }

  static String? contrasenaInicioSesion(String? valor) {
    if (valor == null || valor.isEmpty) return 'Ingresa tu contraseña';
    return null;
  }

  static String? contrasenaNueva(String? valor) {
    if (valor == null || valor.isEmpty) return 'Ingresa una contraseña';
    if (valor.length < longitudMinimaContrasena) {
      return 'La contraseña debe tener al menos '
          '$longitudMinimaContrasena caracteres';
    }
    return null;
  }

  static String? confirmarContrasena(String? valor, String contrasena) {
    if (valor == null || valor.isEmpty) return 'Confirma tu contraseña';
    if (valor != contrasena) return 'Las contraseñas no coinciden';
    return null;
  }

  static String? nombreVisible(String? valor) {
    final texto = valor?.trim() ?? '';
    if (texto.isEmpty) return 'Ingresa tu nombre';
    if (texto.length > longitudMaximaNombre) {
      return 'El nombre no puede superar $longitudMaximaNombre caracteres';
    }
    return null;
  }
}
