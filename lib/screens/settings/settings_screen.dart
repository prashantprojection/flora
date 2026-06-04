import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flora/utils/app_theme.dart';
import 'package:flora/providers/ai_settings_provider.dart';
import 'package:flora/models/llm_providers.dart';
import 'package:flora/api/llm/gemini_engine.dart';
import 'package:flora/models/llm_models.dart';
import 'package:flora/widgets/animated_press.dart';
import 'package:flora/utils/network_utils.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final TextEditingController _apiKeyController = TextEditingController();
  bool _obscureKey = true;
  bool _isValidating = false;
  String _selectedModelId = 'gemini-2.5-flash';
  String _activeProviderId = 'gemini';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final settings = ref.read(aiSettingsProvider);
      _activeProviderId = settings.activeProvider;
      _selectedModelId = settings.geminiModelId;
      _apiKeyController.text = settings.geminiApiKey ?? '';
      setState(() {});
    });
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _validateAndSave() async {
    FocusScope.of(context).unfocus();
    final newKey = _apiKeyController.text.trim();

    if (newKey.isEmpty) {
      // User just wants to clear the key
      await ref.read(aiSettingsProvider.notifier).clearApiKey();
      await ref.read(aiSettingsProvider.notifier).saveSettings(
        activeProvider: _activeProviderId,
        geminiApiKey: null,
        geminiModelId: _selectedModelId,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Personal API key cleared. Using shared fallback key.'),
          backgroundColor: AppTheme.primary,
        ),
      );
      return;
    }

    setState(() => _isValidating = true);

    try {
      final hasInternet = await NetworkUtils.hasInternetConnection();
      if (!hasInternet) {
        throw Exception('No internet connection. Cannot validate key.');
      }

      // Temporary engine to test the key
      final testEngine = GeminiEngine(apiKey: newKey, modelId: _selectedModelId);
      await testEngine.generateContent([
        const LlmMessage(role: LlmRole.user, text: "Respond with 'ok' if you receive this.")
      ]);

      // Success
      await ref.read(aiSettingsProvider.notifier).saveSettings(
        activeProvider: _activeProviderId,
        geminiApiKey: newKey,
        geminiModelId: _selectedModelId,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('API Key validated and saved successfully! ✅'),
          backgroundColor: AppTheme.primary,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Validation failed: Invalid key or network issue.'),
          backgroundColor: AppTheme.destructive,
        ),
      );
    } finally {
      if (mounted) setState(() => _isValidating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = ref.watch(aiSettingsProvider);
    final hasUserKey = settings.geminiApiKey != null && settings.geminiApiKey!.isNotEmpty;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('AI Settings'),
        centerTitle: true,
        backgroundColor: AppTheme.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacing_4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Provider Selection (Scalability for future)
            Text(
              'AI Provider',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: AppTheme.spacing_2),
            Container(
              decoration: BoxDecoration(
                color: AppTheme.card,
                borderRadius: BorderRadius.circular(AppTheme.borderRadiusLg),
                border: Border.all(color: AppTheme.border),
              ),
              child: Column(
                children: kAiProviders.map((provider) {
                  final isSelected = _activeProviderId == provider.id;
                  return RadioListTile<String>(
                    title: Text(
                      provider.displayName,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: provider.isSupported ? AppTheme.foreground : AppTheme.mutedForeground,
                      ),
                    ),
                    subtitle: !provider.isSupported ? const Text('Coming soon') : null,
                    value: provider.id,
                    groupValue: _activeProviderId,
                    activeColor: AppTheme.primary,
                    onChanged: provider.isSupported
                        ? (value) {
                            if (value != null) setState(() => _activeProviderId = value);
                          }
                        : null,
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: AppTheme.spacing_6),

            // API Key Input
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Your Personal API Key',
                  style: theme.textTheme.titleMedium,
                ),
                if (hasUserKey)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Row(
                      children: [
                        const Icon(LucideIcons.checkCircle2, size: 14, color: AppTheme.primary),
                        const SizedBox(width: 4),
                        Text(
                          'Active',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: AppTheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppTheme.spacing_2),
            Text(
              'Flora uses a shared fallback key by default. By providing your own key, you ensure uninterrupted access to AI features without rate limits.',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: AppTheme.spacing_3),
            
            TextFormField(
              controller: _apiKeyController,
              obscureText: _obscureKey,
              decoration: InputDecoration(
                hintText: 'AIzaSy...',
                filled: true,
                fillColor: AppTheme.input,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.borderRadiusMd),
                  borderSide: const BorderSide(color: AppTheme.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.borderRadiusMd),
                  borderSide: const BorderSide(color: AppTheme.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.borderRadiusMd),
                  borderSide: const BorderSide(color: AppTheme.ring, width: 2),
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureKey ? LucideIcons.eye : LucideIcons.eyeOff,
                    color: AppTheme.mutedForeground,
                  ),
                  onPressed: () {
                    setState(() => _obscureKey = !_obscureKey);
                  },
                ),
              ),
            ),
            const SizedBox(height: AppTheme.spacing_2),
            
            // Link to get key
            GestureDetector(
              onTap: () => _launchUrl('https://aistudio.google.com/app/apikey'),
              child: Row(
                children: [
                  const Icon(LucideIcons.externalLink, size: 14, color: AppTheme.primary),
                  const SizedBox(width: 4),
                  Text(
                    'Get a free API key from Google AI Studio',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: AppTheme.spacing_4),

            AnimatedPress(
              onTap: _isValidating ? null : _validateAndSave,
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.circular(AppTheme.borderRadiusMd),
                ),
                alignment: Alignment.center,
                child: _isValidating
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryForeground),
                        ),
                      )
                    : Text(
                        'Save & Validate',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: AppTheme.primaryForeground,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: AppTheme.spacing_6),

            // Model Selection
            Text(
              'Preferred Model',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: AppTheme.spacing_2),
            Text(
              'Select which Gemini model to use for health checks and care advice. Applies globally.',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: AppTheme.spacing_3),

            ...kGeminiModels.map((model) {
              final isSelected = _selectedModelId == model.id;
              return Padding(
                padding: const EdgeInsets.only(bottom: AppTheme.spacing_2),
                child: InkWell(
                  onTap: () {
                    setState(() => _selectedModelId = model.id);
                    // Also auto-save if changing model (without validating API key)
                    ref.read(aiSettingsProvider.notifier).saveSettings(
                      activeProvider: _activeProviderId,
                      geminiApiKey: _apiKeyController.text.trim().isEmpty ? null : _apiKeyController.text.trim(),
                      geminiModelId: model.id,
                    );
                  },
                  borderRadius: BorderRadius.circular(AppTheme.borderRadiusLg),
                  child: Container(
                    padding: const EdgeInsets.all(AppTheme.spacing_3),
                    decoration: BoxDecoration(
                      color: AppTheme.card,
                      borderRadius: BorderRadius.circular(AppTheme.borderRadiusLg),
                      border: Border.all(
                        color: isSelected ? AppTheme.primary : AppTheme.border,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Radio<String>(
                          value: model.id,
                          groupValue: _selectedModelId,
                          activeColor: AppTheme.primary,
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _selectedModelId = val);
                              ref.read(aiSettingsProvider.notifier).saveSettings(
                                activeProvider: _activeProviderId,
                                geminiApiKey: _apiKeyController.text.trim().isEmpty ? null : _apiKeyController.text.trim(),
                                geminiModelId: val,
                              );
                            }
                          },
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    model.displayName,
                                    style: theme.textTheme.bodyLarge?.copyWith(
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    ),
                                  ),
                                  const SizedBox(width: AppTheme.spacing_2),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppTheme.accent.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      model.badge,
                                      style: theme.textTheme.labelSmall?.copyWith(
                                        color: AppTheme.accentForeground,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                model.description,
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
