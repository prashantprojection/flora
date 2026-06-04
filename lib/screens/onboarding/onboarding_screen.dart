import 'package:flutter/material.dart';
import 'package:flora/utils/app_assets.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:flora/services/preferences_service.dart';

class OnboardingSlideData {
  final String title;
  final String subtitle;
  final String image;
  final Color color;
  final bool isDark;

  const OnboardingSlideData({
    required this.title,
    required this.subtitle,
    required this.image,
    required this.color,
    required this.isDark,
  });
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingSlideData> _slides = [
    OnboardingSlideData(
      title: 'Welcome to Flora',
      subtitle: 'Meet Flo, your personal plant care companion.',
      image: AppAssets.onboardingSlide1,
      color: const Color(0xFFE8F5E2),
      isDark: false,
    ),
    OnboardingSlideData(
      title: 'Everything you need',
      subtitle: 'AI Care Schedules, Light Meters, and Disease Diagnosis — all without subscriptions or paywalls.',
      image: AppAssets.onboardingSlide2,
      color: const Color(0xFFFFFBEA),
      isDark: false,
    ),
    OnboardingSlideData(
      title: 'Flo AI care',
      subtitle: 'Flo AI creates personalised care schedules tailored to your plant and local climate.',
      image: AppAssets.onboardingSlide3,
      color: const Color(0xFFEAF4FF),
      isDark: false,
    ),
    OnboardingSlideData(
      title: 'Your data stays with you',
      subtitle: 'Plants and photos are stored locally. No accounts, no cloud uploads.',
      image: AppAssets.onboardingSlide4,
      color: const Color(0xFF2E4A3A),
      isDark: true,
    )
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _finishOnboarding() async {
    await PreferencesService.setHasSeenOnboarding(true);
    if (mounted) {
      context.go('/');
    }
  }

  void _nextPage() {
    if (_currentPage < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _finishOnboarding();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentSlide = _slides[_currentPage];
    final isDark = currentSlide.isDark;
    final subtitleColor = isDark ? Colors.white70 : theme.colorScheme.onSurfaceVariant;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      color: currentSlide.color,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
              Align(
                alignment: Alignment.topRight,
                child: TextButton(
                  onPressed: _finishOnboarding,
                  child: Text(
                    'Skip',
                    style: TextStyle(
                      color: subtitleColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                  },
                  itemCount: _slides.length,
                    itemBuilder: (context, index) {
                      final slide = _slides[index];
                      final slideIsDark = slide.isDark;
                      final slideTextColor = slideIsDark ? Colors.white : theme.colorScheme.onSurface;
                      final slideSubtitleColor = slideIsDark ? Colors.white70 : theme.colorScheme.onSurfaceVariant;
                    
                    return Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Center(
                              child: AspectRatio(
                                aspectRatio: 1, // To keep the square vector art
                                child: Image.asset(
                                  slide.image,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 48),
                          Text(
                            slide.title,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: slideTextColor,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            slide.subtitle,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: slideSubtitleColor,
                              height: 1.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: List.generate(
                        _slides.length,
                        (index) => AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.only(right: 8),
                          height: 8,
                          width: _currentPage == index ? 24 : 8,
                          decoration: BoxDecoration(
                            color: _currentPage == index
                                ? (isDark ? Colors.white : theme.colorScheme.primary)
                                : (isDark ? Colors.white38 : theme.colorScheme.primaryContainer),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                    FloatingActionButton(
                      onPressed: _nextPage,
                      backgroundColor: isDark ? Colors.white : theme.colorScheme.primary,
                      foregroundColor: isDark ? Colors.black : theme.colorScheme.onPrimary,
                      elevation: 0,
                      child: Icon(
                        _currentPage == _slides.length - 1
                            ? LucideIcons.check
                            : LucideIcons.arrowRight,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
