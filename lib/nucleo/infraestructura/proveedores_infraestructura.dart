import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'cliente_almacenamiento.dart';
import 'cliente_autenticacion.dart';
import 'cliente_funciones_api.dart';
import 'cliente_postgrest.dart';
import 'configuracion_backend.dart';
import 'proveedores/supabase/cliente_almacenamiento_cloudinary.dart';
import 'proveedores/supabase/cliente_autenticacion_supabase.dart';
import 'proveedores/supabase/cliente_funciones_supabase.dart';
import 'proveedores/supabase/cliente_postgrest_supabase.dart';
import 'proveedores/vps/cliente_autenticacion_jwt.dart';
import 'proveedores/vps/cliente_funciones_http.dart';
import 'proveedores/vps/cliente_postgrest_http.dart';

/// Composition root de la infraestructura. Cambiar de Supabase a VPS es solo
/// modificar `--dart-define=BACKEND=vps` y las URLs en el archivo de entorno.
final proveedorClienteAutenticacion = Provider<ClienteAutenticacion>((ref) {
  if (ConfiguracionBackend.esVps) {
    final cliente = ClienteAutenticacionJwt();
    ref.onDispose(cliente.liberarRecursos);
    return cliente;
  }
  return ClienteAutenticacionSupabase();
});

final proveedorClientePostgrest = Provider<ClientePostgrest>((ref) {
  if (ConfiguracionBackend.esVps) {
    final auth = ref.watch(proveedorClienteAutenticacion);
    final cliente = ClientePostgrestHttp(tokenAcceso: auth.tokenAcceso);
    ref.listen(proveedorClienteAutenticacion, (_, siguiente) {
      cliente.tokenAcceso = siguiente.tokenAcceso;
    });
    ref.onDispose(cliente.liberarRecursos);
    return cliente;
  }
  return ClientePostgrestSupabase();
});

final proveedorClienteFuncionesApi = Provider<ClienteFuncionesApi>((ref) {
  if (ConfiguracionBackend.esVps) {
    final cliente = ClienteFuncionesHttp(
      autenticacion: ref.watch(proveedorClienteAutenticacion),
    );
    ref.onDispose(cliente.liberarRecursos);
    return cliente;
  }
  return ClienteFuncionesSupabase();
});

final proveedorClienteAlmacenamiento = Provider<ClienteAlmacenamiento>((ref) {
  final cliente = ClienteAlmacenamientoCloudinary();
  ref.onDispose(cliente.liberarRecursos);
  return cliente;
});
