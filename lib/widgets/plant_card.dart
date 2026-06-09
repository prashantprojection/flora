import 'package:flora/utils/image_utils.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:flora/models/plant.dart';
import 'package:flora/models/care_event.dart';
import 'package:flora/utils/app_theme.dart';

class PlantCard extends StatelessWidget {
  final Plant plant;

  const PlantCard({super.key, required this.plant});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final wateringStatus = _getWateringStatus(plant);
    final statusColor = wateringStatus.color;
    final needsWater = wateringStatus.needsWater;

    return Semantics(
      label: '${plant.name}, ${wateringStatus.text}',
      button: true,
      child: Card(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        elevation: needsWater ? 4 : 2,
        shadowColor: needsWater
            ? theme.colorScheme.error.withValues(alpha: 0.3)
            : Colors.black12,
        child: InkWell(
          onTap: () => context.push('/plant/${plant.id}'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Image area with overlaid status pill ──
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Plant photo / placeholder
                    _buildImage(context, plant.imagePath),

                    // Gradient scrim at bottom of image for readability
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.35),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Status pill — overlaid bottom-left on the image
                    Positioned(
                      bottom: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.92),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: statusColor.withValues(alpha: 0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              wateringStatus.icon,
                              size: 11,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              wateringStatus.text,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // "!" urgent badge — top-right when needs water
                    if (needsWater)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.error,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: theme.colorScheme.error.withValues(
                                  alpha: 0.4,
                                ),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Text(
                              '!',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                height: 1,
                              ),
                            ),
                          ),
                        ),
                      ),
                    // Status/Stage badges
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (plant.status == PlantStatus.quarantine)
                            _buildTopLeftBadge(
                              theme,
                              'Quarantine',
                              Colors.amber.shade700,
                              LucideIcons.shieldAlert,
                            ),
                          if (plant.status == PlantStatus.givenAway ||
                              plant.status == PlantStatus.deceased)
                            _buildTopLeftBadge(
                              theme,
                              'Archived',
                              Colors.grey.shade700,
                              LucideIcons.archive,
                            ),
                          if (plant.stage == PlantStage.seedling)
                            _buildTopLeftBadge(
                              theme,
                              'Seedling',
                              Colors.green.shade600,
                              LucideIcons.sprout,
                            ),
                          if (plant.stage == PlantStage.cutting)
                            _buildTopLeftBadge(
                              theme,
                              'Cutting',
                              Colors.teal.shade600,
                              LucideIcons.scissors,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ── Text details ──
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plant.name,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (plant.species != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        plant.species!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontStyle: FontStyle.italic,
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (plant.location != null &&
                        plant.location!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            LucideIcons.mapPin,
                            size: 10,
                            color: theme.colorScheme.onSurfaceVariant
                                .withValues(alpha: 0.6),
                          ),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              plant.location!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant
                                    .withValues(alpha: 0.7),
                                fontSize: 10,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImage(BuildContext context, String? imagePath) {
    final theme = Theme.of(context);
    final placeholder = Container(
      color: AppTheme.muted,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              LucideIcons.flower2,
              size: 40,
              color: theme.colorScheme.primary.withValues(alpha: 0.35),
            ),
            const SizedBox(height: 4),
            Text(
              'No photo',
              style: TextStyle(
                fontSize: 10,
                color: theme.colorScheme.onSurfaceVariant.withValues(
                  alpha: 0.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (imagePath == null) return placeholder;

    if (imagePath.startsWith('http')) {
      return Image.network(
        imagePath,
        fit: BoxFit.cover,
        cacheWidth: 500,
        errorBuilder: (_, _, _) => placeholder,
      );
    }

    return buildImage(
      imagePath,
      fit: BoxFit.cover,
      cacheWidth: 500,
      errorBuilder: (_, _, _) => placeholder,
    );
  }

  Widget _buildTopLeftBadge(
    ThemeData theme,
    String text,
    Color color,
    IconData icon,
  ) {
    return Container(
      margin: const EdgeInsets.only(right: 4),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  static DateTime _startOfDay(DateTime date) =>
      DateTime.utc(date.year, date.month, date.day);

  ({String text, bool needsWater, Color color, IconData icon}) _getWateringStatus(Plant plant) {
    final today = _startOfDay(DateTime.now());
    final next = _startOfDay(plant.nextWatering);
    final days = next.difference(today).inDays;

    if (days < 0) {
      return (
        text: '${days.abs()}d overdue',
        needsWater: true,
        color: AppTheme.destructive,
        icon: LucideIcons.droplets,
      );
    } else if (days == 0) {
      return (
        text: 'Water today',
        needsWater: true,
        color: AppTheme.destructive,
        icon: LucideIcons.droplets,
      );
    } else if (days <= 2) {
      return (
        text: 'In ${days}d',
        needsWater: false,
        color: const Color(0xFFD97706),
        icon: LucideIcons.droplets,
      );
    }
    return (
      text: 'In ${days}d',
      needsWater: false,
      color: AppTheme.primary,
      icon: LucideIcons.droplets,
    );
  }
}
