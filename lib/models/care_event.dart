enum CareType {
  watering,
  fertilizing,
  pruning,
}

class CareEvent {
  final String id;
  final CareType type;
  final DateTime date;
  final String? notes;

  CareEvent({
    required this.id,
    required this.type,
    required this.date,
    this.notes,
  });

  factory CareEvent.fromJson(Map<String, dynamic> json) {
    return CareEvent(
      id: json['id'],
      type: CareType.values.firstWhere((e) => e.toString() == json['type']),
      date: DateTime.parse(json['date']),
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.toString(),
      'date': date.toIso8601String(),
      'notes': notes,
    };
  }
}