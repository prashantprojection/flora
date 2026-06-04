import 'package:flora/models/diagnosis_record.dart';

/// Abstract contract for all diagnosis history operations.
/// Swap [LocalDiagnosisRepository] for a remote implementation with zero UI changes.
abstract class DiagnosisRepository {
  /// Returns all diagnosis records, sorted newest first.
  List<DiagnosisRecord> getDiagnoses();

  /// Returns a single record by ID, or null if not found.
  DiagnosisRecord? getDiagnosis(String id);

  /// Saves a new diagnosis record (copies image to persistent storage).
  Future<void> saveDiagnosis(DiagnosisRecord record);

  /// Appends/replaces the serialized follow-up chat JSON for a record.
  Future<void> updateChatMessages(String id, String chatJson);

  /// Updates the helpful/not-helpful feedback for a record.
  Future<void> updateDiagnosisFeedback(String id, bool isHelpful);

  /// Deletes a single diagnosis record and its associated image.
  Future<void> deleteDiagnosis(String id);

  /// Deletes all diagnosis records and images.
  Future<void> clearHistory();
}
