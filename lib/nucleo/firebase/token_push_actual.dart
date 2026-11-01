import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Token FCM de este dispositivo, cuando ya se conoce. Cerrar sesión lo usa
/// para borrar solo este token y no los de los otros teléfonos del usuario.
class TokenPushActual extends Notifier<String?> {
  @override
  String? build() => null;

  void recordar(String token) {
    if (token.isEmpty) return;
    state = token;
  }
}

final proveedorTokenPushActual = NotifierProvider<TokenPushActual, String?>(
  TokenPushActual.new,
);
