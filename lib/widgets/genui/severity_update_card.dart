import 'package:flutter/material.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:flora/utils/app_theme.dart';

/// Severity update card rendered when the AI calls [render_severity_update].
/// Shows the transition from old to new severity with color-coded badges.
class SeverityUpdateCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const SeverityUpdateCard({super.key, required this.data});

  Color _severityColor(String? sev) {
    switch (sev?.toLowerCase()) {
      case 'low':
        return const Color(0xFF2E7D32);
      case 'medium':
        return const Color(0xFFE65100);
      case 'high':
        return const Color(0xFFC62828);
      case 'none':
        return const Color(0xFF1B5E20);
      default:
        return Colors.grey.shade700;
    }
  }

  IconData _severityIcon(String? sev) {
    switch (sev?.toLowerCase()) {
      case 'low':
        return LucideIcons.shieldCheck;
      case 'medium':
        return LucideIcons.triangleAlert;
      case 'high':
        return LucideIcons.octagonAlert;
      case 'none':
        return LucideIcons.leaf;
      default:
        return LucideIcons.circleAlert;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final prev = data['previousSeverity'] as String? ?? 'Unknown';
    final updated = data['updatedSeverity'] as String? ?? 'Unknown';
    final reason = data['reason'] as String? ?? '';
    final urgentAction = data['urgentAction'] as String? ?? '';

    final prevColor = _severityColor(prev);
    final updatedColor = _severityColor(updated);

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16, right: 24),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Text(
                'Severity Update',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              // Before → After badges
              Row(
                children: [
                  _SeverityBadge(
                    label: prev,
                    color: prevColor,
                    icon: _severityIcon(prev),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Icon(
                      LucideIcons.arrowRight,
                      size: 16,
                      color: AppTheme.mutedForeground,
                    ),
                  ),
                  _SeverityBadge(
                    label: updated,
                    color: updatedColor,
                    icon: _severityIcon(updated),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Reason
              if (reason.isNotEmpty) ...[
                Text(
                  reason,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    height: 1.4,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 10),
              ],

              // Urgent action callout
              if (urgentAction.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: updatedColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: updatedColor.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(LucideIcons.zap, size: 15, color: updatedColor),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          urgentAction,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: updatedColor,
                            fontWeight: FontWeight.w600,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SeverityBadge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;

  const _SeverityBadge({
    required this.label,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
