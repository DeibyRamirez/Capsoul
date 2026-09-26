import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

class CapsoulApp extends StatefulWidget {
  const CapsoulApp({super.key, this.router});

  /// Optional router override for tests.
  final GoRouter? router;

  @override
  State<CapsoulApp> createState() => _CapsoulAppState();
}

class _CapsoulAppState extends State<CapsoulApp> {
  late final GoRouter _router = widget.router ?? createAppRouter();

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Capsoul',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: _router,
    );
  }
}