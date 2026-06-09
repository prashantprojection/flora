import 'package:shared_preferences/shared_preferences.dart';
import 'package:flora/models/llm_models.dart';
import 'package:flora/models/llm_providers.dart';

class PreferencesService {
  static late final SharedPreferences _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // --- Onboarding ---
  static bool get hasSeenOnboarding =>
      _prefs.getBool('has_seen_onboarding') ?? false;
  static Future<void> setHasSeenOnboarding(bool value) async {
    await _prefs.setBool('has_seen_onboarding', value);
  }

  // --- AI Tooltip ---
  static bool get hasSeenAiTooltip =>
      _prefs.getBool('has_seen_ai_tooltip') ?? false;
  static Future<void> setHasSeenAiTooltip(bool value) async {
    await _prefs.setBool('has_seen_ai_tooltip', value);
  }

  // --- AI Settings ---
  static AiProvider get activeAiProvider {
    final val = _prefs.getString('active_ai_provider');
    if (val == null) return AiProvider.gemini;
    return AiProviderX.fromStringId(val);
  }

  static Future<void> setActiveAiProvider(AiProvider value) async {
    await _prefs.setString('active_ai_provider', value.stringId);
  }

  static String? getApiKeyForProvider(AiProvider provider) =>
      _prefs.getString('api_key_${provider.stringId}');

  static Future<void> setApiKeyForProvider(
    AiProvider provider,
    String? value,
  ) async {
    final key = 'api_key_${provider.stringId}';
    if (value == null || value.isEmpty) {
      await _prefs.remove(key);
    } else {
      await _prefs.setString(key, value);
    }
  }

  static String get activeModelId {
    final val = _prefs.getString('active_model_id');
    if (val == null) {
      // Default to the default model of the currently active provider
      return kDefaultModelByProvider[activeAiProvider] ?? 'gemini-2.5-flash';
    }
    return val;
  }

  static Future<void> setActiveModelId(String value) async {
    await _prefs.setString('active_model_id', value);
  }
}
