import 'package:image_picker/image_picker.dart';
import 'package:flora/utils/image_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

import 'package:flora/utils/app_theme.dart';
import 'package:flora/models/diagnosis_data.dart';
import 'package:flora/providers/diagnosis_session_provider.dart';
import 'package:flora/providers/diagnosis_provider.dart';
import 'package:flora/services/platform_share_service.dart';
import 'package:flora/screens/disease_diagnosis/components/diagnosis_section_card.dart';
import 'package:flora/screens/disease_diagnosis/components/diagnosis_bullet_list.dart';
import 'package:flora/screens/disease_diagnosis/components/diagnosis_feedback_button.dart';
import 'package:flora/screens/disease_diagnosis/components/diagnosis_chat_screen.dart';

class DiagnosisResultView extends ConsumerStatefulWidget {
  const DiagnosisResultView({super.key});

  @override
  ConsumerState<DiagnosisResultView> createState() =>
      _DiagnosisResultViewState();
}

class _DiagnosisResultViewState extends ConsumerState<DiagnosisResultView> {
  final TextEditingController _inputController = TextEditingController();
  final FocusNode _inputFocusNode = FocusNode();

  @override
  void dispose() {
    _inputController.dispose();
    _inputFocusNode.dispose();
    super.dispose();
  }

  Future<void> _sendFirstFollowUp() async {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;

    _inputController.clear();
    _inputFocusNode.unfocus();

    // Send the first follow-up — this populates chatHistory[2]
    await ref.read(diagnosisSessionProvider.notifier).sendFollowUp(text);

    // Push the chat screen only after the first message is sent
    if (mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const DiagnosisChatScreen()),
      );
    }
  }

  Future<void> _openExistingChat() async {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const DiagnosisChatScreen()),
    );
  }

  ({String label, Color color, Color bg, IconData icon}) _severity(
      DiagnosisData data) {
    final sev = data.severity.toLowerCase();
    if (sev == 'low') {
      return (
        label: 'Low Severity',
        color: const Color(0xFF2E7D32),
        bg: const Color(0xFFE8F5E9),
        icon: LucideIcons.shieldCheck,
      );
    } else if (sev == 'medium') {
      return (
        label: 'Medium Severity',
        color: const Color(0xFFE65100),
        bg: const Color(0xFFFFF3E0),
        icon: LucideIcons.triangleAlert,
      );
    } else if (sev.contains('high') || sev.contains('severe')) {
      return (
        label: 'High Severity',
        color: const Color(0xFFC62828),
        bg: const Color(0xFFFFEBEE),
        icon: LucideIcons.octagonAlert,
      );
    } else if (sev == 'none') {
      return (
        label: 'Healthy',
        color: const Color(0xFF1B5E20),
        bg: const Color(0xFFE8F5E9),
        icon: LucideIcons.leaf,
      );
    }
    return (
      label: 'Analysed',
      color: Colors.grey.shade700,
      bg: Colors.grey.shade100,
      icon: LucideIcons.circleAlert,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(diagnosisSessionProvider);
    final notifier = ref.read(diagnosisSessionProvider.notifier);
    final data = state.diagnosisResult;
    final theme = Theme.of(context);

    if (data == null) {
      // Fallback — should never reach here in normal flow
      return const SizedBox.shrink();
    }

    final sev = _severity(data);
    final selectedImage = state.selectedImage;

    // Feedback from history
    bool? initialFeedback;
    if (state.currentRecordId != null) {
      final historyList = ref.watch(diagnosisHistoryProvider);
      final record = historyList
          .where((r) => r.id == state.currentRecordId)
          .firstOrNull;
      initialFeedback = record?.isHelpful;
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Hero Image AppBar ─────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: selectedImage != null ? 260 : 0,
            pinned: true,
            backgroundColor: AppTheme.background,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.35),
                  shape: BoxShape.circle,
                ),
                child: const Icon(LucideIcons.x, size: 18, color: Colors.white),
              ),
              onPressed: notifier.resetState,
            ),
            actions: [
              // TTS
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.35),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    state.isSpeaking
                        ? Icons.stop_circle_outlined
                        : LucideIcons.volume2,
                    size: 18,
                    color: Colors.white,
                  ),
                ),
                onPressed: notifier.speakDiagnosis,
              ),
              // Share
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.35),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(LucideIcons.share2,
                      size: 18, color: Colors.white),
                ),
                onPressed: () {
                  if (selectedImage != null) {
                    final report = StringBuffer();
                    report.writeln('Flora Diagnosis: ${data.diseaseName}');
                    report.writeln('Severity: ${data.severity}');
                    if (data.treatment.isNotEmpty) {
                      report.writeln('\nTreatment:');
                      for (final t in data.treatment) {
                        report.writeln('- $t');
                      }
                    }
                    PlatformShareService.shareFiles(
                      [selectedImage.path],
                      text: report.toString(),
                    );
                  }
                },
              ),
              const SizedBox(width: 8),
            ],
            flexibleSpace: selectedImage != null
                ? FlexibleSpaceBar(
                    background: buildImage(
                      selectedImage.path,
                      fit: BoxFit.cover,
                      cacheWidth: 800,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: AppTheme.muted,
                        child: const Center(
                          child: Icon(LucideIcons.imageOff,
                              size: 48, color: AppTheme.mutedForeground),
                        ),
                      ),
                    ),
                  )
                : null,
          ),

          // ── Content ───────────────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Disease name + severity
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        data.diseaseName,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.foreground,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: sev.bg,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(sev.icon, size: 13, color: sev.color),
                          const SizedBox(width: 4),
                          Text(
                            sev.label,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: sev.color,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(LucideIcons.bot,
                        size: 13, color: AppTheme.mutedForeground),
                    const SizedBox(width: 4),
                    Text(
                      'Flo AI Analysis',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppTheme.mutedForeground,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // ── Symptoms ─────────────────────────────────────────────────
                if (data.symptoms.isNotEmpty) ...[
                  DiagnosisSectionCard(
                    icon: LucideIcons.microscope,
                    title: 'Symptoms',
                    color: const Color(0xFF7B1FA2),
                    bg: const Color(0xFFF3E5F5),
                    child: DiagnosisBulletList(
                        items: data.symptoms,
                        color: const Color(0xFF7B1FA2)),
                  ),
                  const SizedBox(height: 12),
                ],

                // ── Cause ────────────────────────────────────────────────────
                if (data.causes.isNotEmpty) ...[
                  DiagnosisSectionCard(
                    icon: LucideIcons.searchCode,
                    title: 'Cause',
                    color: const Color(0xFFBF360C),
                    bg: const Color(0xFFFBE9E7),
                    child: DiagnosisBulletList(
                        items: data.causes,
                        color: const Color(0xFFBF360C)),
                  ),
                  const SizedBox(height: 12),
                ],

                // ── Treatment ─────────────────────────────────────────────────
                if (data.treatment.isNotEmpty) ...[
                  DiagnosisSectionCard(
                    icon: LucideIcons.stethoscope,
                    title: 'Treatment',
                    color: const Color(0xFF1B5E20),
                    bg: const Color(0xFFE8F5E9),
                    child: DiagnosisBulletList(
                        items: data.treatment,
                        color: const Color(0xFF1B5E20)),
                  ),
                  const SizedBox(height: 12),
                ],

                // ── Prevention ────────────────────────────────────────────────
                if (data.prevention.isNotEmpty) ...[
                  DiagnosisSectionCard(
                    icon: LucideIcons.shieldCheck,
                    title: 'Prevention',
                    color: const Color(0xFF01579B),
                    bg: const Color(0xFFE3F2FD),
                    child: DiagnosisBulletList(
                        items: data.prevention,
                        color: const Color(0xFF01579B)),
                  ),
                  const SizedBox(height: 12),
                ],

                // ── Additional Notes ──────────────────────────────────────────
                if (data.additionalNotes != null &&
                    data.additionalNotes!.isNotEmpty) ...[
                  DiagnosisSectionCard(
                    icon: LucideIcons.notebookPen,
                    title: 'Additional Notes',
                    color: AppTheme.mutedForeground,
                    bg: AppTheme.muted,
                    child: Text(
                      data.additionalNotes!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        height: 1.55,
                        color: AppTheme.foreground,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // ── Feedback ──────────────────────────────────────────────────
                const SizedBox(height: 8),
                const Divider(),
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    'Was this diagnosis helpful?',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _FeedbackRow(
                  initialFeedback: initialFeedback,
                  onFeedback: notifier.provideFeedback,
                ),
                const SizedBox(height: 20),

                // ── Scan Another ──────────────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: notifier.resetState,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: const Icon(LucideIcons.scan, size: 18),
                    label: const Text(
                      'Scan Another Plant',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),

                // Bottom padding to make room for the sticky input bar
                const SizedBox(height: 100),
              ]),
            ),
          ),
        ],
      ),

      // ── Sticky Follow-up Input Bar ─────────────────────────────────────────
      bottomNavigationBar: _FollowUpInputBar(
        controller: _inputController,
        focusNode: _inputFocusNode,
        hasExistingChat: state.hasFollowUps,
        isLoading: state.isLoading,
        pendingAttachment: state.pendingAttachment,
        onPickAttachment: notifier.pickAttachment,
        onClearAttachment: notifier.clearAttachment,
        onSend: _sendFirstFollowUp,
        onOpenChat: _openExistingChat,
      ),
    );
  }
}

// ── Sticky Follow-up Input Bar ────────────────────────────────────────────────

class _FollowUpInputBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool hasExistingChat;
  final bool isLoading;
  final XFile? pendingAttachment;
  final VoidCallback onPickAttachment;
  final VoidCallback onClearAttachment;
  final VoidCallback onSend;
  final VoidCallback onOpenChat;

  const _FollowUpInputBar({
    required this.controller,
    required this.focusNode,
    required this.hasExistingChat,
    required this.isLoading,
    required this.pendingAttachment,
    required this.onPickAttachment,
    required this.onClearAttachment,
    required this.onSend,
    required this.onOpenChat,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          border:
              Border(top: BorderSide(color: AppTheme.border, width: 0.5)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // "Continue conversation" chip — shown only if chat already exists
            if (hasExistingChat)
              Padding(
                padding:
                    const EdgeInsets.only(top: 8, left: 16, right: 16),
                child: GestureDetector(
                  onTap: onOpenChat,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: AppTheme.primary.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        Icon(LucideIcons.messageCircle,
                            size: 15, color: AppTheme.primary),
                        const SizedBox(width: 8),
                        Text(
                          'Continue conversation with Dr. Flo →',
                          style:
                              theme.textTheme.labelMedium?.copyWith(
                            color: AppTheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // Attachment preview
            if (pendingAttachment != null)
              Padding(
                padding:
                    const EdgeInsets.only(top: 8, left: 16, right: 16),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: buildImage(
                        pendingAttachment!.path,
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Image attached',
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: AppTheme.mutedForeground),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(LucideIcons.x, size: 18),
                      onPressed: onClearAttachment,
                      color: AppTheme.mutedForeground,
                    ),
                  ],
                ),
              ),

            // Input row
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              child: Row(
                children: [
                  // Attach image button
                  IconButton(
                    icon: Icon(
                      LucideIcons.paperclip,
                      color: pendingAttachment != null
                          ? AppTheme.primary
                          : AppTheme.mutedForeground,
                      size: 20,
                    ),
                    onPressed: isLoading ? null : onPickAttachment,
                    tooltip: 'Attach image',
                  ),
                  // Text field
                  Expanded(
                    child: TextField(
                      controller: controller,
                      focusNode: focusNode,
                      enabled: !isLoading,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => onSend(),
                      decoration: InputDecoration(
                        hintText: hasExistingChat
                            ? 'Ask Dr. Flo another question...'
                            : 'Ask Dr. Flo a follow-up question...',
                        hintStyle: TextStyle(
                          color: AppTheme.mutedForeground
                              .withValues(alpha: 0.7),
                          fontSize: 14,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: theme.colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.5),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Send button
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    child: IconButton(
                      icon: isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(LucideIcons.sendHorizontal),
                      color: AppTheme.primary,
                      onPressed: isLoading ? null : onSend,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Feedback Row ──────────────────────────────────────────────────────────────

class _FeedbackRow extends StatefulWidget {
  final bool? initialFeedback;
  final ValueChanged<bool> onFeedback;

  const _FeedbackRow({required this.initialFeedback, required this.onFeedback});

  @override
  State<_FeedbackRow> createState() => _FeedbackRowState();
}

class _FeedbackRowState extends State<_FeedbackRow> {
  int _selected = 0; // 0=none, 1=helpful, 2=not quite

  @override
  void initState() {
    super.initState();
    if (widget.initialFeedback == true) _selected = 1;
    if (widget.initialFeedback == false) _selected = 2;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        DiagnosisFeedbackButton(
          icon: LucideIcons.thumbsUp,
          label: 'Helpful',
          isSelected: _selected == 1,
          onTap: () {
            setState(() => _selected = 1);
            widget.onFeedback(true);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Thanks! Flo will keep improving 🌿'),
                duration: Duration(seconds: 2),
              ),
            );
          },
        ),
        const SizedBox(width: 12),
        DiagnosisFeedbackButton(
          icon: LucideIcons.thumbsDown,
          label: 'Not quite',
          isSelected: _selected == 2,
          onTap: () {
            setState(() => _selected = 2);
            widget.onFeedback(false);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content:
                    Text("Thanks for the feedback! We'll improve Dr. Flo."),
                duration: Duration(seconds: 2),
              ),
            );
          },
        ),
      ],
    );
  }
}
