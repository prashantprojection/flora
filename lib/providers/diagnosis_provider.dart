import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flora/models/diagnosis_record.dart';
import 'package:flora/repositories/diagnosis_repository.dart';

final diagnosisRepositoryProvider = Provider<DiagnosisRepository>((ref) {
  return DiagnosisRepository();
});

final diagnosisHistoryProvider =
    StateNotifierProvider<DiagnosisHistoryNotifier, List<DiagnosisRecord>>((
      ref,
    ) {
      return DiagnosisHistoryNotifier(ref.watch(diagnosisRepositoryProvider));
    });

class DiagnosisHistoryNotifier extends StateNotifier<List<DiagnosisRecord>> {
  final DiagnosisRepository _repository;

  DiagnosisHistoryNotifier(this._repository) : super([]) {
    loadHistory();
  }

  void loadHistory() {
    state = _repository.getDiagnoses();
  }

  Future<void> addDiagnosis(DiagnosisRecord record) async {
    await _repository.saveDiagnosis(record);
    loadHistory();
  }

  Future<void> deleteDiagnosis(int index) async {
    await _repository.deleteDiagnosis(index);
    loadHistory();
  }

  Future<void> clearHistory() async {
    await _repository.clearHistory();
    loadHistory();
  }
}
