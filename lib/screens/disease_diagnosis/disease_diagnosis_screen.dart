import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flora/providers/diagnosis_session_provider.dart';
import 'package:flora/screens/disease_diagnosis/components/diagnosis_selection_view.dart';
import 'package:flora/screens/disease_diagnosis/components/diagnosis_preview_view.dart';
import 'package:flora/screens/disease_diagnosis/components/diagnosis_result_view.dart';
import 'package:flora/screens/disease_diagnosis/components/diagnosis_history_sheet.dart';

/// Root screen for the diagnosis feature.
/// Routes between the three main states:
///   1. No image → selection + history sheet
///   2. Image picked, diagnosis pending → preview
///   3. Diagnosis complete → result view (with lazy follow-up chat on top)
///
/// [DiagnosisChatScreen] is NEVER embedded here — it is pushed imperatively
/// from [DiagnosisResultView] so it stays off the widget tree until needed.
class DiseaseDiagnosisScreen extends ConsumerWidget {
  const DiseaseDiagnosisScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(diagnosisSessionProvider);
    final notifier = ref.read(diagnosisSessionProvider.notifier);

    // Show snack bar on errors and auto-clear them from state
    ref.listen(diagnosisSessionProvider.select((s) => s.error), (prev, error) {
      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error),
            backgroundColor: Colors.redAccent,
          ),
        );
        notifier.clearError();
      }
    });

    // ── Routing ──────────────────────────────────────────────────────────────

    if (state.diagnosisResult != null) {
      // Diagnosis complete — show rich result view
      return const DiagnosisResultView();
    }

    if (state.selectedImage != null) {
      // Image picked — show preview + describe + diagnose
      return DiagnosisPreviewView(
        selectedImage: state.selectedImage!,
        initialDescription: state.description,
        onDescriptionChanged: notifier.updateDescription,
        onStartDiagnosis: notifier.runDiagnosis,
        onReset: notifier.resetState,
        isLoading: state.isLoading,
        loadingMessage: state.loadingMessage,
      );
    }

    // No image — show selection screen + history bottom sheet
    return Stack(
      children: [
        DiagnosisSelectionView(
          onPickImage: notifier.pickImage,
        ),
        DiagnosisHistorySheet(
          onViewRecord: notifier.viewRecord,
        ),
      ],
    );
  }
}
