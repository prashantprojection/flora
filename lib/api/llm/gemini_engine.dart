import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flora/api/llm/llm_engine.dart';
import 'package:flora/models/llm_models.dart';

class GeminiEngine implements LlmEngine {
  late final String _apiKey;

  GeminiEngine() {
    final key = dotenv.env['GEMINI_API_KEY'];
    if (key == null) {
      throw Exception('GEMINI_API_KEY not found in .env file.');
    }
    _apiKey = key;
  }

  // ── Schema Mapper ─────────────────────────────────────────────────────────
  
  Schema _mapToGoogleSchema(Map<String, dynamic> schemaMap) {
    // A simplified mapper for GenUI schema to Google SDK Schema
    final properties = <String, Schema>{};
    
    if (schemaMap.containsKey('properties')) {
      final props = schemaMap['properties'] as Map<String, dynamic>;
      for (final entry in props.entries) {
        final propMap = entry.value as Map<String, dynamic>;
        final propType = propMap['type'] as String? ?? 'string';
        final propDesc = propMap['description'] as String?;
        
        // Map types (string, array, boolean, integer, number)
        SchemaType googleType;
        switch (propType) {
          case 'string': googleType = SchemaType.string; break;
          case 'array': googleType = SchemaType.array; break;
          case 'boolean': googleType = SchemaType.boolean; break;
          case 'integer': googleType = SchemaType.integer; break;
          case 'number': googleType = SchemaType.number; break;
          case 'object': googleType = SchemaType.object; break;
          default: googleType = SchemaType.string;
        }

        // Handle array items specifically
        Schema? itemsSchema;
        if (googleType == SchemaType.array && propMap.containsKey('items')) {
            final itemsMap = propMap['items'] as Map<String, dynamic>;
            itemsSchema = _mapToGoogleSchema(itemsMap);
        }

        properties[entry.key] = Schema(
            googleType, 
            description: propDesc,
            properties: googleType == SchemaType.object ? _mapToGoogleSchema(propMap).properties : null,
            items: itemsSchema,
        );
      }
    }

    return Schema(
      SchemaType.object, 
      properties: properties.isNotEmpty ? properties : null,
      requiredProperties: schemaMap.containsKey('required') 
          ? List<String>.from(schemaMap['required']) 
          : null,
    );
  }

  GenerativeModel _getModel({LlmConfig? config}) {
    List<Tool>? googleTools;

    if (config != null && config.tools != null && config.tools!.isNotEmpty) {
      final functionDeclarations = config.tools!.map((t) {
        return FunctionDeclaration(
          t.name,
          t.description,
          _mapToGoogleSchema(t.schema),
        );
      }).toList();
      googleTools = [Tool(functionDeclarations: functionDeclarations)];
    }

    return GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: _apiKey,
      tools: googleTools,
      generationConfig: GenerationConfig(
        temperature: config?.temperature ?? 0.4,
        maxOutputTokens: config?.maxTokens,
        topK: config?.topK,
      ),
    );
  }

  LlmResponse _parseResponse(GenerateContentResponse response) {
    LlmFunctionCall? funcCall;
    if (response.functionCalls.isNotEmpty) {
      final call = response.functionCalls.first;
      funcCall = LlmFunctionCall(
        name: call.name,
        arguments: call.args,
      );
    }
    
    // We capture BOTH text and the function call if they exist.
    // The text will serve as our context summary, while the function call renders the UI.
    return LlmResponse(
      text: response.text,
      functionCall: funcCall,
    );
  }

  List<Content> _mapMessagesToGoogleContent(List<LlmMessage> messages) {
    return messages.map((m) {
      final role = m.role == LlmRole.user ? 'user' : 'model';
      final parts = <Part>[TextPart(m.text)];
      if (m.image != null) {
        parts.add(DataPart('image/jpeg', m.image!));
      }
      return Content(role, parts);
    }).toList();
  }

  @override
  Future<LlmResponse> generateContent(List<LlmMessage> messages, {LlmConfig? config}) async {
    try {
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
    } catch (e) {
      debugPrint('[GeminiEngine] generateContent failed: $e');
      throw Exception('Gemini generateContent failed');
    }
  }

  @override
  Stream<String> generateTextStream(List<LlmMessage> messages, {LlmConfig? config}) async* {
    try {
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
    } catch (e) {
      debugPrint('[GeminiEngine] generateTextStream failed: $e');
      throw Exception('Gemini generateTextStream failed');
    }
  }
}
