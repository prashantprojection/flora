import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flora/api/llm/llm_engine.dart';
import 'package:flora/models/llm_models.dart';

class GeminiEngine extends LlmEngine {
  GeminiEngine({String? apiKey, String? modelId}) : super(apiKey: apiKey ?? '', modelId: modelId ?? 'gemini-2.5-flash');

  // ── Schema Mapper ─────────────────────────────────────────────────────────

  Schema _mapToGoogleSchema(Map<String, dynamic> schemaMap) {
    final typeStr = schemaMap['type'] as String? ?? 'object';
    final description = schemaMap['description'] as String?;

    SchemaType googleType;
    switch (typeStr) {
      case 'string':
        googleType = SchemaType.string;
        break;
      case 'array':
        googleType = SchemaType.array;
        break;
      case 'boolean':
        googleType = SchemaType.boolean;
        break;
      case 'integer':
        googleType = SchemaType.integer;
        break;
      case 'number':
        googleType = SchemaType.number;
        break;
      case 'object':
      default:
        googleType = SchemaType.object;
    }

    if (googleType == SchemaType.array) {
      Schema? itemsSchema;
      if (schemaMap.containsKey('items')) {
        itemsSchema = _mapToGoogleSchema(schemaMap['items'] as Map<String, dynamic>);
      }
      return Schema(googleType, description: description, items: itemsSchema);
    }

    if (googleType == SchemaType.object) {
      final properties = <String, Schema>{};
      if (schemaMap.containsKey('properties')) {
        final props = schemaMap['properties'] as Map<String, dynamic>;
        for (final entry in props.entries) {
          properties[entry.key] = _mapToGoogleSchema(entry.value as Map<String, dynamic>);
        }
      }
      return Schema(
        googleType,
        description: description,
        properties: properties.isNotEmpty ? properties : null,
        requiredProperties: schemaMap.containsKey('required') ? List<String>.from(schemaMap['required']) : null,
      );
    }

    // Primitive types (string, boolean, integer, number)
    return Schema(googleType, description: description);
  }

  // Cache tool definitions to avoid re-mapping schemas on every API call.
  List<Tool>? _cachedTools;

  GenerativeModel _getModel({LlmConfig? config}) {
    final hasTools = config != null && config.tools != null && config.tools!.isNotEmpty;

    List<Tool>? googleTools;
    if (hasTools) {
      if (_cachedTools == null) {
        final functionDeclarations = config.tools!.map((t) {
          return FunctionDeclaration(t.name, t.description, _mapToGoogleSchema(t.schema));
        }).toList();
        _cachedTools = [Tool(functionDeclarations: functionDeclarations)];
      }
      googleTools = _cachedTools;
    }

    // Always create a new GenerativeModel to pick up per-call config
    // (temperature, maxTokens, etc.). This is cheap since tools are cached.
    return GenerativeModel(
      model: modelId,
      apiKey: apiKey,
      tools: googleTools,
      generationConfig: GenerationConfig(temperature: config?.temperature ?? 0.4, maxOutputTokens: config?.maxTokens, topK: config?.topK),
    );
  }

  LlmResponse _parseResponse(GenerateContentResponse response) {
    LlmFunctionCall? funcCall;
    if (response.functionCalls.isNotEmpty) {
      final call = response.functionCalls.first;
      funcCall = LlmFunctionCall(name: call.name, arguments: call.args);
    }

    // We capture BOTH text and the function call if they exist.
    // The text will serve as our context summary, while the function call renders the UI.
    return LlmResponse(text: response.text, functionCall: funcCall);
  }

  List<Content> _mapMessagesToGoogleContent(List<LlmMessage> messages) {
    return messages.map((m) {
      final role = m.role == LlmRole.user ? 'user' : 'model';
      final parts = <Part>[];
      // Image MUST come before text for Gemini vision to work reliably
      if (m.image != null) {
        parts.add(DataPart(_detectMimeType(m.image!), m.image!));
      }
      parts.add(TextPart(m.text));
      return Content(role, parts);
    }).toList();
  }

  /// Detects image MIME type from magic bytes header.
  /// Falls back to 'image/jpeg' for unknown formats.
  String _detectMimeType(Uint8List bytes) {
    if (bytes.length < 4) return 'image/jpeg';
    // PNG: 89 50 4E 47
    if (bytes[0] == 0x89 && bytes[1] == 0x50 && bytes[2] == 0x4E && bytes[3] == 0x47) {
      return 'image/png';
    }
    // WebP: 52 49 46 46 ?? ?? ?? ?? 57 45 42 50
    if (bytes.length >= 12 && bytes[0] == 0x52 && bytes[1] == 0x49 && bytes[2] == 0x46 && bytes[3] == 0x46 && bytes[8] == 0x57 && bytes[9] == 0x45 && bytes[10] == 0x42 && bytes[11] == 0x50) {
      return 'image/webp';
    }
    // GIF: 47 49 46
    if (bytes[0] == 0x47 && bytes[1] == 0x49 && bytes[2] == 0x46) {
      return 'image/gif';
    }
    return 'image/jpeg'; // default
  }

  @override
  Future<LlmResponse> doGenerateContent(List<LlmMessage> messages, {LlmConfig? config}) async {
    final model = _getModel(config: config);
    final content = _mapMessagesToGoogleContent(messages);

    if (content.isEmpty) {
      throw Exception('Cannot generate content with an empty message list.');
    }

    GenerateContentResponse response;
    if (content.length == 1) {
      // Single-turn request
      response = await model.generateContent(content);
    } else {
      // Multi-turn chat
      final history = content.sublist(0, content.length - 1);
      final chat = model.startChat(history: history);
      response = await chat.sendMessage(content.last);
    }

    return _parseResponse(response);
  }

  @override
  Stream<String> doGenerateTextStream(List<LlmMessage> messages, {LlmConfig? config}) async* {
    final model = _getModel(config: config);
    final content = _mapMessagesToGoogleContent(messages);

    if (content.isEmpty) {
      throw Exception('Cannot generate stream with an empty message list.');
    }

    Stream<GenerateContentResponse> responseStream;
    if (content.length == 1) {
      responseStream = model.generateContentStream(content);
    } else {
      final history = content.sublist(0, content.length - 1);
      final chat = model.startChat(history: history);
      responseStream = chat.sendMessageStream(content.last);
    }

    await for (final chunk in responseStream) {
      if (chunk.text != null && chunk.text!.isNotEmpty) {
        yield chunk.text!;
      }
    }
  }
}
