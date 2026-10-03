import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'nucleo/enrutador/enrutador_app.dart';
import 'nucleo/tema/tema_app.dart';

/// Widget raíz de Capsoul: MaterialApp con go_router y el tema de marca.
class AppCapsoul extends ConsumerWidget {
  const AppCapsoul({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enrutador = ref.watch(proveedorEnrutadorApp);
    return MaterialApp.router(
      title: 'Capsoul',
      debugShowCheckedModeBanner: false,
      theme: TemaApp.claro,
      // Textos de Material (selector de fecha, tooltips) en español.
      locale: const Locale('es', 'CO'),
      supportedLocales: const [Locale('es', 'CO'), Locale('es')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      routerConfig: enrutador,
    );
  }
}
