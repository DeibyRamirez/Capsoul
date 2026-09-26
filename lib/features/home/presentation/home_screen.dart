import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Hola',
                style: textTheme.headlineMedium?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Bienvenido a Capsoul',
                style: textTheme.titleMedium?.copyWith(
                  color: AppColors.muted,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Peque\u00f1as herencias, grandes recuerdos',
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.accent,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const Spacer(),
              const _GlassDomePlaceholder(),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

class _GlassDomePlaceholder extends StatelessWidget {
  const _GlassDomePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 220,
        height: 220,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.accent.withValues(alpha: 0.35),
              AppColors.primary.withValues(alpha: 0.55),
              AppColors.primary,
            ],
          ),
          border: Border.all(
            color: AppColors.domeBorder,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.25),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Container(
          margin: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.domeGlass,
            border: Border.all(
              color: AppColors.onPrimary.withValues(alpha: 0.35),
            ),
          ),
          child: const Center(
            child: Icon(
              Icons.auto_awesome,
              color: AppColors.onPrimary,
              size: 48,
            ),
          ),
        ),
      ),
    );
  }
}