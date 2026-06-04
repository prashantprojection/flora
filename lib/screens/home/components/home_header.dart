import 'package:flutter/material.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:flora/utils/app_theme.dart';

class HomeHeader extends StatelessWidget {
  final String greeting;
  final String mascotPath;

  const HomeHeader({
    super.key,
    required this.greeting,
    required this.mascotPath,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SliverAppBar.large(
      floating: true,
      pinned: true,
      expandedHeight: 200,
      backgroundColor: theme.colorScheme.surface,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              greeting,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              'My Garden',
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),
          ],
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [
                AppTheme.primary.withValues(alpha: 0.12),
                AppTheme.accent.withValues(alpha: 0.05),
                theme.colorScheme.surface,
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Decorative background ring
              Positioned(
                top: -20,
                right: -40,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.primary.withValues(alpha: 0.06),
                  ),
                ),
              ),
              // Flo mascot illustration in the header
              Positioned(
                bottom: 8,
                right: 16,
                child: SizedBox(
                  height: 140,
                  child: Image.asset(
                    mascotPath,
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => Icon(
                      LucideIcons.sprout,
                      size: 120,
                      color: AppTheme.primary.withValues(alpha: 0.1),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
