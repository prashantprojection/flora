import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flora/services/preferences_service.dart';
import 'package:flora/models/llm_models.dart';
import 'package:flora/models/llm_providers.dart';

class AiSettingsState {
  final AiProvider activeProvider;
  final Map<AiProvider, String?> apiKeys;
  final String activeModelId;

  const AiSettingsState({
    required this.activeProvider,
    this.apiKeys = const {},
    required this.activeModelId,
  });

  String? get activeApiKey => apiKeys[activeProvider];

  AiSettingsState copyWith({
    AiProvider? activeProvider,
    Map<AiProvider, String?>? apiKeys,
    String? activeModelId,
  }) {
    return AiSettingsState(
      activeProvider: activeProvider ?? this.activeProvider,
      apiKeys: apiKeys ?? this.apiKeys,
      activeModelId: activeModelId ?? this.activeModelId,
    );
  }
}

class AiSettingsNotifier extends Notifier<AiSettingsState> {
  // Precondition: PreferencesService.init() must be called in main() before runApp.
  @override
  AiSettingsState build() {
    final Map<AiProvider, String?> keys = {};
    for (final provider in AiProvider.values) {
      keys[provider] = PreferencesService.getApiKeyForProvider(provider);
    }

    return AiSettingsState(
      activeProvider: PreferencesService.activeAiProvider,
      apiKeys: keys,
      activeModelId: PreferencesService.activeModelId,
    );
  }

  Future<void> saveSettings({
    required AiProvider activeProvider,
    String? apiKey,
    required String activeModelId,
  }) async {
    // If provider changed, validate if the current modelId is valid for the new provider
    String finalModelId = activeModelId;
    final availableModels = kModelsByProvider[activeProvider] ?? [];
    if (!availableModels.any((m) => m.id == finalModelId)) {
      finalModelId = kDefaultModelByProvider[activeProvider] ?? finalModelId;
    }

    await PreferencesService.setActiveAiProvider(activeProvider);
    await PreferencesService.setApiKeyForProvider(activeProvider, apiKey);
    await PreferencesService.setActiveModelId(finalModelId);

    final newApiKeys = Map<AiProvider, String?>.from(state.apiKeys);
    newApiKeys[activeProvider] = apiKey;

    state = AiSettingsState(
      activeProvider: activeProvider,
      apiKeys: newApiKeys,
      activeModelId: finalModelId,
    );
  }

  Future<void> saveActiveModel(String modelId) async {
    await PreferencesService.setActiveModelId(modelId);
    state = state.copyWith(activeModelId: modelId);
  }
}

final aiSettingsProvider =
    NotifierProvider<AiSettingsNotifier, AiSettingsState>(
      AiSettingsNotifier.new,
    );
