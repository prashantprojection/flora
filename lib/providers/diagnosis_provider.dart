import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flora/models/diagnosis_record.dart';
import 'package:flora/repositories/diagnosis/diagnosis_repository.dart';
import 'package:flora/repositories/diagnosis/local_diagnosis_repository.dart';

// ── Repository Provider ───────────────────────────────────────────────────────
// To swap to a remote backend: replace LocalDiagnosisRepository() with
// RemoteDiagnosisRepository() — zero other changes needed.

final diagnosisRepositoryProvider = Provider<DiagnosisRepository>((ref) {
  return LocalDiagnosisRepository();
});

// ── History Notifier ──────────────────────────────────────────────────────────

class DiagnosisHistoryNotifier extends Notifier<List<DiagnosisRecord>> {
  DiagnosisRepository get _repository => ref.read(diagnosisRepositoryProvider);

  @override
  List<DiagnosisRecord> build() {
    return _repository.getDiagnoses();
  }

  void _refresh() {
    state = _repository.getDiagnoses();
  }

  Future<void> addDiagnosis(DiagnosisRecord record) async {
    await _repository.saveDiagnosis(record);
    _refresh();
  }

  Future<void> updateDiagnosisFeedback(String id, bool isHelpful) async {
    await _repository.updateDiagnosisFeedback(id, isHelpful);
    _refresh();
  }

  Future<void> updateChatMessages(String id, String chatJson) async {
    await _repository.updateChatMessages(id, chatJson);
    _refresh();
  }

  Future<void> deleteDiagnosis(String id) async {
    await _repository.deleteDiagnosis(id);
    _refresh();
  }

  Future<void> clearHistory() async {
    await _repository.clearHistory();
    _refresh();
  }
}

final diagnosisHistoryProvider =
    NotifierProvider<DiagnosisHistoryNotifier, List<DiagnosisRecord>>(
  DiagnosisHistoryNotifier.new,
);
