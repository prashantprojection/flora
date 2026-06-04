
import 'package:flora/api/llm/gemini_engine.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flora/models/llm_models.dart';
import 'package:flora/providers/ai_settings_provider.dart';

abstract class LlmEngine {
  /// Master function capable of handling single-turn text, multi-modal images, 
  /// and multi-turn chat with or without tools.
  Future<LlmResponse> generateContent(List<LlmMessage> messages, {LlmConfig? config});

  /// Streaming equivalent for real-time text typewriter effects.
  /// (Streaming currently only supports text, not tool calls).
  Stream<String> generateTextStream(List<LlmMessage> messages, {LlmConfig? config});
}

final llmEngineProvider = Provider<LlmEngine>((ref) {
  final settings = ref.watch(aiSettingsProvider);
  // In the future, this can switch between GeminiEngine, OpenAiEngine, etc.
  // based on settings.activeProvider
  return GeminiEngine(
    apiKey: settings.geminiApiKey,
    modelId: settings.geminiModelId,
  );
});
