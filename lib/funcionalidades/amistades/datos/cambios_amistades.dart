import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Avisa cuando cambia una fila de `amistades` donde el usuario es receptor.
abstract interface class FuenteCambiosAmistades {
  /// Emite un evento por cada insert, update o delete. Al cancelar la
  /// suscripción se cierra el canal.
  Stream<void> escuchar(String uidReceptor);
}

/// Sin tiempo real (backend VPS o pruebas): no emite nada.
class FuenteCambiosAmistadesInactiva implements FuenteCambiosAmistades {
  const FuenteCambiosAmistadesInactiva();

  @override
  Stream<void> escuchar(String uidReceptor) => const Stream<void>.empty();
}

/// Supabase Realtime (`postgres_changes`) filtrado por `receptor_id`.
/// RLS `amistades_leer` limita los eventos a las filas del usuario.
class FuenteCambiosAmistadesSupabase implements FuenteCambiosAmistades {
  FuenteCambiosAmistadesSupabase({SupabaseClient? cliente})
    : _clienteInyectado = cliente;

  final SupabaseClient? _clienteInyectado;

  SupabaseClient get _cliente => _clienteInyectado ?? Supabase.instance.client;

  @override
  Stream<void> escuchar(String uidReceptor) {
    RealtimeChannel? canal;
    late final StreamController<void> controlador;
    controlador = StreamController<void>(
      onListen: () {
        canal = _cliente
            .channel('amistades-receptor-$uidReceptor')
            .onPostgresChanges(
              event: PostgresChangeEvent.all,
              schema: 'public',
              table: 'amistades',
              filter: PostgresChangeFilter(
                type: PostgresChangeFilterType.eq,
                column: 'receptor_id',
                value: uidReceptor,
              ),
              callback: (_) {
                if (!controlador.isClosed) controlador.add(null);
              },
            )
            .subscribe((estado, error) {
              if (error != null) {
                debugPrint('Capsoul: realtime de amistades: $estado $error');
              }
            });
      },
      onCancel: () async {
        final abierto = canal;
        canal = null;
        if (abierto != null) await _cliente.removeChannel(abierto);
      },
    );
    return controlador.stream;
  }
}
