import 'dart:io';
import 'package:flutter/material.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:flora/services/platform_share_service.dart';
import 'package:flora/utils/app_theme.dart';
import 'package:flora/screens/disease_diagnosis/components/diagnosis_section_card.dart';
import 'package:flora/screens/disease_diagnosis/components/diagnosis_bullet_list.dart';
import 'package:flora/screens/disease_diagnosis/components/diagnosis_feedback_button.dart';

class DiagnosisResultView extends StatelessWidget {
  final File? selectedImage;
  final String diagnosisResult;
  final bool isSpeaking;
  final VoidCallback onSpeak;
  final VoidCallback onReset;

  const DiagnosisResultView({
    super.key,
    required this.selectedImage,
    required this.diagnosisResult,
    required this.isSpeaking,
    required this.onSpeak,
    required this.onReset,
  });

  // ── Parsing helpers ─────────────────────────────────────────────────────────

  String? _extractSection(String text, String heading) {
    final regex = RegExp(
      r'##\s*' + RegExp.escape(heading) + r'[\s\S]*?\n([\s\S]*?)(?=\n##|\s*$)',
      caseSensitive: false,
    );
    final match = regex.firstMatch(text);
    return match?.group(1)?.trim();
  }

  String? _extractInlineValue(String text, String heading) {
    final regex = RegExp(
      r'##\s*' + RegExp.escape(heading) + r'[\s\S]*?\*\*(.*?)\*\*',
      caseSensitive: false,
    );
    return regex.firstMatch(text)?.group(1)?.trim();
  }

  /// Parse bullet points / numbered list into clean strings.
  List<String> _parseBullets(String? raw) {
    if (raw == null || raw.trim().isEmpty) return [];
    return raw
        .split('\n')
        .map((l) => l.replaceAll(RegExp(r'^[\s*\-•\d\.]+'), '').trim())
        .where((l) => l.isNotEmpty)
        .toList();
  }

  // ── Severity parsing ────────────────────────────────────────────────────────

  ({String label, Color color, Color bg, IconData icon}) _severity() {
    final raw = _extractInlineValue(diagnosisResult, 'Severity') ?? '';
    final sev = raw.toLowerCase();
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
    }
    return (
      label: 'Unknown',
      color: Colors.grey.shade700,
      bg: Colors.grey.shade100,
      icon: LucideIcons.circleAlert,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sev = _severity();

    // Extract named disease / health condition from the first ## heading or first bold
    final nameMatch = RegExp(r'##\s*(.+)').firstMatch(diagnosisResult);
    final diseaseName = nameMatch?.group(1)?.trim() ?? "Plant Analysis";

    final symptoms = _parseBullets(_extractSection(diagnosisResult, 'Symptoms'));
    final causes = _parseBullets(_extractSection(diagnosisResult, 'Cause'));
    final treatment = _parseBullets(_extractSection(diagnosisResult, 'Treatment'));
    final prevention = _parseBullets(_extractSection(diagnosisResult, 'Prevention'));
    final additionalNotes = _extractSection(diagnosisResult, 'Additional Notes') ??
        _extractSection(diagnosisResult, 'Notes');

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Image Hero AppBar ───────────────────────────────────────
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
              onPressed: onReset,
            ),
            actions: [
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.35),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isSpeaking ? Icons.stop_circle_outlined : LucideIcons.volume2,
                    size: 18,
                    color: Colors.white,
                  ),
                ),
                onPressed: onSpeak,
                tooltip: isSpeaking ? 'Stop' : 'Listen',
              ),
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.35),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(LucideIcons.share2, size: 18, color: Colors.white),
                ),
                onPressed: () {
                  if (selectedImage != null) {
                    PlatformShareService.shareFiles(
                      [selectedImage!.path],
                      text: 'Flora Diagnosis Report:\n\n$diagnosisResult',
                    );
                  }
                },
              ),
            ],
            flexibleSpace: selectedImage != null
                ? FlexibleSpaceBar(
                    background: RepaintBoundary(
                      child: selectedImage!.existsSync()
                          ? Image.file(
                              selectedImage!,
                              fit: BoxFit.cover,
                              cacheWidth: 800,
                              errorBuilder: (_, __, ___) =>
                                  _imagePlaceholder(context),
                            )
                          : _imagePlaceholder(context),
                    ),
                  )
                : null,
          ),

          // ── Content ─────────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ── Disease name + severity badge ────────────────────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        diseaseName,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.foreground,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: sev.bg,
                        borderRadius: BorderRadius.circular(50),
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
                    const Icon(LucideIcons.bot, size: 13,
                        color: AppTheme.mutedForeground),
                    const SizedBox(width: 4),
                    Text(
                      "Flo AI Analysis",
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppTheme.mutedForeground,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // ── Symptoms ─────────────────────────────────────────
                if (symptoms.isNotEmpty) ...[
                  DiagnosisSectionCard(
                    icon: LucideIcons.microscope,
                    title: 'Symptoms',
                    color: const Color(0xFF7B1FA2),
                    bg: const Color(0xFFF3E5F5),
                    child: DiagnosisBulletList(items: symptoms, color: const Color(0xFF7B1FA2)),
                  ),
                  const SizedBox(height: 12),
                ],

                // ── Cause ────────────────────────────────────────────
                if (causes.isNotEmpty) ...[
                  DiagnosisSectionCard(
                    icon: LucideIcons.searchCode,
                    title: 'Cause',
                    color: const Color(0xFFBF360C),
                    bg: const Color(0xFFFBE9E7),
                    child: DiagnosisBulletList(items: causes, color: const Color(0xFFBF360C)),
                  ),
                  const SizedBox(height: 12),
                ],

                // ── Treatment ────────────────────────────────────────
                if (treatment.isNotEmpty) ...[
                  DiagnosisSectionCard(
                    icon: LucideIcons.stethoscope,
                    title: 'Treatment',
                    color: const Color(0xFF1B5E20),
                    bg: const Color(0xFFE8F5E9),
                    child: DiagnosisBulletList(items: treatment, color: const Color(0xFF1B5E20)),
                  ),
                  const SizedBox(height: 12),
                ],

                // ── Prevention ───────────────────────────────────────
                if (prevention.isNotEmpty) ...[
                  DiagnosisSectionCard(
                    icon: LucideIcons.shieldCheck,
                    title: 'Prevention',
                    color: const Color(0xFF01579B),
                    bg: const Color(0xFFE3F2FD),
                    child: DiagnosisBulletList(items: prevention, color: const Color(0xFF01579B)),
                  ),
                  const SizedBox(height: 12),
                ],

                // ── Additional Notes (fallback raw text) ─────────────
                if (additionalNotes != null && additionalNotes.isNotEmpty) ...[
                  DiagnosisSectionCard(
                    icon: LucideIcons.notebookPen,
                    title: 'Additional Notes',
                    color: AppTheme.mutedForeground,
                    bg: AppTheme.muted,
                    child: Text(
                      additionalNotes,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        height: 1.55,
                        color: AppTheme.foreground,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // ── Feedback + Reset ─────────────────────────────────
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
                const _DiagnosisFeedbackSection(),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: onReset,
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
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _imagePlaceholder(BuildContext context) {
    return Container(
      color: AppTheme.muted,
      child: const Center(
        child: Icon(
          LucideIcons.imageOff,
          size: 48,
          color: AppTheme.mutedForeground,
        ),
      ),
    );
  }
}

class _DiagnosisFeedbackSection extends StatefulWidget {
  const _DiagnosisFeedbackSection();

  @override
  State<_DiagnosisFeedbackSection> createState() => _DiagnosisFeedbackSectionState();
}

class _DiagnosisFeedbackSectionState extends State<_DiagnosisFeedbackSection> {
  int _selectedFeedback = 0; // 0 = none, 1 = helpful, 2 = not quite

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        DiagnosisFeedbackButton(
          icon: LucideIcons.thumbsUp,
          label: 'Helpful',
          isSelected: _selectedFeedback == 1,
          onTap: () {
            setState(() => _selectedFeedback = 1);
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
          isSelected: _selectedFeedback == 2,
          onTap: () {
            setState(() => _selectedFeedback = 2);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Thanks for the feedback! We'll improve Dr. Flo."),
                duration: Duration(seconds: 2),
              ),
            );
          },
        ),
      ],
    );
  }
}


