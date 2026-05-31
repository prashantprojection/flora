import 'package:flutter/material.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return SliverAppBar.large(
      floating: true,
      pinned: true,
      expandedHeight: 180,
      backgroundColor: theme.colorScheme.surface,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 20, bottom: 20),
        title: Text(
          'My Garden',
          style: TextStyle(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [
                theme.colorScheme.primary.withValues(alpha: 0.1),
                theme.colorScheme.surface,
              ],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                top: 40,
                right: -20,
                child: Icon(
                  LucideIcons.sprout,
                  size: 150,
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
