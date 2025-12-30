import 'dart:io';
import 'package:hive_ce/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flora/models/diagnosis_record.dart';

class DiagnosisRepository {
  final Box<DiagnosisRecord> _box;

  DiagnosisRepository() : _box = Hive.box<DiagnosisRecord>('diagnosis_history');

  List<DiagnosisRecord> getDiagnoses() {
    return _box.values.toList()..sort((a, b) => b.date.compareTo(a.date));
  }

  Future<void> saveDiagnosis(DiagnosisRecord record) async {
    // 1. Copy image to app document directory for persistence
    final appDir = await getApplicationDocumentsDirectory();
    final fileName = '${record.id}.jpg';
    final savedImage = await File(
      record.imagePath,
    ).copy('${appDir.path}/$fileName');

    // 2. Create new record with persistent path
    final newRecord = DiagnosisRecord(
      id: record.id,
      imagePath: savedImage.path,
      diagnosis: record.diagnosis,
      date: record.date,
    );

    // 3. Save to Hive
    await _box.add(newRecord);
  }

  Future<void> deleteDiagnosis(int index) async {
    final record = _box.getAt(index);
    if (record != null) {
      final file = File(record.imagePath);
      if (await file.exists()) {
        await file.delete();
      }
      await _box.deleteAt(index);
    }
  }

  Future<void> clearHistory() async {
    // Delete all images
    for (var record in _box.values) {
      final file = File(record.imagePath);
      if (await file.exists()) {
        await file.delete();
      }
    }
    await _box.clear();
  }
}
