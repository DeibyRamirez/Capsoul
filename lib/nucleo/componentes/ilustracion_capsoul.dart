import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Nombres de archivo (sin carpeta ni extensión) de las ilustraciones.
///
/// El PNG vive en `assets/illustrations/<nombre>.png`. Si todavía no está
/// en el proyecto, [IlustracionCapsoul] dibuja [fallback].
abstract final class NombresIlustracion {
  static const String heroFrasco = 'hero_jar';
  static const String authNoche = 'auth_night';
  static const String onboarding1 = 'onboarding_1';
  static const String onboarding2 = 'onboarding_2';
  static const String onboarding3 = 'onboarding_3';
  static const String tarjetaRecuerdos = 'card_memories';
  static const String tarjetaMomentos = 'card_moments';
  static const String tarjetaCapsula = 'card_capsule';
  static const String tarjetaLegado = 'card_legacy';
  static const String vacioRecuerdos = 'empty_memories';
  static const String vacioMomentos = 'empty_moments';
  static const String vacioCapsulas = 'empty_capsules';
  static const String vacioRecibidas = 'empty_received';
  static const String vacioLegado = 'empty_legacy';
  static const String vacioAmigos = 'empty_friends';
  static const String capsulaSellada = 'capsule_sealed';
  static const String capsulaAbierta = 'capsule_opened';
  static const String retoDiario = 'challenge_daily';
  static const String retoSemanal = 'challenge_weekly';
  static const String retoEspecial = 'challenge_special';
  static const String retoHecho = 'challenge_done';
  static const String errorSinConexion = 'error_offline';

  static String ruta(String nombre) => 'assets/illustrations/$nombre.png';
}

/// Comprueba una vez por nombre si el PNG está en el manifiesto de assets.
abstract final class CatalogoIlustraciones {
  static final Map<String, Future<bool>> _existe = {};

  static Future<bool> existe(String nombre) {
    return _existe.putIfAbsent(nombre, () async {
      try {
        await rootBundle.load(NombresIlustracion.ruta(nombre));
        return true;
      } catch (_) {
        return false;
      }
    });
  }
}

/// Hueco de ilustración: PNG si el archivo existe, si no el arte en código.
class IlustracionCapsoul extends StatelessWidget {
  const IlustracionCapsoul({
    super.key,
    required this.nombre,
    required this.fallback,
    this.ancho,
    this.alto,
    this.ajuste = BoxFit.contain,
  });

  final String nombre;
  final Widget fallback;
  final double? ancho;
  final double? alto;
  final BoxFit ajuste;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: CatalogoIlustraciones.existe(nombre),
      builder: (context, snapshot) {
        if (snapshot.data != true) {
          return SizedBox(width: ancho, height: alto, child: fallback);
        }
        return Image.asset(
          NombresIlustracion.ruta(nombre),
          width: ancho,
          height: alto,
          fit: ajuste,
          gaplessPlayback: true,
          errorBuilder: (_, _, _) =>
              SizedBox(width: ancho, height: alto, child: fallback),
        );
      },
    );
  }
}
