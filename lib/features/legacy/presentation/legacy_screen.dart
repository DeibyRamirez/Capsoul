import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class LegacyScreen extends StatelessWidget {
  const LegacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mi legado')),
      body: Center(
        child: Text(
          'Tu legado se construye d\u00eda a d\u00eda',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.muted,
              ),
        ),
      ),
    );
  }
}