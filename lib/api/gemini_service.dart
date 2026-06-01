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
    bool hasGrowLight = false,
    String? plantStage,
    String? weatherLocation,
  }) async {
    String prompt =
        'You are Flo AI, an expert and friendly plant care assistant. Provide comprehensive, actionable care tips for a plant named "$plantName". '
        'Include advice on watering, fertilizing, pruning, and ambient light/temperature requirements.';
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

    if (plantStage != null && plantStage != 'mature') {
      prompt += ' Note that this plant is currently a $plantStage. Adjust care advice to be gentler and appropriate for its young stage.';
    }
    if (hasGrowLight) {
      prompt += ' The plant is growing under a grow light. Factor in extended or consistent light exposure in your advice.';
    }
    if (weatherLocation != null && weatherLocation.isNotEmpty) {
      prompt += ' The user\'s broader weather location/climate is $weatherLocation. Ensure advice fits this region.';
    }

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
        'You are Flo AI, a friendly plant care expert. First, verify if the image actually contains a plant. '
        'If it does NOT contain a plant (e.g., it is a person, animal, or random object), identify what it is briefly but remind the user you are a plant expert. '
        'Respond exactly with this markdown structure and nothing else:\n'
        '## Diagnosis\n**This appears to be a [briefly identify the object], but I am Flo, a plant expert!**\n## Severity\n**None**\n## Notes\n**Please upload a clear image of a plant so I can help you diagnose it.**\n\n'
        'If it DOES contain a plant, analyze it and provide a detailed diagnosis.';
    if (additionalDetails != null && additionalDetails.isNotEmpty) {
      prompt +=
          ' The user has provided these additional details and specific query: "$additionalDetails". Focus your diagnosis and recommendations based on these details, but also provide a general health assessment.';
    } else {
      prompt +=
          ' Provide a concise health diagnosis, identify any visible issues, and offer specific, actionable recommendations for improvement. If the plant appears healthy, state that clearly.';
    }
    prompt += '''
Respond in Markdown format with the following structure (if it is a plant):
## Diagnosis
**[Your diagnosis here]**
## Severity
**[Low/Medium/High]**
## Treatment Steps
**[Numbered, concrete, step-by-step treatment plan]**
## Prevention
**[List of actionable precautions to prevent this issue in the future]**
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
    bool hasGrowLight = false,
    String? plantStage,
    String? weatherLocation,
  }) async {
    final int month = DateTime.now().month;

    // Location-aware climate prompt
    String locationClause = location.isNotEmpty
        ? 'User is in room "$location". '
        : '';
    if (weatherLocation != null && weatherLocation.isNotEmpty) {
      locationClause += 'The local climate is "$weatherLocation". Adjust watering frequency for this climate. '
          'If this is a tropical or monsoon climate, account for wet/dry seasons. ';
    }
    if (hasGrowLight) {
      locationClause += 'The plant is under a grow light (extended daylight). ';
    }
    if (plantStage != null && plantStage != 'mature') {
      locationClause += 'The plant is a $plantStage, so it may need gentler, more frequent watering. ';
    }
    locationClause += 'If outdoor location, suggest higher watering frequency (2-4 days). '
        'If indoor, suggest standard indoor frequency (7-14 days).';

    final prompt = '''
You are Flo AI, a friendly and expert plant care assistant. I am adding a new plant to my collection.
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
2. "wateringFrequency": Return an INTEGER representing days between watering.
   - Do NOT return 1 (daily) unless strictly necessary. For most indoor plants, 7 is a safe average.
3. "fertilizingFrequency": Return an INTEGER representing days between fertilizing. (e.g. 30 for monthly during growing season). If the plant doesn't need fertilizer often, use 90 or 180.
4. "pruningFrequency": Return an INTEGER representing days between pruning. If the plant rarely needs pruning, use 180 or 365.
5. "advice": Provide comprehensive care tips covering watering, fertilizing, pruning, and ambient light/temperature requirements. Format the tips by season:
   Spring: [Detailed Tip]\nSummer: [Detailed Tip]\nAutumn: [Detailed Tip]\nWinter: [Detailed Tip]
6. "reasoning": Provide 2-3 concise bullet points explaining why these specific frequencies were chosen. Each bullet should start with "• ".

Respond STRICTLY in this JSON format:
{
  "isValid": boolean,
  "wateringFrequency": integer,
  "fertilizingFrequency": integer,
  "pruningFrequency": integer,
  "advice": "Spring: [Tip]\\nSummer: [Tip]\\nAutumn: [Tip]\\nWinter: [Tip]",
  "reasoning": "• Bullet 1\\n• Bullet 2"
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

      // Parse frequencies
      int parseFreq(dynamic value, int fallback) {
        if (value is int) return value;
        if (value is String) return int.tryParse(value) ?? fallback;
        return fallback;
      }

      int wateringFreq = parseFreq(data['wateringFrequency'], 7);
      if (wateringFreq < 1 || wateringFreq > 60) wateringFreq = 7;
      
      int fertFreq = parseFreq(data['fertilizingFrequency'], 30);
      int pruneFreq = parseFreq(data['pruningFrequency'], 90);

      return {
        'isValid': true,
        'wateringFrequency': wateringFreq,
        'fertilizingFrequency': fertFreq,
        'pruningFrequency': pruneFreq,
        'advice': data['advice'] ?? 'No specific advice generated.',
        'reasoning': data['reasoning'] ?? '',
      };
    } catch (e) {
      debugPrint('[GeminiService] getPlantCareRecommendations failed: $e');
      return {
        'isValid': true,
        'wateringFrequency': 7,
        'fertilizingFrequency': 30,
        'pruningFrequency': 90,
        'advice': 'Could not generate specific advice. Water when topsoil is dry.',
        'reasoning': '',
      };
    }
  }
}

final geminiServiceProvider = Provider<GeminiService>((ref) {
  return GeminiService();
});
