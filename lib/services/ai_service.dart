import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flora/api/llm/llm_engine.dart';
import 'package:flora/models/llm_models.dart';
import 'package:flora/api/ai_prompt_templates.dart';
import 'package:flora/services/genui_orchestrator.dart';
import 'package:flora/utils/app_exception.dart';

class AiService {
  final LlmEngine _engine;
  final AiToolOrchestrator _orchestrator;

  AiService(this._engine, this._orchestrator);

  // ── Care Tips ──────────────────────────────────────────────────────────────

  Future<String> fetchGeneralCareTips({
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
      final response = await _engine.generateContent([
        LlmMessage(role: LlmRole.user, text: prompt)
      ]);
      final text = response.text ?? '';
      if (text.isNotEmpty) {
        return text.replaceAll(RegExp(r'[*`#]'), '');
      }
      throw Exception('Empty response from AI.');
    } catch (e, stack) {
      throw ErrorHandler.parse(e, stack);
    }
  }

  Stream<String> streamGeneralCareTips({
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
      final stream = _engine.generateTextStream([
        LlmMessage(role: LlmRole.user, text: prompt)
      ]);
      await for (final chunk in stream) {
        yield chunk.replaceAll(RegExp(r'[*`#]'), '');
      }
    } catch (e, stack) {
      throw ErrorHandler.parse(e, stack);
    }
  }

  // ── Diagnosis ──────────────────────────────────────────────────────────────

  /// Initial diagnosis call — sends full history including the plant image.
  /// The AI responds with a GenUI [render_diagnosis_card] function call.
  /// Returns the JSON-encoded function call arguments, or plain text as fallback.
  Future<String> processDiseaseDiagnosisChat(List<LlmMessage> history) async {
    try {
      final response = await _orchestrator.executeToolChat(history);

      if (response.isWidget) {
        return jsonEncode(response.functionCall!.arguments);
      }

      final text = response.text ?? '';
      if (text.isNotEmpty) return text;
      throw Exception('Empty response from AI.');
    } catch (e, stack) {
      throw ErrorHandler.parse(e, stack);
    }

  }

  /// Follow-up chat call — uses Rolling Summarization.
  /// Instead of sending the full massive history, we build a lightweight prompt
  /// from the context summaries of previous messages.
  Future<AiToolResult> processFollowUpChat(List<LlmMessage> history) async {
    try {
      // Build a rolling summary from the historical messages
      final summaryBuffer = StringBuffer();
      for (final msg in history) {
        if (msg.contextSummary != null && msg.contextSummary!.isNotEmpty) {
          final prefix = msg.role == LlmRole.user ? "User: " : "Dr. Flo: ";
          summaryBuffer.writeln("$prefix${msg.contextSummary}");
        }
      }

      final contextText = summaryBuffer.isNotEmpty
          ? summaryBuffer.toString()
          : "(No previous follow-up context)";

      final systemContext = LlmMessage(
        role: LlmRole.user,
        text:
            'System: You are Dr. Flo, a plant disease expert. Below is a summary of the conversation so far:\n\n'
            '$contextText\n\n'
            'Instructions for your next response:\n'
            '1. You MUST first output a brief 1-sentence plain text summary of the conversation state and the advice you are about to give.\n'
            '2. Then, you MUST call the appropriate tool to render the UI widget for the user.\n'
            '3. Respond concisely and never reference the original image unless specifically asked.',
      );
      
      const systemAck = LlmMessage(
        role: LlmRole.model,
        text: 'Understood. I will provide a text summary and then call the tool.',
      );

      // We only send the system context, the ack, and the VERY LAST user message.
      // This completely drops the heavy image and JSON payloads from previous turns.
      final lightweightHistory = [systemContext, systemAck, history.last];
      
      return await _orchestrator.executeFollowUpChat(lightweightHistory);
    } catch (e) {
      debugPrint('[AiService] processFollowUpChat engine failed: $e');
      return AiToolResult(text: "I'm having trouble connecting right now. Please try again.");
    }
  }

  // ── Structured Care Schedule ───────────────────────────────────────────────

  Future<Map<String, dynamic>> fetchStructuredCareSchedule({
    required String plantName,
    String? species,
    required String location,
    bool hasGrowLight = false,
    String? plantStage,
    String? weatherLocation,
    Uint8List? imageBytes,
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
      final response = await _engine.generateContent([
        LlmMessage(
          role: LlmRole.user, 
          text: prompt, 
          image: imageBytes,
        )
      ]);
      final textResponse = response.text ?? '';
      if (textResponse.isNotEmpty) {
        final text =
            textResponse.replaceAll(RegExp(r'```json|```'), '').trim();
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
    } catch (e, stack) {
      throw ErrorHandler.parse(e, stack);
    }

    return {
      'isValid': true,
      'wateringFrequency': 7,
      'fertilizingFrequency': 30,
      'pruningFrequency': 90,
      'advice':
          'Spring: Water weekly.\\nSummer: Water twice a week.\\nAutumn: Water weekly.\\nWinter: Water bi-weekly.',
      'reasoning':
          '• Standard care schedule applied\n• Customized AI recommendations currently unavailable',
    };
  }
}

final aiServiceProvider = Provider<AiService>((ref) {
  final engine = ref.watch(llmEngineProvider);
  final orchestrator = ref.watch(aiToolOrchestratorProvider);
  return AiService(engine, orchestrator);
});
