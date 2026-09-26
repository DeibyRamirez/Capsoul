import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';

class CreateSelectorScreen extends StatelessWidget {
  const CreateSelectorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _CreateOption(
            icon: Icons.videocam_outlined,
            title: 'Video',
            subtitle: 'Graba un recuerdo en video',
            onTap: () => context.push('/create/video'),
          ),
          _CreateOption(
            icon: Icons.mic_none_outlined,
            title: 'Audio',
            subtitle: 'Deja un mensaje de voz',
            onTap: () => context.push('/create/audio'),
          ),
          _CreateOption(
            icon: Icons.edit_outlined,
            title: 'Escribir',
            subtitle: 'Escribe una nota o carta',
            onTap: () => context.push('/create/escribir'),
          ),
          _CreateOption(
            icon: Icons.photo_outlined,
            title: 'Foto',
            subtitle: 'Guarda una imagen especial',
            onTap: () => context.push('/create/foto'),
          ),
        ],
      ),
    );
  }
}

class _CreateOption extends StatelessWidget {
  const _CreateOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
        leading: CircleAvatar(
          backgroundColor: AppColors.accent.withValues(alpha: 0.15),
          foregroundColor: AppColors.primary,
          child: Icon(icon),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: AppColors.onSurface,
          ),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right, color: AppColors.muted),
        onTap: onTap,
      ),
    );
  }
}

/// Placeholder for a specific create modality (Video / Audio / Escribir / Foto).
class CreatePlaceholderScreen extends StatelessWidget {
  const CreatePlaceholderScreen({super.key, required this.modality});

  final String modality;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(modality)),
      body: Center(
        child: Text(
          'Pr\u00f3ximamente: $modality',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.muted,
              ),
        ),
      ),
    );
  }
}