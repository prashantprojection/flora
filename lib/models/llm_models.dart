import 'dart:typed_data';
import 'package:flora/models/llm_providers.dart';

/// Represents configuration for an LLM engine to control creativity and limits.
class LlmConfig {
  final double? temperature;
  final int? maxTokens;
  final int? topK;
  final List<LlmTool>? tools;

  const LlmConfig({this.temperature, this.maxTokens, this.topK, this.tools});
}

/// Represents the role of a message sender in a chat context.
enum LlmRole { user, model }

/// Represents a single message in a multi-turn conversation context.
class LlmMessage {
  final LlmRole role;
  final String text;
  final Uint8List? image;

  /// A brief background summary of what happened in this conversational turn.
  /// Used for building lightweight context prompts on follow-up chats.
  final String? contextSummary;

  /// The local path to an attached image, if any. Used for UI display
  /// when raw bytes are not stored in memory.
  final String? imagePath;

  const LlmMessage({
    required this.role,
    required this.text,
    this.image,
    this.contextSummary,
    this.imagePath,
  });
}

// ── GenUI (Function Calling) Models ───────────────────────────────────────

/// A tool definition passed to the LLM so it knows what widgets it can render
class LlmTool {
  final String name;
  final String description;

  /// JSON Schema for the widget's parameters.
  /// **Architectural Note:** This schema is a neutral JSON format. Each LLM Engine
  /// (e.g. `GeminiEngine`, `OpenAiEngine`) is responsible for translating this
  /// format into its own provider's required wire schema (e.g. Google's `Schema` object).
  final Map<String, dynamic> schema;

  const LlmTool({
    required this.name,
    required this.description,
    required this.schema,
  });
}

/// A request from the LLM to call a specific tool (render a specific widget)
class LlmFunctionCall {
  final String name;
  final Map<String, dynamic> arguments;

  const LlmFunctionCall({required this.name, required this.arguments});
}

/// The response from the LLM, which could be raw text OR a request to render GenUI
class LlmResponse {
  final String? text;
  final LlmFunctionCall? functionCall;

  const LlmResponse({this.text, this.functionCall});

  bool get isFunctionCall => functionCall != null;
}

// ── LLM Models ───────────────────────────────────────────────────────────

class LlmModelOption {
  final String id;
  final String displayName;
  final String badge;
  final String description;

  const LlmModelOption({
    required this.id,
    required this.displayName,
    required this.badge,
    required this.description,
  });
}

const Map<AiProvider, List<LlmModelOption>> kModelsByProvider = {
  AiProvider.gemini: [
    LlmModelOption(
      id: 'gemini-2.5-flash',
      displayName: 'Gemini 2.5 Flash',
      badge: '⚡ Fast',
      description: 'Fast and balanced, ideal for plant care and diagnosis.',
    ),
    LlmModelOption(
      id: 'gemini-2.5-pro',
      displayName: 'Gemini 2.5 Pro',
      badge: '🧠 Smart',
      description: 'Higher accuracy and deeper reasoning for complex queries.',
    ),
    LlmModelOption(
      id: 'gemini-2.5-flash-lite',
      displayName: 'Gemini 2.5 Flash Lite',
      badge: '🪶 Lite',
      description: 'Ultra-fast and efficient for simple tasks.',
    ),
  ],
  AiProvider.openai: [
    LlmModelOption(
      id: 'gpt-4o',
      displayName: 'GPT-4o',
      badge: '🧠 Smart',
      description: 'Highly capable multimodal model for complex tasks.',
    ),
    LlmModelOption(
      id: 'gpt-4o-mini',
      displayName: 'GPT-4o Mini',
      badge: '⚡ Fast',
      description:
          'Fast, affordable, and intelligent model for everyday tasks.',
    ),
  ],
  AiProvider.anthropic: [
    LlmModelOption(
      id: 'claude-3-5-sonnet-latest',
      displayName: 'Claude 3.5 Sonnet',
      badge: '🧠 Smart',
      description: 'Ideal balance of intelligence and speed.',
    ),
    LlmModelOption(
      id: 'claude-3-haiku-20240307',
      displayName: 'Claude 3 Haiku',
      badge: '⚡ Fast',
      description: 'Fastest model for near-instant responses.',
    ),
  ],
};

const Map<AiProvider, String> kDefaultModelByProvider = {
  AiProvider.gemini: 'gemini-2.5-flash',
  AiProvider.openai: 'gpt-4o-mini',
  AiProvider.anthropic: 'claude-3-haiku-20240307',
};
