import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flora/api/llm/llm_engine.dart';
import 'package:flora/api/ai_prompt_templates.dart';

import 'package:flora/services/genui_orchestrator.dart';

class AiService {
  final LlmEngine _engine;
  final GenUiOrchestrator _orchestrator;

  AiService(this._engine, this._orchestrator);

  Future<String> generateCareTips({
    required String plantName,
    String? species,
    required String plantingDate,
    required String location,
    String additionalDetails = '',
    bool hasGrowLight = false,
    String? plantStage,
    String? weatherLocation,
  }) async {
    final prompt = AiPromptTemplates.buildCareTips(
      plantName: plantName,
      species: species,
      plantingDate: plantingDate,
      location: location,
      additionalDetails: additionalDetails,
      hasGrowLight: hasGrowLight,
      plantStage: plantStage,
      weatherLocation: weatherLocation,
    );

    try {
      final response = await _engine.generateResponse(prompt);
      final text = response.text ?? '';
      if (text.isNotEmpty) {
        return text.replaceAll(RegExp(r'[*`#]'), '');
      }
    } catch (e) {
      debugPrint('[AiService] generateCareTips engine failed: $e');
    }

    return '''Spring: Place in bright indirect light and water moderately.
Summer: Increase watering frequency and monitor for dry soil.
Autumn: Reduce watering as growth slows.
Winter: Keep soil slightly dry and avoid cold drafts.''';
  }

  /// Streams care tips for a real-time typewriter effect in the UI.
  Stream<String> generateCareTipsStream({
    required String plantName,
    String? species,
    required String plantingDate,
    required String location,
    String additionalDetails = '',
    bool hasGrowLight = false,
    String? plantStage,
    String? weatherLocation,
  }) async* {
    final prompt = AiPromptTemplates.buildCareTips(
      plantName: plantName,
      species: species,
      plantingDate: plantingDate,
      location: location,
      additionalDetails: additionalDetails,
      hasGrowLight: hasGrowLight,
      plantStage: plantStage,
      weatherLocation: weatherLocation,
    );

    try {
      final stream = _engine.generateTextStream(prompt);
      await for (final chunk in stream) {
        yield chunk.replaceAll(RegExp(r'[*`#]'), '');
      }
    } catch (e) {
      debugPrint('[AiService] generateCareTipsStream engine failed: $e');
      yield '''Spring: Place in bright indirect light and water moderately.
Summer: Increase watering frequency and monitor for dry soil.
Autumn: Reduce watering as growth slows.
Winter: Keep soil slightly dry and avoid cold drafts.''';
    }
  }

  Future<String> analyzePlantImage(
    Uint8List imageData, {
    String? additionalDetails,
  }) async {
    final prompt = AiPromptTemplates.buildDiagnosis(
      additionalDetails: additionalDetails,
    );

    try {
      final response = await _orchestrator.generateGenUiFromImage(prompt, imageData);
      
      if (response.isWidget) {
        // Return the JSON arguments as a string to be saved/parsed
        return jsonEncode(response.functionCall!.arguments);
      }
      
      final text = response.text ?? '';
      if (text.isNotEmpty) return text;
    } catch (e) {
      debugPrint('[AiService] analyzePlantImage engine failed: $e');
    }

    return jsonEncode({
      'diseaseName': 'Analysis Unavailable',
      'severity': 'Unknown',
      'symptoms': ['Unable to reach the AI analysis service.'],
      'causes': ['Network issue or AI service is temporarily down.'],
      'treatment': ['Please check your internet connection.', 'Try again later.'],
      'prevention': [],
    });
  }

  Future<String> validatePlantAndSuggest(String name) async {
    final prompt = AiPromptTemplates.buildValidation(name);

    try {
      final response = await _engine.generateResponse(prompt);
      final text = response.text ?? '';
      if (text.isNotEmpty) {
        if (text.contains('YES')) return 'YES|14';
        if (text.contains('NO')) return 'NO';
        return text.trim();
      }
    } catch (e) {
      debugPrint('[AiService] validatePlantAndSuggest engine failed: $e');
    }

    return 'YES|14';
  }

  Future<Map<String, dynamic>> getPlantCareRecommendations({
    required String plantName,
    String? species,
    required String location,
    bool hasGrowLight = false,
    String? plantStage,
    String? weatherLocation,
  }) async {
    final prompt = AiPromptTemplates.buildRecommendations(
      plantName: plantName,
      species: species,
      location: location,
      hasGrowLight: hasGrowLight,
      plantStage: plantStage,
      weatherLocation: weatherLocation,
    );

    try {
      final response = await _engine.generateResponse(prompt);
      final textResponse = response.text ?? '';
      if (textResponse.isNotEmpty) {
        final text = textResponse.replaceAll(RegExp(r'```json|```'), '').trim();
        final Map<String, dynamic> data = jsonDecode(text);
        final bool isValid = data['isValid'] == true;

        if (!isValid) return {'isValid': false};

        int parseFreq(dynamic value, int fallback) {
          if (value is int) return value;
          if (value is String) return int.tryParse(value) ?? fallback;
          return fallback;
        }

        int wateringFreq = parseFreq(data['wateringFrequency'], 7);
        if (wateringFreq < 1 || wateringFreq > 60) wateringFreq = 7;
        
        return {
          'isValid': true,
          'wateringFrequency': wateringFreq,
          'fertilizingFrequency': parseFreq(data['fertilizingFrequency'], 30),
          'pruningFrequency': parseFreq(data['pruningFrequency'], 90),
          'advice': data['advice'] ?? 'No specific advice generated.',
          'reasoning': data['reasoning'] ?? '',
        };
      }
    } catch (e) {
      debugPrint('[AiService] getPlantCareRecommendations engine failed: $e');
    }

    return {
      'isValid': true,
      'wateringFrequency': 7,
      'fertilizingFrequency': 30,
      'pruningFrequency': 90,
      'advice': 'Spring: Water weekly.\\nSummer: Water twice a week.\\nAutumn: Water weekly.\\nWinter: Water bi-weekly.',
      'reasoning': '• Standard care schedule applied\n• Customized AI recommendations currently unavailable',
    };
  }
}

final aiServiceProvider = Provider<AiService>((ref) {
  final engine = ref.watch(llmEngineProvider);
  final orchestrator = ref.watch(genUiOrchestratorProvider);
  return AiService(engine, orchestrator);
});
