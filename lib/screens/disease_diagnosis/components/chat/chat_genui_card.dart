import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import 'package:flora/utils/app_theme.dart';
import 'package:flora/models/llm_models.dart';
import 'package:flora/models/diagnosis_data.dart';
import 'package:flora/providers/diagnosis_session_provider.dart';
import 'package:flora/providers/diagnosis_provider.dart';
import 'package:flora/screens/disease_diagnosis/components/diagnosis_section_card.dart';
import 'package:flora/screens/disease_diagnosis/components/diagnosis_bullet_list.dart';

class ChatGenUiCard extends ConsumerWidget {
  final LlmMessage message;

  const ChatGenUiCard({super.key, required this.message});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    // Parse GenUI JSON string if it's a valid DiagnosisData object
    final data = message.text.contains('"diseaseName"')
        ? DiagnosisData.tryParse(message.text)
        : null;
    final isJson = data != null;

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16, right: 40),
        padding: isJson ? EdgeInsets.zero : const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isJson
              ? Colors.transparent
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomRight: Radius.circular(16),
            bottomLeft: Radius.circular(4),
          ),
        ),
        child: isJson
            ? _buildGenUiCard(context, ref, data)
            : MarkdownBody(
                data: message.text,
                styleSheet: MarkdownStyleSheet(
                  p: TextStyle(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 15,
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildGenUiCard(
    BuildContext context,
    WidgetRef ref,
    DiagnosisData data,
  ) {
    final state = ref.watch(diagnosisSessionProvider);
    final notifier = ref.read(diagnosisSessionProvider.notifier);
    final theme = Theme.of(context);

    // Find initial feedback if it exists for the current session
    bool? initialHelpful;
    if (state.currentRecordId != null) {
      final historyList = ref.watch(diagnosisHistoryProvider);
      final record = historyList
          .where((r) => r.id == state.currentRecordId)
          .firstOrNull;
      initialHelpful = record?.isHelpful;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color:
                      (data.severity.toLowerCase() == 'none' ||
                          data.diseaseName.toLowerCase().contains('healthy'))
                      ? Colors.green.withValues(alpha: 0.1)
                      : theme.colorScheme.errorContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  (data.severity.toLowerCase() == 'none' ||
                          data.diseaseName.toLowerCase().contains('healthy'))
                      ? LucideIcons.leaf
                      : LucideIcons.bug,
                  color:
                      (data.severity.toLowerCase() == 'none' ||
                          data.diseaseName.toLowerCase().contains('healthy'))
                      ? Colors.green
                      : theme.colorScheme.error,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.diseaseName,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppTheme.foreground,
                      ),
                    ),
                    if (!(data.severity.toLowerCase() == 'none' ||
                        data.diseaseName.toLowerCase().contains(
                          'healthy',
                        ))) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getSeverityColor(
                            data.severity,
                          ).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${data.severity} Severity',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: _getSeverityColor(data.severity),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (data.symptoms.isNotEmpty)
            DiagnosisSectionCard(
              icon: LucideIcons.info,
              title: 'Symptoms',
              color: AppTheme.primary,
              bg: AppTheme.primary,
              child: DiagnosisBulletList(
                items: data.symptoms,
                color: AppTheme.primary,
              ),
            ),
          const SizedBox(height: 16),
          if (data.causes.isNotEmpty)
            DiagnosisSectionCard(
              icon: LucideIcons.search,
              title: 'Causes',
              color: Colors.orange,
              bg: Colors.orange,
              child: DiagnosisBulletList(
                items: data.causes,
                color: Colors.orange,
              ),
            ),
          const SizedBox(height: 16),
          if (data.treatment.isNotEmpty)
            DiagnosisSectionCard(
              icon: LucideIcons.bandage,
              title: 'Treatment Plan',
              color: Colors.orange,
              bg: Colors.orange,
              child: DiagnosisBulletList(
                items: data.treatment,
                color: Colors.orange,
              ),
            ),
          const SizedBox(height: 16),
          if (data.prevention.isNotEmpty)
            DiagnosisSectionCard(
              icon: LucideIcons.shieldCheck,
              title: 'Prevention',
              color: Colors.green,
              bg: Colors.green,
              child: DiagnosisBulletList(
                items: data.prevention,
                color: Colors.green,
              ),
            ),
          if (data.additionalNotes != null &&
              data.additionalNotes!.isNotEmpty) ...[
            const SizedBox(height: 16),
            DiagnosisSectionCard(
              icon: LucideIcons.notebookPen,
              title: 'Notes',
              color: AppTheme.mutedForeground,
              bg: AppTheme.muted,
              child: Text(
                data.additionalNotes!,
                style: theme.textTheme.bodySmall?.copyWith(
                  height: 1.5,
                  color: AppTheme.foreground,
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // TTS Button
              IconButton(
                icon: Icon(
                  state.isSpeaking ? LucideIcons.square : LucideIcons.volume2,
                  color: state.isSpeaking
                      ? theme.colorScheme.primary
                      : AppTheme.mutedForeground,
                ),
                onPressed: notifier.speakDiagnosis,
                tooltip: state.isSpeaking
                    ? 'Stop audio'
                    : 'Listen to diagnosis',
              ),
              // Feedback Buttons
              Row(
                children: [
                  Text(
                    "Was this helpful?",
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.mutedForeground,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(
                      LucideIcons.thumbsUp,
                      size: 20,
                      color: initialHelpful == true
                          ? Colors.green
                          : AppTheme.mutedForeground,
                    ),
                    onPressed: () => notifier.provideFeedback(true),
                  ),
                  IconButton(
                    icon: Icon(
                      LucideIcons.thumbsDown,
                      size: 20,
                      color: initialHelpful == false
                          ? Colors.red
                          : AppTheme.mutedForeground,
                    ),
                    onPressed: () => notifier.provideFeedback(false),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'low':
        return Colors.amber;
      case 'medium':
        return Colors.orange;
      case 'high':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
