import '../../../nucleo/errores/fallo_app.dart';

class FalloLegado implements FalloApp {
  const FalloLegado(this.codigo, this.mensaje);

  static const codigoSinSesion = 'sin_sesion';
  static const codigoNoEncontrado = 'no_encontrado';
  static const codigoUsuarioNoEncontrado = 'usuario_no_encontrado';
  static const codigoDebeSerAmigo = 'debe_ser_amigo';
  static const codigoFechaRequerida = 'fecha_requerida';
  static const codigoFechaDebeSerFutura = 'fecha_debe_ser_futura';
  static const codigoPersonaConfianzaRequerida = 'persona_confianza_requerida';
  static const codigoInactividadRequerida = 'inactividad_requerida';
  static const codigoCondicionCoherente = 'condicion_coherente';
  static const codigoCapsulaInvalida = 'capsula_invalida';
  static const codigoHerenciaNoEditable = 'herencia_no_editable';
  static const codigoFuncionNoDisponible = 'funcion_no_disponible';
  static const codigoDesconocido = 'desconocido';

  @override
  final String codigo;
  @override
  final String mensaje;

  static const sinSesion = FalloLegado(
    codigoSinSesion,
    'Inicia sesión para gestionar tu legado.',
  );

  static const fechaRequerida = FalloLegado(
    codigoFechaRequerida,
    'Elige la fecha en la que se activará el legado.',
  );

  static const fechaDebeSerFutura = FalloLegado(
    codigoFechaDebeSerFutura,
    'La fecha de activación debe ser posterior a hoy.',
  );

  static const personaConfianzaRequerida = FalloLegado(
    codigoPersonaConfianzaRequerida,
    'Configura una persona de confianza en Seguridad del legado antes de activar.',
  );

  static const inactividadRequerida = FalloLegado(
    codigoInactividadRequerida,
    'Indica cuántos días de inactividad deben pasar antes de activar el legado.',
  );

  static const condicionCoherente = FalloLegado(
    codigoCondicionCoherente,
    'Revisa la condición de activación: falta la fecha, los días de inactividad o la persona de confianza.',
  );

  static const capsulaInvalida = FalloLegado(
    codigoCapsulaInvalida,
    'Solo puedes vincular cápsulas que hayas creado tú.',
  );

  static const herenciaNoEditable = FalloLegado(
    codigoHerenciaNoEditable,
    'Esta herencia ya no se puede editar.',
  );

  static const funcionNoDisponible = FalloLegado(
    codigoFuncionNoDisponible,
    'El servidor de legado no está actualizado. Contacta al equipo de Capsoul.',
  );

  static FalloLegado desdeCodigoPostgres(String? codigo) {
    switch (codigo) {
      case 'usuario_no_encontrado':
        return const FalloLegado(
          codigoUsuarioNoEncontrado,
          'No encontramos ese usuario.',
        );
      case 'debe_ser_amigo':
        return const FalloLegado(
          codigoDebeSerAmigo,
          'La persona de confianza debe ser tu amigo en Capsoul.',
        );
      case 'capsula_invalida':
        return capsulaInvalida;
      case 'herencia_no_editable':
        return herenciaNoEditable;
      case 'sin_sesion':
        return sinSesion;
      default:
        return const FalloLegado(
          codigoDesconocido,
          'No pudimos completar la operación de legado.',
        );
    }
  }

  /// Interpreta códigos embebidos en el mensaje de PostgREST/Postgres.
  static FalloLegado desdeMensajePostgres(String mensaje) {
    if (mensaje.contains('herencias_condicion_coherente')) {
      return condicionCoherente;
    }
    for (final codigo in [
      'usuario_no_encontrado',
      'debe_ser_amigo',
      'capsula_invalida',
      'herencia_no_editable',
    ]) {
      if (mensaje.contains(codigo)) {
        return desdeCodigoPostgres(codigo);
      }
    }
    return const FalloLegado(
      codigoDesconocido,
      'No pudimos completar la operación de legado.',
    );
  }
}
