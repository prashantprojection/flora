import 'package:flutter/material.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:flora/services/preferences_service.dart';

/// First-launch value proposition card.
/// Shown once on first launch, dismissed via "Start Growing" or tap outside (after 2s).
class OnboardingCard extends StatefulWidget {
  final VoidCallback onDismiss;
  const OnboardingCard({super.key, required this.onDismiss});

  @override
  State<OnboardingCard> createState() => _OnboardingCardState();
}

class _OnboardingCardState extends State<OnboardingCard>
    with TickerProviderStateMixin {
  bool _canDismissByTap = false;
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fadeController.forward();

    // Allow tap-to-dismiss after a very short 500ms delay to prevent accidental dismissals on app launch
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) setState(() => _canDismissByTap = true);
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _dismiss() async {
    await PreferencesService.setHasSeenOnboarding(true);
    widget.onDismiss();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: GestureDetector(
        onTap: _canDismissByTap ? _dismiss : null,
        child: Container(
          color: Colors.black.withValues(alpha: 0.65),
          width: size.width,
          height: size.height,
          child: SafeArea(
            child: Center(
              child: GestureDetector(
                // Prevent tap-through to dismiss when tapping card itself
                onTap: () {},
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        theme.colorScheme.surface,
                        theme.colorScheme.primaryContainer
                            .withValues(alpha: 0.4),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.primary.withValues(alpha: 0.2),
                        blurRadius: 40,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Logo / icon
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              theme.colorScheme.primary,
                              theme.colorScheme.secondary,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color:
                                  theme.colorScheme.primary.withValues(alpha: 0.4),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: const Icon(
                          LucideIcons.sprout,
                          color: Colors.white,
                          size: 36,
                        ),
                      ),
                      const SizedBox(height: 20),

                      Text(
                        'Welcome to Flora 🌿',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Your AI-powered plant care companion',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 28),

                      // 3 differentiators
                      _buildFeatureTile(
                        context,
                        icon: LucideIcons.infinity,
                        color: theme.colorScheme.primary,
                        title: 'Free forever',
                        subtitle:
                            'No subscription, no paywall — every feature, always free.',
                      ),
                      const SizedBox(height: 16),
                      _buildFeatureTile(
                        context,
                        icon: LucideIcons.sparkles,
                        color: theme.colorScheme.secondary,
                        title: 'AI-generated care',
                        subtitle:
                            'Gemini AI creates personalised schedules for your plant and climate — not a static database.',
                      ),
                      const SizedBox(height: 16),
                      _buildFeatureTile(
                        context,
                        icon: LucideIcons.shieldCheck,
                        color: Colors.teal,
                        title: 'Your data stays on your device',
                        subtitle:
                            'Plants and photos are stored locally. No accounts, no cloud uploads.',
                      ),

                      const SizedBox(height: 28),

                      // CTA
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: _dismiss,
                          icon: const Icon(LucideIcons.arrowRight, size: 18),
                          label: const Text(
                            'Start Growing',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.primary,
                            foregroundColor: theme.colorScheme.onPrimary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureTile(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
  }) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
