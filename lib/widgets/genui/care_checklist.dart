import 'package:flutter/material.dart';
import 'package:flora/utils/app_theme.dart';

/// Interactive care step checklist rendered when the AI calls [render_care_checklist].
/// Steps persist their checked state for the lifetime of the widget.
class CareChecklist extends StatefulWidget {
  final Map<String, dynamic> data;
  const CareChecklist({super.key, required this.data});

  @override
  State<CareChecklist> createState() => _CareChecklistState();
}

class _CareChecklistState extends State<CareChecklist> {
  late final List<bool> _checked;

  @override
  void initState() {
    super.initState();
    final steps = widget.data['steps'] as List? ?? [];
    _checked = List.filled(steps.length, false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = widget.data['title'] as String? ?? 'Care Plan';
    final steps =
        (widget.data['steps'] as List?)?.map((e) => e.toString()).toList() ??
        [];

    final completedCount = _checked.where((c) => c).length;
    final progress = steps.isEmpty ? 0.0 : completedCount / steps.length;

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
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Text(
                    '$completedCount/${steps.length}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppTheme.mutedForeground,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  color: AppTheme.primary,
                  minHeight: 4,
                ),
              ),
              const SizedBox(height: 12),
              ...List.generate(steps.length, (i) {
                return InkWell(
                  onTap: () => setState(() => _checked[i] = !_checked[i]),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _checked[i]
                                ? AppTheme.primary
                                : Colors.transparent,
                            border: Border.all(
                              color: _checked[i]
                                  ? AppTheme.primary
                                  : AppTheme.border,
                              width: 1.5,
                            ),
                          ),
                          child: _checked[i]
                              ? const Icon(
                                  Icons.check,
                                  size: 13,
                                  color: Colors.white,
                                )
                              : null,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            steps[i],
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: _checked[i]
                                  ? AppTheme.mutedForeground
                                  : theme.colorScheme.onSurface,
                              decoration: _checked[i]
                                  ? TextDecoration.lineThrough
                                  : null,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}
