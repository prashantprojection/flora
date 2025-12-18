enum CareType { watering, fertilizing, pruning, skipped }

class CareEvent {
  final String id;
  final CareType type;
  final DateTime date;
  final String? notes;
  final String? photoUrl;

  CareEvent({
    required this.id,
    required this.type,
    required this.date,
    this.notes,
    this.photoUrl,
  });

  factory CareEvent.fromJson(Map<String, dynamic> json) {
    return CareEvent(
      id: json['id'],
      type: CareType.values.firstWhere((e) => e.toString() == json['type']),
      date: DateTime.parse(json['date']),
      notes: json['notes'],
      photoUrl: json['photoUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.toString(),
      'date': date.toIso8601String(),
      'notes': notes,
      'photoUrl': photoUrl,
    };
  }
}
