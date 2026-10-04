import 'package:flutter/material.dart';

import '../tema/colores_app.dart';
import '../tema/tema_app.dart';

/// Mensaje por defecto de la pantalla de error de arranque.
const String kMensajeErrorArranque =
    'Revisa tu conexión y vuelve a abrir la app.';

/// Se muestra cuando la app no puede arrancar (p. ej. falta la configuración
/// de Supabase o el servidor no responde).
class AppErrorArranque extends StatelessWidget {
  const AppErrorArranque({super.key, this.detalle});

  /// Explicación en español; si es `null` se usa [kMensajeErrorArranque].
  final String? detalle;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Capsoul',
      debugShowCheckedModeBanner: false,
      theme: TemaApp.claro,
      home: Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.cloud_off,
                    size: 56,
                    color: ColoresApp.acento,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No pudimos iniciar Capsoul',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: ColoresApp.primario,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    detalle ?? kMensajeErrorArranque,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: ColoresApp.atenuado),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
