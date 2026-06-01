import 'package:flutter/material.dart';
import 'package:flora/widgets/animated_press.dart';

class DiagnosisFeedbackButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const DiagnosisFeedbackButton({
    super.key,
    required this.icon,
    required this.label,
    this.isSelected = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bgColor = isSelected 
        ? theme.colorScheme.primary.withValues(alpha: 0.15) 
        : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5);
    final borderColor = isSelected 
        ? theme.colorScheme.primary 
        : theme.colorScheme.outlineVariant.withValues(alpha: 0.5);
    final iconColor = isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant;
    final textColor = isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface;

    return AnimatedPress(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: iconColor),
            const SizedBox(width: 6),
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
