import 'package:flutter/material.dart';
import 'package:flora/utils/app_theme.dart';

/// Short answer with tappable follow-up suggestion chips.
/// Rendered when the AI calls [render_quick_answers].
class QuickAnswersCard extends StatelessWidget {
  final Map<String, dynamic> data;

  /// Called when the user taps a suggestion chip — pre-fills the input bar.
  final ValueChanged<String>? onSuggestionTap;

  const QuickAnswersCard({super.key, required this.data, this.onSuggestionTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final answer = data['answer'] as String? ?? '';
    final suggestions =
        (data['suggestions'] as List?)?.map((e) => e.toString()).toList() ?? [];

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
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Answer text
              Text(
                answer,
                style: theme.textTheme.bodyMedium?.copyWith(
                  height: 1.5,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              if (suggestions.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  'You might also want to ask:',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppTheme.mutedForeground,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: suggestions
                      .map(
                        (s) => GestureDetector(
                          onTap: () => onSuggestionTap?.call(s),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: AppTheme.primary.withValues(alpha: 0.25),
                              ),
                            ),
                            child: Text(
                              s,
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: AppTheme.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
