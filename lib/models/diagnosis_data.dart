import 'dart:convert';
import 'package:flutter/foundation.dart';

class DiagnosisData {
  final String diseaseName;
  final String severity;
  final List<String> symptoms;
  final List<String> causes;
  final List<String> treatment;
  final List<String> prevention;
  final String? additionalNotes;

  const DiagnosisData({
    required this.diseaseName,
    required this.severity,
    required this.symptoms,
    required this.causes,
    required this.treatment,
    required this.prevention,
    this.additionalNotes,
  });

  /// Factory to parse from GenUI structured JSON
  factory DiagnosisData.fromJson(Map<String, dynamic> json) {
    return DiagnosisData(
      diseaseName: json['diseaseName'] ?? 'Plant Analysis',
      severity: json['severity'] ?? 'Unknown',
      symptoms: List<String>.from(json['symptoms'] ?? []),
      causes: List<String>.from(json['causes'] ?? []),
      treatment: List<String>.from(json['treatment'] ?? []),
      prevention: List<String>.from(json['prevention'] ?? []),
      additionalNotes: json['additionalNotes'],
    );
  }

  /// Convert to JSON map
  Map<String, dynamic> toJson() {
    return {
      'diseaseName': diseaseName,
      'severity': severity,
      'symptoms': symptoms,
      'causes': causes,
      'treatment': treatment,
      'prevention': prevention,
      if (additionalNotes != null) 'additionalNotes': additionalNotes,
    };
  }

  /// Convert to JSON string for saving in Hive
  String toJsonString() {
    return jsonEncode(toJson());
  }

  /// Master parser that assumes GenUI structured JSON
  factory DiagnosisData.fromString(String rawData) {
    try {
      final json = jsonDecode(rawData);
      return DiagnosisData.fromJson(json);
    } catch (e) {
      debugPrint('[DiagnosisData] Parsing JSON failed: $e');
      return const DiagnosisData(
        diseaseName: 'Error',
        severity: 'Unknown',
        symptoms: [],
        causes: [],
        treatment: [],
        prevention: [],
      );
    }
  }
}
