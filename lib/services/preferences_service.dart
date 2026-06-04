import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static late final SharedPreferences _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // --- Onboarding ---
  static bool get hasSeenOnboarding => _prefs.getBool('has_seen_onboarding') ?? false;
  static Future<void> setHasSeenOnboarding(bool value) async {
    await _prefs.setBool('has_seen_onboarding', value);
  }

  // --- AI Tooltip ---
  static bool get hasSeenAiTooltip => _prefs.getBool('has_seen_ai_tooltip') ?? false;
  static Future<void> setHasSeenAiTooltip(bool value) async {
    await _prefs.setBool('has_seen_ai_tooltip', value);
  }

  // --- AI Settings ---
  static String get activeAiProvider => _prefs.getString('active_ai_provider') ?? 'gemini';
  static Future<void> setActiveAiProvider(String value) async {
    await _prefs.setString('active_ai_provider', value);
  }

  static String? get userGeminiApiKey => _prefs.getString('user_gemini_api_key');
  static Future<void> setUserGeminiApiKey(String? value) async {
    if (value == null || value.isEmpty) {
      await _prefs.remove('user_gemini_api_key');
    } else {
      await _prefs.setString('user_gemini_api_key', value);
    }
  }

  static String get selectedGeminiModel => _prefs.getString('user_gemini_model') ?? 'gemini-2.5-flash';
  static Future<void> setSelectedGeminiModel(String value) async {
    await _prefs.setString('user_gemini_model', value);
  }
}
