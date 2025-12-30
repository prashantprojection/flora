import 'package:hive_ce/hive.dart';

class DiagnosisRecord {
  final String id;
  final String imagePath;
  final String diagnosis;
  final DateTime date;

  DiagnosisRecord({
    required this.id,
    required this.imagePath,
    required this.diagnosis,
    required this.date,
  });
}

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
    );
  }

  @override
  void write(BinaryWriter writer, DiagnosisRecord obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.imagePath)
      ..writeByte(2)
      ..write(obj.diagnosis)
      ..writeByte(3)
      ..write(obj.date);
  }
}
