import 'package:capsoul/nucleo/infraestructura/proveedores/supabase/almacenamiento_sesion_auth.dart';
import 'package:capsoul/nucleo/infraestructura/proveedores/supabase/migracion_sesion_shared_preferences.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _LocalFalso implements LocalStorage {
  String? _sesion;

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> hasAccessToken() async =>
      _sesion != null && _sesion!.isNotEmpty;

  @override
  Future<String?> accessToken() async => _sesion;

  @override
  Future<void> persistSession(String persistSessionString) async {
    _sesion = persistSessionString;
  }

  @override
  Future<void> removePersistedSession() async {
    _sesion = null;
  }
}

void main() {
  test('migra desde SharedPreferences y borra la clave legacy', () async {
    SharedPreferences.setMockInitialValues({
      AlmacenamientoSesionAuth.clavePersistencia: '{"refresh":"r"}',
    });
    final prefs = await SharedPreferences.getInstance();
    final destino = _LocalFalso();
    await migrarSesionDesdeSharedPreferencesSiHaceFalta(
      destino: destino,
      preferencias: prefs,
    );
    expect(await destino.accessToken(), '{"refresh":"r"}');
    expect(
      prefs.getString(AlmacenamientoSesionAuth.clavePersistencia),
      isNull,
    );
  });

  test('no sobrescribe si el destino ya tiene sesión', () async {
    SharedPreferences.setMockInitialValues({
      AlmacenamientoSesionAuth.clavePersistencia: '{"vieja":true}',
    });
    final prefs = await SharedPreferences.getInstance();
    final destino = _LocalFalso();
    await destino.persistSession('{"nueva":true}');
    await migrarSesionDesdeSharedPreferencesSiHaceFalta(
      destino: destino,
      preferencias: prefs,
    );
    expect(await destino.accessToken(), '{"nueva":true}');
  });
}
