import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class GeminiService {
  late final GenerativeModel _textModel;
  late final GenerativeModel _visionModel;

  GeminiService() {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null) {
      throw Exception('GEMINI_API_KEY not found in .env file.');
    }
    _textModel = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: apiKey,
      generationConfig: GenerationConfig(temperature: 0.4),
    );
    _visionModel = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: apiKey,
      generationConfig: GenerationConfig(temperature: 0.4),
    );
  }

  Future<String> generateCareTips({
    required String plantName,
    String? species,
    required String plantingDate,
    required String location,
    String additionalDetails = '',
  }) async {
    String prompt =
        'You are a plant care expert. Provide concise, actionable care tips for a plant named "$plantName".';
    if (species != null && species.isNotEmpty) {
      prompt += ' The species is $species.';
    }
    if (plantingDate.isNotEmpty) {
      prompt += ' It was planted on $plantingDate.';
    }
    if (location.isNotEmpty) {
      prompt += ' It is located in/at: $location.';
    }
    if (additionalDetails.isNotEmpty) {
      prompt +=
          " The user has a specific question or observation: \"$additionalDetails\". Address this directly in your tips.";
    }
    prompt +=
        ' Format the response as a simple, bulleted list. Do not include any introductory or concluding sentences. Only provide the list of tips.';

    final content = [Content.text(prompt)];
    final response = await _textModel.generateContent(content);
    return response.text?.replaceAll(RegExp(r'[\*_`#]'), '') ??
        'Could not generate care tips.';
  }

  Future<String> analyzePlantImage(
    Uint8List imageData, {
    String? additionalDetails,
  }) async {
    String prompt =
        'Analyze this image of a plant. Provide a detailed diagnosis.';
    if (additionalDetails != null && additionalDetails.isNotEmpty) {
      prompt +=
          ' The user has provided these additional details and specific query: "$additionalDetails". Focus your diagnosis and recommendations based on these details, but also provide a general health assessment.';
    } else {
      prompt +=
          ' Provide a concise health diagnosis, identify any visible issues, and offer specific, actionable recommendations for improvement. If the plant appears healthy, state that clearly.';
    }
    prompt += '''
Respond in Markdown format with the following structure:
## Diagnosis
**[Your diagnosis here]**
## Severity
**[Low/Medium/High]**
## Precautions
**[List of actionable precautions and recommendations]**
''';

    final content = [
      Content.multi([TextPart(prompt), DataPart('image/jpeg', imageData)]),
    ];
    final response = await _visionModel.generateContent(content);
    return response.text ?? 'Could not analyze image.';
  }

  Future<String> validatePlantAndSuggest(String name) async {
    try {
      final prompt =
          'Is "$name" a real plant? If yes, answer YES '
          'and suggest standard fertilizing frequency in days (integer). '
          'If no or unsure, answer NO. '
          'Format: YES|14 or NO. Do not add any other text.';

      final response = await _textModel.generateContent([Content.text(prompt)]);
      return response.text?.trim() ?? 'NO';
    } catch (e) {
      debugPrint('Error validating plant: $e');
      return 'NO'; // Fail safe
    }
  }

  Future<Map<String, dynamic>> getPlantCareRecommendations({
    required String plantName,
    String? species,
    required String location,
  }) async {
    final int month = DateTime.now().month;

    String prompt =
        '''
You are a plant care expert. I am adding a new plant to my collection.
Name: "$plantName"
Species: "${species ?? 'Unknown'}"
Location: "$location"
Current Month: $month

First, evaluate if "$plantName" (contextualized by species if provided) is a legitimate plant name.
- Valid Examples: "Rose", "Snake Plant", "Ficus", "Monstera", "Tomato".
- Invalid Examples: "Table", "Laptop", "Unicorn", "asdf", "kjsdhf".

If INVALID, set "isValid" to false.

If VALID:
1. Analyze the "Location".
   - If implies Outdoor (e.g., Garden, Patio, Balcony, Backyard), suggest higher watering frequency (typically 2-4 days) based on exposure.
   - If implies Indoor (e.g., Living Room, Bedroom, Office), suggest standard indoor frequency (typically 7-14 days).
2. "frequency": Return an INTEGER representing days between watering.
   - Do NOT return '1' (daily) unless it is strictly necessary (e.g., aquatic plant, seedling in heat).
   - For most indoor plants, 7 is a safe average.
   - Be consistent with standard care guides.

Respond STRICTLY in this JSON format:
{
  "isValid": boolean,
  "frequency": integer,
  "advice": "Spring: [Tip]\\nSummer: [Tip]\\nAutumn: [Tip]\\nWinter: [Tip]"
}
Do not include markdown formatting like ```json. Just the raw JSON string.
''';

    final content = [Content.text(prompt)];
    final response = await _textModel.generateContent(content);
    final text =
        response.text?.replaceAll(RegExp(r'```json|```'), '').trim() ?? '';

    try {
      final Map<String, dynamic> data = jsonDecode(text);
      final bool isValid = data['isValid'] == true;

      if (!isValid) {
        return {'isValid': false};
      }

      int frequency = 7; // Default
      if (data['frequency'] is int) {
        frequency = data['frequency'];
      } else if (data['frequency'] is String) {
        frequency = int.tryParse(data['frequency']) ?? 7;
      }

      return {
        'isValid': true,
        'frequency': frequency,
        'advice': data['advice'] ?? 'No specific advice generated.',
      };
    } catch (e) {
      return {
        'isValid': true,
        'frequency': 7,
        'advice':
            'Could not generate specific advice. Water when topsoil is dry.',
      };
    }
  }
}

final geminiServiceProvider = Provider<GeminiService>((ref) {
  return GeminiService();
});
