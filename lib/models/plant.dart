import 'care_event.dart';

class Plant {
  final String id;
  final String name;
  final String? species;
  final String? imageUrl;
  final DateTime plantingDate;
  final String? location;
  final DateTime lastWatered;
  final DateTime nextWatering;
  final int? wateringFrequency;
  final String? careInstructions;
  final List<CareEvent> careHistory;
  final List<CareSchedule> careSchedules;

  // Gemini reasoning for watering frequency
  final String? aiReasoning;
  // Timestamp for "Last updated" label in AICareTips
  final DateTime? aiTipsGeneratedAt;
  // Location context used when AI tips were generated
  final String? aiTipsSource;

  Plant({
    required this.id,
    required this.name,
    this.species,
    this.imageUrl,
    required this.plantingDate,
    this.location,
    required this.lastWatered,
    required this.nextWatering,
    this.wateringFrequency,
    this.careInstructions,
    required this.careHistory,
    this.careSchedules = const [],
    this.aiReasoning,
    this.aiTipsGeneratedAt,
    this.aiTipsSource,
  });

  Plant copyWith({
    String? id,
    String? name,
    String? species,
    String? imageUrl,
    DateTime? plantingDate,
    String? location,
    DateTime? lastWatered,
    DateTime? nextWatering,
    int? wateringFrequency,
    String? careInstructions,
    List<CareEvent>? careHistory,
    List<CareSchedule>? careSchedules,
    String? aiReasoning,
    DateTime? aiTipsGeneratedAt,
    String? aiTipsSource,
    // Sentinel to allow explicit null-clearing
    bool clearAiReasoning = false,
    bool clearAiTipsGeneratedAt = false,
    bool clearAiTipsSource = false,
  }) {
    return Plant(
      id: id ?? this.id,
      name: name ?? this.name,
      species: species ?? this.species,
      imageUrl: imageUrl ?? this.imageUrl,
      plantingDate: plantingDate ?? this.plantingDate,
      location: location ?? this.location,
      lastWatered: lastWatered ?? this.lastWatered,
      nextWatering: nextWatering ?? this.nextWatering,
      wateringFrequency: wateringFrequency ?? this.wateringFrequency,
      careInstructions: careInstructions ?? this.careInstructions,
      careHistory: careHistory ?? this.careHistory,
      careSchedules: careSchedules ?? this.careSchedules,
      aiReasoning: clearAiReasoning ? null : (aiReasoning ?? this.aiReasoning),
      aiTipsGeneratedAt: clearAiTipsGeneratedAt
          ? null
          : (aiTipsGeneratedAt ?? this.aiTipsGeneratedAt),
      aiTipsSource:
          clearAiTipsSource ? null : (aiTipsSource ?? this.aiTipsSource),
    );
  }

  factory Plant.fromJson(Map<String, dynamic> json) {
    // Migration logic: If wateringFrequency is missing, try to infer it.
    int inferredFrequency = 7;
    if (json['wateringFrequency'] != null) {
      inferredFrequency = json['wateringFrequency'];
    } else {
      try {
        final last = DateTime.parse(json['lastWatered']);
        final next = DateTime.parse(json['nextWatering']);
        final diff = next.difference(last).inDays;
        if (diff > 0) {
          inferredFrequency = diff;
        }
      } catch (_) {}
    }

    return Plant(
      id: json['id'],
      name: json['name'],
      species: json['species'],
      imageUrl: json['imageUrl'],
      plantingDate: DateTime.parse(json['plantingDate']),
      location: json['location'],
      lastWatered: DateTime.parse(json['lastWatered']),
      nextWatering: DateTime.parse(json['nextWatering']),
      wateringFrequency: inferredFrequency,
      careInstructions: json['careInstructions'],
      careHistory: (json['careHistory'] as List)
          .map((e) => CareEvent.fromJson(e))
          .toList(),
      careSchedules:
          (json['careSchedules'] as List?)
              ?.map((e) => CareSchedule.fromJson(e))
              .toList() ??
          [],
      // New nullable fields — safe fallback for old persisted data
      aiReasoning: json['aiReasoning'] as String?,
      aiTipsGeneratedAt: json['aiTipsGeneratedAt'] != null
          ? DateTime.tryParse(json['aiTipsGeneratedAt'] as String)
          : null,
      aiTipsSource: json['aiTipsSource'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'species': species,
      'imageUrl': imageUrl,
      'plantingDate': plantingDate.toIso8601String(),
      'location': location,
      'lastWatered': lastWatered.toIso8601String(),
      'nextWatering': nextWatering.toIso8601String(),
      'wateringFrequency': wateringFrequency,
      'careInstructions': careInstructions,
      'careHistory': careHistory.map((e) => e.toJson()).toList(),
      'careSchedules': careSchedules.map((e) => e.toJson()).toList(),
      'aiReasoning': aiReasoning,
      'aiTipsGeneratedAt': aiTipsGeneratedAt?.toIso8601String(),
      'aiTipsSource': aiTipsSource,
    };
  }
}

class CareSchedule {
  final CareType type;
  final int frequency; // days
  final DateTime lastDate;
  final DateTime nextDate;

  CareSchedule({
    required this.type,
    required this.frequency,
    required this.lastDate,
    required this.nextDate,
  });

  CareSchedule copyWith({
    CareType? type,
    int? frequency,
    DateTime? lastDate,
    DateTime? nextDate,
  }) {
    return CareSchedule(
      type: type ?? this.type,
      frequency: frequency ?? this.frequency,
      lastDate: lastDate ?? this.lastDate,
      nextDate: nextDate ?? this.nextDate,
    );
  }

  factory CareSchedule.fromJson(Map<String, dynamic> json) {
    return CareSchedule(
      type: CareType.values.firstWhere((e) => e.toString() == json['type']),
      frequency: json['frequency'],
      lastDate: DateTime.parse(json['lastDate']),
      nextDate: DateTime.parse(json['nextDate']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.toString(),
      'frequency': frequency,
      'lastDate': lastDate.toIso8601String(),
      'nextDate': nextDate.toIso8601String(),
    };
  }
}
