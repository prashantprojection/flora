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
  final List<CareEvent> careHistory;

  Plant({
    required this.id,
    required this.name,
    this.species,
    this.imageUrl,
    required this.plantingDate,
    this.location,
    required this.lastWatered,
    required this.nextWatering,
    required this.careHistory,
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
    List<CareEvent>? careHistory,
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
      careHistory: careHistory ?? this.careHistory,
    );
  }

  factory Plant.fromJson(Map<String, dynamic> json) {
    return Plant(
      id: json['id'],
      name: json['name'],
      species: json['species'],
      imageUrl: json['imageUrl'],
      plantingDate: DateTime.parse(json['plantingDate']),
      location: json['location'],
      lastWatered: DateTime.parse(json['lastWatered']),
      nextWatering: DateTime.parse(json['nextWatering']),
      careHistory: (json['careHistory'] as List)
          .map((e) => CareEvent.fromJson(e))
          .toList(),
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
      'careHistory': careHistory.map((e) => e.toJson()).toList(),
    };
  }
}