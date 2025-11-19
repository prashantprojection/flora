import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

class BottomNavBar extends StatelessWidget {
  const BottomNavBar({super.key});

  int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.toString();
    if (location == '/schedule') {
      return 1;
    }
    if (location == '/health-check') {
      return 2;
    }
    if (location == '/support') {
      return 3;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth > 600) {
      return const SizedBox.shrink(); // Hide on larger screens
    }

    return BottomNavigationBar(
      currentIndex: _calculateSelectedIndex(context),
      onTap: (int idx) {
        switch (idx) {
          case 0:
            context.go('/');
            break;
          case 1:
            context.go('/schedule');
            break;
          case 2:
            context.go('/health-check');
            break;
          case 3:
            context.go('/support');
            break;
        }
      },
      backgroundColor: Theme.of(context).colorScheme.surface, // Use card color
      selectedItemColor: Theme.of(context).colorScheme.primary,
      unselectedItemColor: Theme.of(context).colorScheme.onSurface.withAlpha(153),
      selectedLabelStyle: Theme.of(context).textTheme.labelSmall,
      unselectedLabelStyle: Theme.of(context).textTheme.labelSmall,
      type: BottomNavigationBarType.fixed,
      elevation: 1.0,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(LucideIcons.house),
          activeIcon: Icon(LucideIcons.house),
          label: 'Garden',
        ),
        BottomNavigationBarItem(
          icon: Icon(LucideIcons.calendarCheck),
          activeIcon: Icon(LucideIcons.calendarCheck),
          label: 'Schedule',
        ),
        BottomNavigationBarItem(
          icon: Icon(LucideIcons.heartPulse),
          activeIcon: Icon(LucideIcons.heartPulse),
          label: 'Health Check',
        ),
        BottomNavigationBarItem(
          icon: Icon(LucideIcons.gem),
          activeIcon: Icon(LucideIcons.gem),
          label: 'Support Us',
        ),
      ],
    );
  }
}