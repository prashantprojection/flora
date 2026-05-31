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
}
