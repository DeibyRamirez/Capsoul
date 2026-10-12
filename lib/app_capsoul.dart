import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'nucleo/enrutador/enrutador_app.dart';
import 'nucleo/enlaces/escucha_enlaces_app.dart';
import 'nucleo/firebase/escucha_tokens_push.dart';
import 'nucleo/tema/tema_app.dart';

/// Widget raíz de Capsoul: MaterialApp con go_router y el tema de marca.
class AppCapsoul extends ConsumerWidget {
  const AppCapsoul({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enrutador = ref.watch(proveedorEnrutadorApp);
    final app = MaterialApp.router(
      title: 'Capsoul',
      debugShowCheckedModeBanner: false,
      theme: TemaApp.claro,
      // Textos de Material (selector de fecha, tooltips) en español.
      locale: const Locale('es', 'CO'),
      supportedLocales: const [Locale('es', 'CO'), Locale('es')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      routerConfig: enrutador,
    );
    final enPrueba =
        !kIsWeb && Platform.environment['FLUTTER_TEST'] == 'true';
    if (enPrueba) return app;
    return EscuchaTokensPush(
      child: EscuchaEnlacesApp(child: app),
    );
  }
}
