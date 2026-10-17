import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'almacenamiento_sesion_auth.dart';

/// Copia la sesión legacy de SharedPreferences al almacenamiento seguro una vez.
Future<void> migrarSesionDesdeSharedPreferencesSiHaceFalta({
  required LocalStorage destino,
  SharedPreferences? preferencias,
}) async {
  if (kIsWeb) return;
  final prefs = preferencias ?? await SharedPreferences.getInstance();
  const clavesLegacy = [
    AlmacenamientoSesionAuth.clavePersistencia,
    'supabase.auth.token',
  ];
  String? sesion;
  String? claveUsada;
  for (final clave in clavesLegacy) {
    final valor = prefs.getString(clave);
    if (valor != null && valor.isNotEmpty) {
      sesion = valor;
      claveUsada = clave;
      break;
    }
  }
  if (sesion == null) return;
  if (await destino.hasAccessToken()) return;
  await destino.persistSession(sesion);
  if (claveUsada != null) await prefs.remove(claveUsada);
}
