import 'package:flutter/foundation.dart';

enum AiProvider { gemini, openai, anthropic }

extension AiProviderX on AiProvider {
  String get stringId {
    switch (this) {
      case AiProvider.gemini:
        return 'gemini';
      case AiProvider.openai:
        return 'openai';
      case AiProvider.anthropic:
        return 'anthropic';
    }
  }

  static AiProvider fromStringId(String id) {
    return AiProvider.values.firstWhere(
      (p) => p.stringId == id,
      orElse: () => AiProvider.gemini,
    );
  }
}

@immutable
class AiProviderOption {
  final AiProvider id;
  final String displayName;
  final bool isSupported;
  final String apiKeyUrl;
  final String apiKeyHint;

  const AiProviderOption({
    required this.id,
    required this.displayName,
    this.isSupported = true,
    required this.apiKeyUrl,
    required this.apiKeyHint,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AiProviderOption &&
        other.id == id &&
        other.displayName == displayName &&
        other.isSupported == isSupported &&
        other.apiKeyUrl == apiKeyUrl &&
        other.apiKeyHint == apiKeyHint;
  }

  @override
  int get hashCode =>
      Object.hash(id, displayName, isSupported, apiKeyUrl, apiKeyHint);
}

const List<AiProviderOption> kAiProviders = [
  AiProviderOption(
    id: AiProvider.gemini,
    displayName: 'Google Gemini',
    apiKeyUrl: 'https://aistudio.google.com/app/apikey',
    apiKeyHint: 'AIzaSy...',
  ),
  AiProviderOption(
    id: AiProvider.openai,
    displayName: 'OpenAI',
    isSupported: true,
    apiKeyUrl: 'https://platform.openai.com/api-keys',
    apiKeyHint: 'sk-proj-...',
  ),
  AiProviderOption(
    id: AiProvider.anthropic,
    displayName: 'Anthropic Claude',
    isSupported: true,
    apiKeyUrl: 'https://console.anthropic.com/settings/keys',
    apiKeyHint: 'sk-ant-...',
  ),
];

final List<AiProviderOption> kSupportedAiProviders = kAiProviders
    .where((p) => p.isSupported)
    .toList();
