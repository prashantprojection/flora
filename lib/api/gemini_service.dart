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

  // ---------------------------------------------------------------------------
  // Location-aware, hemisphere/tropical seasonal advice
  // ---------------------------------------------------------------------------
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

    // Inject location climate context
    if (location.isNotEmpty && location != 'Not Specified') {
      prompt +=
          ' The user is located in $location. Adjust all care recommendations for this climate, including monsoon season patterns if applicable.';
    }

    // Hemisphere and tropical season awareness
    prompt +=
        ' Generate seasonal advice appropriate for the user\'s location ($location). '
        'If they are in the Southern Hemisphere, reverse the seasons (e.g., December is summer). '
        'If the location is tropical or near the equator, note that seasons may be wet/dry rather than spring/summer/autumn/winter, '
        'and label the cards accordingly (e.g., "Wet Season" / "Dry Season").';

    if (additionalDetails.isNotEmpty) {
      prompt +=
          ' The user has a specific question or observation: "$additionalDetails". Address this directly in your tips.';
    }

    prompt +=
        ' Format the response as seasonal sections: Spring: [tip]\nSummer: [tip]\nAutumn: [tip]\nWinter: [tip]\n'
        '(or Wet Season/Dry Season if tropical). Do not include any introductory or concluding sentences.';

    try {
      final content = [Content.text(prompt)];
      final response = await _textModel.generateContent(content);
      return response.text?.replaceAll(RegExp(r'[*`#]'), '') ??
          'Could not generate care tips.';
    } catch (e) {
      debugPrint('[GeminiService] generateCareTips failed: $e');
      return 'Could not generate care tips.';
    }
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
    try {
      final response = await _visionModel.generateContent(content);
      return response.text ?? 'Could not analyze image.';
    } catch (e) {
      debugPrint('[GeminiService] analyzePlantImage failed: $e');
      return 'Could not analyze image.';
    }
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
      debugPrint('[GeminiService] validatePlantAndSuggest failed: $e');
      return 'NO';
    }
  }

  // ---------------------------------------------------------------------------
  // Location parameter, reasoning field, and validation
  // ---------------------------------------------------------------------------
  Future<Map<String, dynamic>> getPlantCareRecommendations({
    required String plantName,
    String? species,
    required String location,
  }) async {
    final int month = DateTime.now().month;

    // Location-aware climate prompt
    final locationClause = location.isNotEmpty
        ? 'User is in "$location". Adjust watering frequency for this climate. '
            'If this is a tropical or monsoon climate, account for wet/dry seasons. '
            'If outdoor (Garden, Patio, Balcony, Backyard), suggest higher frequency (2-4 days). '
            'If indoor (Living Room, Bedroom, Office), suggest standard indoor frequency (7-14 days).'
        : 'If outdoor location, suggest higher watering frequency (2-4 days). '
            'If indoor, suggest standard indoor frequency (7-14 days).';

    final prompt = '''
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
1. $locationClause
2. "frequency": Return an INTEGER representing days between watering.
   - Do NOT return '1' (daily) unless it is strictly necessary (e.g., aquatic plant, seedling in heat).
   - For most indoor plants, 7 is a safe average.
   - Be consistent with standard care guides.
3. IMPORTANT: Validate the watering frequency against known horticultural standards.
   Examples: basil requires watering every 1-2 days; succulents every 14-21 days; tropical houseplants every 5-7 days.
   If your suggested frequency deviates significantly from known standards, explain why in the advice field.
4. "reasoning": Provide 2-3 concise bullet points explaining why this specific frequency was chosen
   for this plant in this location (e.g. "Monstera prefers moderate humidity typical of Living Room conditions").
   Each bullet should start with "• ".

Respond STRICTLY in this JSON format:
{
  "isValid": boolean,
  "frequency": integer,
  "advice": "Spring: [Tip]\\nSummer: [Tip]\\nAutumn: [Tip]\\nWinter: [Tip]",
  "reasoning": "• Bullet 1\\n• Bullet 2\\n• Bullet 3"
}
Do not include markdown formatting like ```json. Just the raw JSON string.
''';

    try {
      final content = [Content.text(prompt)];
      final response = await _textModel.generateContent(content);
      final text =
          response.text?.replaceAll(RegExp(r'```json|```'), '').trim() ?? '';

      final Map<String, dynamic> data = jsonDecode(text);
      final bool isValid = data['isValid'] == true;

      if (!isValid) {
        return {'isValid': false};
      }

      // Clamp frequency to sane bounds
      int frequency = 7;
      if (data['frequency'] is int) {
        frequency = data['frequency'] as int;
      } else if (data['frequency'] is String) {
        frequency = int.tryParse(data['frequency'] as String) ?? 7;
      }
      if (frequency < 1 || frequency > 60) {
        debugPrint(
            '[GeminiService] Clamped absurd frequency $frequency → 7');
        frequency = 7;
      }

      return {
        'isValid': true,
        'frequency': frequency,
        'advice': data['advice'] ?? 'No specific advice generated.',
        'reasoning': data['reasoning'] ?? '',
      };
    } catch (e) {
      debugPrint('[GeminiService] getPlantCareRecommendations failed: $e');
      return {
        'isValid': true,
        'frequency': 7,
        'advice': 'Could not generate specific advice. Water when topsoil is dry.',
        'reasoning': '',
      };
    }
  }
}

final geminiServiceProvider = Provider<GeminiService>((ref) {
  return GeminiService();
});
