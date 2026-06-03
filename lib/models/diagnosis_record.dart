import 'package:hive_ce/hive.dart';

class DiagnosisRecord {
  final String id;
  final String imagePath;
  final String diagnosis;
  final DateTime date;
  final bool? isHelpful;

  /// JSON-encoded list of [PersistedChatMessage] for follow-up conversation.
  /// Null means no follow-up was ever started (old records stay compatible).
  final String? chatMessages;

  DiagnosisRecord({
    required this.id,
    required this.imagePath,
    required this.diagnosis,
    required this.date,
    this.isHelpful,
    this.chatMessages,
  });

  DiagnosisRecord copyWith({
    String? id,
    String? imagePath,
    String? diagnosis,
    DateTime? date,
    bool? isHelpful,
    String? chatMessages,
    bool clearChatMessages = false,
  }) {
    return DiagnosisRecord(
      id: id ?? this.id,
      imagePath: imagePath ?? this.imagePath,
      diagnosis: diagnosis ?? this.diagnosis,
      date: date ?? this.date,
      isHelpful: isHelpful ?? this.isHelpful,
      chatMessages:
          clearChatMessages ? null : (chatMessages ?? this.chatMessages),
    );
  }
}

// ── Hive Adapter ──────────────────────────────────────────────────────────────
// Field indices:
//   0 → id
//   1 → imagePath
//   2 → diagnosis
//   3 → date
//   4 → isHelpful
//   5 → chatMessages  (NEW — old records read null, backward-compatible)

class DiagnosisRecordAdapter extends TypeAdapter<DiagnosisRecord> {
  @override
  final int typeId = 0;

  @override
  DiagnosisRecord read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DiagnosisRecord(
      id: fields[0] as String,
      imagePath: fields[1] as String,
      diagnosis: fields[2] as String,
      date: fields[3] as DateTime,
      isHelpful: fields[4] as bool?,
      chatMessages: fields[5] as String?, // null for old records — safe
    );
  }

  @override
  void write(BinaryWriter writer, DiagnosisRecord obj) {
    writer
      ..writeByte(6) // total fields
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.imagePath)
      ..writeByte(2)
      ..write(obj.diagnosis)
      ..writeByte(3)
      ..write(obj.date)
      ..writeByte(4)
      ..write(obj.isHelpful)
      ..writeByte(5)
      ..write(obj.chatMessages);
  }
}
