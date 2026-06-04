class AiProviderOption {
  final String id;
  final String displayName;
  final bool isSupported;

  const AiProviderOption({
    required this.id,
    required this.displayName,
    this.isSupported = true,
  });
}

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

const kAiProviders = [
  AiProviderOption(
    id: 'gemini',
    displayName: 'Google Gemini',
  ),
  AiProviderOption(
    id: 'openai',
    displayName: 'OpenAI',
    isSupported: false, // For future scalability
  ),
  AiProviderOption(
    id: 'anthropic',
    displayName: 'Anthropic Claude',
    isSupported: false, // For future scalability
  ),
];

const kGeminiModels = [
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
];
