import 'package:flora/api/llm/anthropic_engine.dart';
import 'package:flora/api/llm/gemini_engine.dart';
import 'package:flora/api/llm/openai_engine.dart';
import 'package:flora/models/llm_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flora/models/llm_models.dart';
import 'package:flora/providers/ai_settings_provider.dart';
import 'package:flutter/foundation.dart';

abstract class LlmEngine {
  final String apiKey;
  final String modelId;

  LlmEngine({required this.apiKey, required this.modelId});

  /// Master function capable of handling single-turn text, multi-modal images,
  /// and multi-turn chat with or without tools.
  Future<LlmResponse> generateContent(
    List<LlmMessage> messages, {
    LlmConfig? config,
  }) async {
    _validate();
    try {
      return await doGenerateContent(messages, config: config);
    } catch (e, stack) {
      debugPrint('[$runtimeType] generateContent failed: $e');
      Error.throwWithStackTrace(Exception('$runtimeType Error: $e'), stack);
    }
  }

  /// Streaming equivalent for real-time text typewriter effects.
  Stream<String> generateTextStream(
    List<LlmMessage> messages, {
    LlmConfig? config,
  }) async* {
    _validate();
    try {
      yield* doGenerateTextStream(messages, config: config);
    } catch (e, stack) {
      debugPrint('[$runtimeType] generateTextStream failed: $e');
      Error.throwWithStackTrace(Exception('$runtimeType Error: $e'), stack);
    }
  }

  void _validate() {
    if (apiKey.isEmpty) {
      throw Exception('Missing API Key: You must provide a valid API key for $runtimeType.');
    }
  }

  @protected
  Future<LlmResponse> doGenerateContent(
    List<LlmMessage> messages, {
    LlmConfig? config,
  });

  @protected
  Stream<String> doGenerateTextStream(
    List<LlmMessage> messages, {
    LlmConfig? config,
  });
}

/// Provides the currently active LLM engine instance based on user settings.
///
/// **Architectural Note:** This is currently a synchronous `Provider`. `GeminiEngine`
/// initializes synchronously. However, if future engines (like `OpenAiEngine`)
/// require async initialization (e.g., fetching auth tokens, setting up connection pools),
/// this must be migrated to a `FutureProvider` or `AsyncNotifier`, and the dependent
/// `aiServiceProvider` will need to handle async injection.
final llmEngineProvider = Provider<LlmEngine>((ref) {
  final settings = ref.watch(aiSettingsProvider);
  switch (settings.activeProvider) {
    case AiProvider.gemini:
      return GeminiEngine(
        apiKey: settings.activeApiKey,
        modelId: settings.activeModelId,
      );
    case AiProvider.openai:
      return OpenAiEngine(
        apiKey: settings.activeApiKey,
        modelId: settings.activeModelId,
      );
    case AiProvider.anthropic:
      return AnthropicEngine(
        apiKey: settings.activeApiKey,
        modelId: settings.activeModelId,
      );
  }
});
