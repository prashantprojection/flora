import 'dart:io';
import 'package:hive_ce/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flora/models/diagnosis_record.dart';
import 'package:flora/repositories/diagnosis/diagnosis_repository.dart';

/// Hive-backed implementation of [DiagnosisRepository].
/// All reads are synchronous (Hive box is pre-opened in main.dart).
/// All writes are async and non-blocking for the UI.
class LocalDiagnosisRepository implements DiagnosisRepository {
  final Box<DiagnosisRecord> _box;

  LocalDiagnosisRepository()
      : _box = Hive.box<DiagnosisRecord>('diagnosis_history');

  @override
  List<DiagnosisRecord> getDiagnoses() {
    return _box.values.toList()..sort((a, b) => b.date.compareTo(a.date));
  }

  @override
  DiagnosisRecord? getDiagnosis(String id) {
    try {
      return _box.values.firstWhere((r) => r.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> saveDiagnosis(DiagnosisRecord record) async {
    // Copy image to app documents for long-term persistence
    final appDir = await getApplicationDocumentsDirectory();
    final fileName = '${record.id}.jpg';
    final savedImage =
        await File(record.imagePath).copy('${appDir.path}/$fileName');

    final persistedRecord = DiagnosisRecord(
      id: record.id,
      imagePath: savedImage.path,
      diagnosis: record.diagnosis,
      date: record.date,
    );

    await _box.add(persistedRecord);
  }

  @override
  Future<void> updateChatMessages(String id, String chatJson) async {
    final key = _findKey(id);
    if (key == null) return;
    final record = _box.get(key)!;
    await _box.put(key, record.copyWith(chatMessages: chatJson));
  }

  @override
  Future<void> updateDiagnosisFeedback(String id, bool isHelpful) async {
    final key = _findKey(id);
    if (key == null) return;
    final record = _box.get(key)!;
    await _box.put(key, record.copyWith(isHelpful: isHelpful));
  }

  @override
  Future<void> deleteDiagnosis(String id) async {
    final key = _findKey(id);
    if (key == null) return;
    final record = _box.get(key)!;
    final file = File(record.imagePath);
    if (await file.exists()) await file.delete();
    await _box.delete(key);
  }

  @override
  Future<void> clearHistory() async {
    for (final record in _box.values) {
      final file = File(record.imagePath);
      if (await file.exists()) await file.delete();
    }
    await _box.clear();
  }

  // ── Private helpers ────────────────────────────────────────────────────────

  dynamic _findKey(String id) {
    try {
      return _box.keys.firstWhere((k) => _box.get(k)?.id == id);
    } catch (_) {
      return null;
    }
  }
}
