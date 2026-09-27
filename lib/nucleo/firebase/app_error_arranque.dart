import 'package:flutter/material.dart';

import '../tema/colores_app.dart';
import '../tema/tema_app.dart';

/// Se muestra cuando Firebase no se puede inicializar al arrancar.
class AppErrorArranque extends StatelessWidget {
  const AppErrorArranque({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Capsoul',
      debugShowCheckedModeBanner: false,
      theme: TemaApp.claro,
      home: const Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.cloud_off, size: 56, color: ColoresApp.acento),
                  SizedBox(height: 16),
                  Text(
                    'No pudimos iniciar Capsoul',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: ColoresApp.primario,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Revisa tu conexión y vuelve a abrir la app.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: ColoresApp.atenuado),
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
