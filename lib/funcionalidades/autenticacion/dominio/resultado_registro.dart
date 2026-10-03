import 'usuario_app.dart';

/// Resultado de crear una cuenta.
///
/// Si Supabase Auth exige confirmar el correo, `signUp` no abre sesión:
/// [sesionIniciada] es `false` y el usuario debe confirmar y luego iniciar
/// sesión.
class ResultadoRegistro {
  const ResultadoRegistro({
    required this.usuario,
    required this.sesionIniciada,
  });

  final UsuarioApp usuario;
  final bool sesionIniciada;

  bool get requiereConfirmarCorreo => !sesionIniciada;
}
