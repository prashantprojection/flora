import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flora/utils/app_theme.dart';
import 'package:flora/providers/ai_settings_provider.dart';
import 'package:flora/models/llm_providers.dart';
import 'package:flora/models/llm_models.dart';
import 'package:flora/widgets/animated_press.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final TextEditingController _apiKeyController = TextEditingController();
  bool _obscureKey = true;
  late String _selectedModelId;
  late AiProvider _activeProviderId;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(aiSettingsProvider);
    _activeProviderId = settings.activeProvider;
    _selectedModelId = settings.activeModelId;
    _apiKeyController.text = settings.apiKeys[_activeProviderId] ?? '';
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Could not open the link automatically.'),
            backgroundColor: AppTheme.destructive,
            action: SnackBarAction(
              label: 'Copy Link',
              textColor: Colors.white,
              onPressed: () {
                Clipboard.setData(ClipboardData(text: url));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Link copied to clipboard!'),
                    backgroundColor: AppTheme.primary,
                  ),
                );
              },
            ),
          ),
        );
      }
    }
  }

  Future<void> _saveSettings() async {
    FocusScope.of(context).unfocus();
    final newKey = _apiKeyController.text.trim();

    try {
      await ref
          .read(aiSettingsProvider.notifier)
          .saveSettings(
            activeProvider: _activeProviderId,
            apiKey: newKey.isEmpty ? null : newKey,
            activeModelId: _selectedModelId,
          );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            newKey.isEmpty
                ? 'Personal API key cleared. Using shared fallback key.'
                : 'API Key saved successfully! ✅',
          ),
          backgroundColor: AppTheme.primary,
        ),
      );
    } catch (e) {
      debugPrint('[SettingsScreen] Failed to save settings: $e');
    }
  }

  Future<void> _onModelSelected(String modelId) async {
    if (_selectedModelId == modelId) return;
    setState(() => _selectedModelId = modelId);

    try {
      await ref.read(aiSettingsProvider.notifier).saveActiveModel(modelId);
    } catch (e) {
      debugPrint('[SettingsScreen] Failed to save model: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = ref.watch(aiSettingsProvider);
    final hasUserKey = settings.apiKeys[_activeProviderId]?.isNotEmpty ?? false;

    // Find the active provider option to get its hint and url
    final activeProviderOption = kAiProviders.firstWhere(
      (p) => p.id == _activeProviderId,
      orElse: () => kAiProviders.first,
    );

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
            Text('AI Provider', style: theme.textTheme.titleMedium),
            const SizedBox(height: AppTheme.spacing_2),
            Container(
              decoration: BoxDecoration(
                color: AppTheme.card,
                borderRadius: BorderRadius.circular(AppTheme.borderRadiusLg),
                border: Border.all(color: AppTheme.border),
              ),
              child: RadioGroup<AiProvider>(
                groupValue: _activeProviderId,
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _activeProviderId = value;
                      // Update key field for the new provider
                      _apiKeyController.text = settings.apiKeys[value] ?? '';
                      // Fallback model if we switch providers and current model is invalid
                      final available =
                          kModelsByProvider[_activeProviderId] ?? [];
                      if (!available.any((m) => m.id == _selectedModelId)) {
                        _selectedModelId =
                            kDefaultModelByProvider[_activeProviderId] ??
                            'gemini-2.5-flash';
                      }
                    });
                    _onModelSelected(_selectedModelId);
                  }
                },
                child: Column(
                  children: kAiProviders.map((provider) {
                    final tile = RadioListTile<AiProvider>(
                      title: Text(
                        provider.displayName,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: provider.isSupported
                              ? AppTheme.foreground
                              : AppTheme.mutedForeground,
                        ),
                      ),
                      subtitle: !provider.isSupported
                          ? const Text('Coming soon')
                          : null,
                      value: provider.id,
                      activeColor: AppTheme.primary,
                    );

                    if (!provider.isSupported) {
                      return IgnorePointer(
                        child: Opacity(opacity: 0.6, child: tile),
                      );
                    }
                    return tile;
                  }).toList(),
                ),
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          LucideIcons.checkCircle2,
                          size: 14,
                          color: AppTheme.primary,
                        ),
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

            TextField(
              controller: _apiKeyController,
              obscureText: _obscureKey,
              decoration: InputDecoration(
                hintText: activeProviderOption.apiKeyHint,
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
            InkWell(
              onTap: () => _launchUrl(activeProviderOption.apiKeyUrl),
              borderRadius: BorderRadius.circular(AppTheme.borderRadiusSm),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      LucideIcons.externalLink,
                      size: 14,
                      color: AppTheme.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Get a free API key from ${activeProviderOption.displayName}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: AppTheme.spacing_4),

            AnimatedPress(
              onTap: _saveSettings,
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.circular(AppTheme.borderRadiusMd),
                ),
                alignment: Alignment.center,
                child: Text(
                  'Save Settings',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: AppTheme.primaryForeground,
                  ),
                ),
              ),
            ),

            const SizedBox(height: AppTheme.spacing_6),

            // Model Selection
            Text('Preferred Model', style: theme.textTheme.titleMedium),
            const SizedBox(height: AppTheme.spacing_2),
            Text(
              'Select which model to use for health checks and care advice. Applies globally.',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: AppTheme.spacing_3),
            RadioGroup<String>(
              groupValue: _selectedModelId,
              onChanged: (val) {
                if (val != null) _onModelSelected(val);
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: (kModelsByProvider[_activeProviderId] ?? []).map((
                  model,
                ) {
                  final isSelected = _selectedModelId == model.id;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppTheme.spacing_2),
                    child: InkWell(
                      onTap: () => _onModelSelected(model.id),
                      borderRadius: BorderRadius.circular(
                        AppTheme.borderRadiusLg,
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(AppTheme.spacing_3),
                        decoration: BoxDecoration(
                          color: AppTheme.card,
                          borderRadius: BorderRadius.circular(
                            AppTheme.borderRadiusLg,
                          ),
                          border: Border.all(
                            color: isSelected
                                ? AppTheme.primary
                                : AppTheme.border,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Radio<String>(
                              value: model.id,
                              activeColor: AppTheme.primary,
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        model.displayName,
                                        style: theme.textTheme.bodyLarge
                                            ?.copyWith(
                                              fontWeight: isSelected
                                                  ? FontWeight.bold
                                                  : FontWeight.normal,
                                            ),
                                      ),
                                      const SizedBox(width: AppTheme.spacing_2),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppTheme.accent.withValues(
                                            alpha: 0.2,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: Text(
                                          model.badge,
                                          style: theme.textTheme.labelSmall
                                              ?.copyWith(
                                                color:
                                                    AppTheme.accentForeground,
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
                }).toList(),
              ),
            ),

            const SizedBox(height: AppTheme.spacing_6),
          ],
        ),
      ),
    );
  }
}
