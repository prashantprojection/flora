import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flora/models/diagnosis_record.dart';
import 'package:flora/repositories/diagnosis_repository.dart';

final diagnosisRepositoryProvider = Provider<DiagnosisRepository>((ref) {
  return DiagnosisRepository();
});

class DiagnosisHistoryNotifier extends Notifier<List<DiagnosisRecord>> {
  DiagnosisRepository get _repository => ref.read(diagnosisRepositoryProvider);

  /// [build] initializes state synchronously from the Hive box
  /// (already open since main.dart opens it before runApp).
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

  Future<void> deleteDiagnosis(int index) async {
    await _repository.deleteDiagnosis(index);
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
