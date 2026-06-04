import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flora/services/preferences_service.dart';

class AiSettingsState {
  final String activeProvider;
  final String? geminiApiKey; // null means use env fallback
  final String geminiModelId;

  const AiSettingsState({
    required this.activeProvider,
    this.geminiApiKey,
    required this.geminiModelId,
  });

  AiSettingsState copyWith({
    String? activeProvider,
    String? geminiApiKey,
    String? geminiModelId,
  }) {
    return AiSettingsState(
      activeProvider: activeProvider ?? this.activeProvider,
      geminiApiKey: geminiApiKey ?? this.geminiApiKey,
      geminiModelId: geminiModelId ?? this.geminiModelId,
    );
  }
}

class AiSettingsNotifier extends Notifier<AiSettingsState> {
  @override
  AiSettingsState build() {
    return AiSettingsState(
      activeProvider: PreferencesService.activeAiProvider,
      geminiApiKey: PreferencesService.userGeminiApiKey,
      geminiModelId: PreferencesService.selectedGeminiModel,
    );
  }

  Future<void> saveSettings({
    required String activeProvider,
    String? geminiApiKey,
    required String geminiModelId,
  }) async {
    await PreferencesService.setActiveAiProvider(activeProvider);
    await PreferencesService.setUserGeminiApiKey(geminiApiKey);
    await PreferencesService.setSelectedGeminiModel(geminiModelId);

    state = AiSettingsState(
      activeProvider: activeProvider,
      geminiApiKey: geminiApiKey,
      geminiModelId: geminiModelId,
    );
  }

  Future<void> clearApiKey() async {
    await PreferencesService.setUserGeminiApiKey(null);
    state = state.copyWith(geminiApiKey: null);
  }
}

final aiSettingsProvider = NotifierProvider<AiSettingsNotifier, AiSettingsState>(AiSettingsNotifier.new);
