import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';

/// Bottom navigation shell: Inicio | Momentos | + | Mi legado | Yo.
/// The center + opens Create (not a persistent tab branch).
class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  int get _navSelectedIndex {
    // Branch indices 0..3 map to nav slots 0,1,3,4 (slot 2 is Create).
    switch (navigationShell.currentIndex) {
      case 0:
        return 0;
      case 1:
        return 1;
      case 2:
        return 3;
      case 3:
        return 4;
      default:
        return 0;
    }
  }

  void _onDestinationSelected(BuildContext context, int index) {
    if (index == 2) {
      context.push('/create');
      return;
    }
    final branchIndex = switch (index) {
      0 => 0,
      1 => 1,
      3 => 2,
      4 => 3,
      _ => 0,
    };
    navigationShell.goBranch(
      branchIndex,
      initialLocation: branchIndex == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _navSelectedIndex,
        onDestinationSelected: (i) => _onDestinationSelected(context, i),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Inicio',
          ),
          const NavigationDestination(
            icon: Icon(Icons.auto_stories_outlined),
            selectedIcon: Icon(Icons.auto_stories),
            label: 'Momentos',
          ),
          NavigationDestination(
            icon: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              ),
              child: const Icon(Icons.add, color: AppColors.onPrimary),
            ),
            label: '+',
          ),
          const NavigationDestination(
            icon: Icon(Icons.account_balance_outlined),
            selectedIcon: Icon(Icons.account_balance),
            label: 'Mi legado',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Yo',
          ),
        ],
      ),
    );
  }
}