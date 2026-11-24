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
  static const codigoCampoObligatorio = 'campo_obligatorio';
  static const codigoValorInvalido = 'valor_invalido';
  static const codigoCondicionCoherente = 'condicion_coherente';
  static const codigoCapsulaInvalida = 'capsula_invalida';
  static const codigoHerenciaNoEditable = 'herencia_no_editable';
  static const codigoFuncionNoDisponible = 'funcion_no_disponible';
  static const codigoConfianzaDebeSerAmigo = 'confianza_debe_ser_amigo';
  static const codigoConfianzaNoBeneficiario = 'confianza_no_beneficiario';
  static const codigoConfianzaRequerida = 'confianza_requerida';
  static const codigoSinPermiso = 'sin_permiso';
  static const codigoHerenciaNoLiberada = 'herencia_no_liberada';
  static const codigoCodigoNoVigente = 'codigo_no_vigente';
  static const codigoCodigoIncorrecto = 'codigo_incorrecto';
  static const codigoCodigoBloqueado = 'codigo_bloqueado';
  static const codigoEsperaReenvio = 'espera_reenvio';
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

  static const campoObligatorio = FalloLegado(
    codigoCampoObligatorio,
    'Completa todos los campos para continuar.',
  );

  static const valorInvalido = FalloLegado(
    codigoValorInvalido,
    'El valor aproximado debe ser un número (usa puntos para los miles).',
  );

  static const beneficiarioRequerido = FalloLegado(
    codigoCampoObligatorio,
    'Elige a quién va dirigida esta pequeña herencia.',
  );

  static const condicionCoherente = FalloLegado(
    codigoCondicionCoherente,
    'Revisa la condición de activación: falta la fecha, los días de inactividad o la persona de confianza.',
  );

  static const capsulaInvalida = FalloLegado(
    codigoCapsulaInvalida,
    'Solo puedes vincular cápsulas propias que estén programadas o abiertas.',
  );

  static const herenciaNoEditable = FalloLegado(
    codigoHerenciaNoEditable,
    'Esta herencia ya no se puede editar.',
  );

  static const funcionNoDisponible = FalloLegado(
    codigoFuncionNoDisponible,
    'El servidor de legado no está actualizado. Contacta al equipo de Capsoul.',
  );

  static const confianzaDebeSerAmigo = FalloLegado(
    codigoConfianzaDebeSerAmigo,
    'La persona de confianza debe ser tu amigo en Capsoul.',
  );

  static const confianzaNoBeneficiario = FalloLegado(
    codigoConfianzaNoBeneficiario,
    'La persona de confianza no puede ser quien recibe la herencia.',
  );

  static const confianzaRequerida = FalloLegado(
    codigoConfianzaRequerida,
    'Elige una persona de confianza para esta herencia.',
  );

  static const sinPermiso = FalloLegado(
    codigoSinPermiso,
    'No tienes permiso para ver esta herencia.',
  );

  static const herenciaNoLiberada = FalloLegado(
    codigoHerenciaNoLiberada,
    'La herencia todavía no se ha abierto. Espera la fecha indicada.',
  );

  static const codigoNoVigente = FalloLegado(
    codigoCodigoNoVigente,
    'El código no está vigente. Pide uno nuevo.',
  );

  static const codigoBloqueado = FalloLegado(
    codigoCodigoBloqueado,
    'Demasiados intentos. Espera unos minutos antes de volver a intentarlo.',
  );

  static const esperaReenvio = FalloLegado(
    codigoEsperaReenvio,
    'Espera un minuto antes de pedir otro código.',
  );

  static FalloLegado codigoIncorrecto(int? intentosRestantes) {
    final restantes = intentosRestantes ?? 0;
    return FalloLegado(
      codigoCodigoIncorrecto,
      restantes > 0
          ? 'Código incorrecto. Te quedan $restantes intento'
              '${restantes == 1 ? '' : 's'}.'
          : 'Código incorrecto. Pide un código nuevo.',
    );
  }

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
      case 'titulo_requerido':
        return campoObligatorio;
      case 'sin_sesion':
        return sinSesion;
      case 'confianza_debe_ser_amigo':
        return confianzaDebeSerAmigo;
      case 'confianza_no_beneficiario':
        return confianzaNoBeneficiario;
      case 'confianza_requerida':
        return confianzaRequerida;
      case 'sin_permiso':
        return sinPermiso;
      case 'herencia_no_liberada':
        return herenciaNoLiberada;
      case 'codigo_no_vigente':
        return codigoNoVigente;
      case 'codigo_bloqueado':
        return codigoBloqueado;
      case 'espera_reenvio':
        return esperaReenvio;
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
      'titulo_requerido',
      'confianza_debe_ser_amigo',
      'confianza_no_beneficiario',
      'confianza_requerida',
      'sin_permiso',
      'herencia_no_liberada',
      'codigo_no_vigente',
      'codigo_bloqueado',
      'espera_reenvio',
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
