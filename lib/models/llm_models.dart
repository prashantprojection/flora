/// Represents configuration for an LLM engine to control creativity and limits.
class LlmConfig {
  final double? temperature;
  final int? maxTokens;
  final int? topK;
  final List<LlmTool>? tools;

  const LlmConfig({
    this.temperature,
    this.maxTokens,
    this.topK,
    this.tools,
  });
}

/// Represents the role of a message sender in a chat context.
enum LlmRole {
  user,
  model,
}

/// Represents a single message in a multi-turn conversation context.
class LlmMessage {
  final LlmRole role;
  final String text;

  const LlmMessage({
    required this.role,
    required this.text,
  });
}

// ── GenUI (Function Calling) Models ───────────────────────────────────────

/// A tool definition passed to the LLM so it knows what widgets it can render
class LlmTool {
  final String name;
  final String description;
  final Map<String, dynamic> schema; // JSON Schema for the widget's parameters

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

  const LlmFunctionCall({
    required this.name,
    required this.arguments,
  });
}

/// The response from the LLM, which could be raw text OR a request to render GenUI
class LlmResponse {
  final String? text;
  final LlmFunctionCall? functionCall;

  const LlmResponse({
    this.text,
    this.functionCall,
  });

  bool get isFunctionCall => functionCall != null;
}
