import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Persistencia de sesión GoTrue en almacenamiento seguro del dispositivo.
class AlmacenamientoSesionAuth implements LocalStorage {
  AlmacenamientoSesionAuth({FlutterSecureStorage? almacenamiento})
      : _almacenamiento = almacenamiento ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
            );

  static const String clavePersistencia = 'supabase.auth.token';

  final FlutterSecureStorage _almacenamiento;

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> hasAccessToken() async {
    final token = await accessToken();
    return token != null && token.isNotEmpty;
  }

  @override
  Future<String?> accessToken() =>
      _almacenamiento.read(key: clavePersistencia);

  @override
  Future<void> persistSession(String persistSessionString) async {
    await _almacenamiento.write(
      key: clavePersistencia,
      value: persistSessionString,
    );
  }

  @override
  Future<void> removePersistedSession() async {
    await _almacenamiento.delete(key: clavePersistencia);
  }
}
