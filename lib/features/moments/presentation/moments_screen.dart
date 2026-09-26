import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class MomentsScreen extends StatelessWidget {
  const MomentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Momentos')),
      body: Center(
        child: Text(
          'Tus momentos aparecer\u00e1n aqu\u00ed',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.muted,
              ),
        ),
      ),
    );
  }
}