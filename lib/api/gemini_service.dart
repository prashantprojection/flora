import 'dart:typed_data';

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
    _textModel = GenerativeModel(model: 'gemini-2.5-flash', apiKey: apiKey);
    _visionModel = GenerativeModel(model: 'gemini-2.5-flash', apiKey: apiKey);
  }

  Future<String> generateCareTips({
    required String plantName,
    String? species,
    required String plantingDate,
    required String location,
    String additionalDetails = '',
  }) async {
    String prompt = 'You are a plant care expert. Provide concise, actionable care tips for a plant named "$plantName".';
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
      prompt += " The user has a specific question or observation: \"$additionalDetails\". Address this directly in your tips.";
    }
    prompt += ' Format the response as a simple, bulleted list. Do not include any introductory or concluding sentences. Only provide the list of tips.';

    final content = [Content.text(prompt)];
    final response = await _textModel.generateContent(content);
    return response.text?.replaceAll(RegExp(r'[\*_`#]'), '') ?? 'Could not generate care tips.';
  }

  Future<String> analyzePlantImage(Uint8List imageData, {String? additionalDetails}) async {
    String prompt = 'Analyze this image of a plant. Provide a detailed diagnosis.';
    if (additionalDetails != null && additionalDetails.isNotEmpty) {
      prompt += ' The user has provided these additional details and specific query: "$additionalDetails". Focus your diagnosis and recommendations based on these details, but also provide a general health assessment.';
    } else {
      prompt += ' Provide a concise health diagnosis, identify any visible issues, and offer specific, actionable recommendations for improvement. If the plant appears healthy, state that clearly.';
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

    final content = [Content.multi([
      TextPart(prompt),
      DataPart('image/jpeg', imageData),
    ])];
    final response = await _visionModel.generateContent(content);
    return response.text ?? 'Could not analyze image.';
  }
}
final geminiServiceProvider = Provider<GeminiService>((ref) {
  return GeminiService();
});
    
