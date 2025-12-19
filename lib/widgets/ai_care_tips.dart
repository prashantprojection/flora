import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flora/api/gemini_service.dart';
import 'package:flora/models/plant.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:intl/intl.dart';

class AICareTips extends ConsumerStatefulWidget {
  final Plant plant;

  const AICareTips({super.key, required this.plant});

  @override
  ConsumerState<AICareTips> createState() => _AICareTipsState();
}

class _AICareTipsState extends ConsumerState<AICareTips> {
  final TextEditingController _additionalDetailsController =
      TextEditingController();
  bool _loading = false;
  String _careTips = '';

  @override
  void initState() {
    super.initState();
    if (widget.plant.careInstructions != null &&
        widget.plant.careInstructions!.isNotEmpty) {
      _careTips = widget.plant.careInstructions!;
    }
    _additionalDetailsController.addListener(() {
      setState(
        () {},
      ); // Rebuilds the widget when text changes to update button state
    });
  }

  @override
  void dispose() {
    _additionalDetailsController.dispose();
    super.dispose();
  }

  Future<void> _handleGenerateTips() async {
    setState(() {
      _loading = true;
      _careTips = '';
    });

    try {
      final geminiService = ref.read(geminiServiceProvider);
      final result = await geminiService.generateCareTips(
        plantName: widget.plant.name,
        species: widget.plant.species,
        plantingDate: DateFormat(
          'yyyy-MM-dd',
        ).format(widget.plant.plantingDate),
        location: widget.plant.location ?? "Not Specified",
        additionalDetails: _additionalDetailsController.text,
      );

      if (result.isNotEmpty) {
        setState(() {
          _careTips = result;
        });
      } else {
        throw Exception('No tips were generated.');
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Could not generate care tips. Please try again later.",
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1. Separate Seasonal Tips from specific User Query Generator
    final seasonalTips = _parseSeasonalTips(_careTips);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // --- 1. Seasonal Care Cards (Collapsible Carousel) ---
        if (seasonalTips.isNotEmpty) ...[
          Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              initiallyExpanded: false,
              tilePadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              title: Text(
                'Seasonal Care Guide',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                'Tap to hide seasonal advice',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              children: [
                _SeasonalCarousel(seasonalTips: seasonalTips),
                const SizedBox(height: 16),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],

        // --- 2. AI Generator / Q&A Section ---
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          elevation: 0,
          color: Theme.of(context).colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            // Border removed as per user request
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Theme.of(context).colorScheme.primary,
                            Theme.of(
                              context,
                            ).colorScheme.primary.withOpacity(0.7),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(
                              context,
                            ).colorScheme.primary.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        LucideIcons.sparkles,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'AI Plant Care Tips',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Ask specific questions or get more tips',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _additionalDetailsController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: "e.g., 'Why are the leaves yellow?'",
                    hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                    filled: true,
                    fillColor: Theme.of(context).scaffoldBackgroundColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                  enabled: !_loading,
                ),
                const SizedBox(height: 12),

                if (_loading)
                  Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  )
                else
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed:
                          _loading || _additionalDetailsController.text.isEmpty
                          ? null
                          : _handleGenerateTips,
                      icon: Icon(
                        LucideIcons.sparkles,
                        color: Colors.white,
                        size: 20,
                      ),
                      label: const Text('Ask AI'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),

                // Show non-seasonal fallback tips if any
                if (_careTips.isNotEmpty && seasonalTips.isEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                    ),
                    child: Text(_careTips),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Map<String, String> _parseSeasonalTips(String tips) {
    Map<String, String> seasons = {};
    final regex = RegExp(
      r'(Spring|Summer|Autumn|Winter):\s*(.*?)(?=(Spring|Summer|Autumn|Winter):|$)',
      caseSensitive: false,
      dotAll: true,
    );

    final matches = regex.allMatches(tips);
    for (final match in matches) {
      if (match.groupCount >= 2) {
        seasons[match.group(1)!] = match.group(2)!.trim();
      }
    }
    return seasons;
  }
}

class _SeasonalCarousel extends StatefulWidget {
  final Map<String, String> seasonalTips;
  const _SeasonalCarousel({required this.seasonalTips});

  @override
  State<_SeasonalCarousel> createState() => _SeasonalCarouselState();
}

class _SeasonalCarouselState extends State<_SeasonalCarousel> {
  late PageController _pageController;
  late List<MapEntry<String, String>> _entries;
  int _currentPage = 0;
  Map<int, double> _heights = {};
  double _currentHeight = 300; // Default fallback height

  @override
  void initState() {
    super.initState();
    _entries = widget.seasonalTips.entries.toList();
    _currentPage = _getCurrentSeasonIndex();
    _pageController = PageController(
      initialPage: _currentPage,
      viewportFraction: 0.92,
    );
  }

  int _getCurrentSeasonIndex() {
    final now = DateTime.now();
    final month = now.month;
    String currentSeason;
    if (month >= 3 && month <= 5)
      currentSeason = 'Spring';
    else if (month >= 6 && month <= 8)
      currentSeason = 'Summer';
    else if (month >= 9 && month <= 11)
      currentSeason = 'Autumn';
    else
      currentSeason = 'Winter';
    int index = _entries.indexWhere(
      (e) => e.key.toLowerCase() == currentSeason.toLowerCase(),
    );
    return index != -1 ? index : 0;
  }

  void _onSizeChanged(int index, Size size) {
    if (_heights[index] == size.height) return;

    // Defer state update to avoid build-phase errors
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _heights[index] = size.height;
          if (index == _currentPage) {
            _currentHeight = size.height;
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // If we have a measured height for the current page, use it.
    // Otherwise keep the previous valid height to prevent jumps.
    final targetHeight = _heights[_currentPage] ?? _currentHeight;

    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutQuart,
          height: targetHeight,
          child: PageView.builder(
            controller: _pageController,
            itemCount: _entries.length,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
                if (_heights.containsKey(index)) {
                  _currentHeight = _heights[index]!;
                }
              });
            },
            itemBuilder: (context, index) {
              final entry = _entries[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: OverflowBox(
                  minHeight: 0,
                  maxHeight: double.infinity,
                  alignment: Alignment.topCenter,
                  // MeasureSize must be INSIDE OverflowBox to report the intrinsic size
                  child: MeasureSize(
                    onChange: (size) => _onSizeChanged(index, size),
                    child: _buildSeasonalCard(context, entry.key, entry.value),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        // Indicators (unchanged)
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_entries.length, (index) {
            final isActive = _currentPage == index;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              height: 6,
              width: isActive ? 16 : 6,
              decoration: BoxDecoration(
                color: isActive
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(3),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildSeasonalCard(BuildContext context, String season, String tip) {
    final theme = Theme.of(context);
    String assetName;

    switch (season.toLowerCase()) {
      case 'spring':
        assetName = 'assets/images/spring_banner.png';
        break;
      case 'summer':
        assetName = 'assets/images/summer_banner.png';
        break;
      case 'autumn':
        assetName = 'assets/images/autumn_banner.png';
        break;
      case 'winter':
        assetName = 'assets/images/winter_banner.png';
        break;
      default:
        assetName = 'assets/images/spring_banner.png';
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: theme.colorScheme.surfaceContainer,
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Banner Image - Reduced to 70 as requested
          SizedBox(
            height: 70,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  assetName,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: theme.colorScheme.surfaceContainerHighest,
                  ),
                ),
                // Gradient for text readability
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.7),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  bottom: 8,
                  left: 16,
                  child: Row(
                    children: [
                      Icon(
                        _getSeasonIcon(season),
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        season.toUpperCase(),
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Full Text Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              tip,
              style: theme.textTheme.bodyMedium?.copyWith(
                height: 1.5,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getSeasonIcon(String season) {
    switch (season.toLowerCase()) {
      case 'spring':
        return LucideIcons.sprout;
      case 'summer':
        return LucideIcons.sun;
      case 'autumn':
        return LucideIcons.leaf;
      case 'winter':
        return LucideIcons.snowflake;
      default:
        return LucideIcons.calendar;
    }
  }
}

// Helper Widget to measure size of its child
class MeasureSize extends StatefulWidget {
  final Widget child;
  final ValueChanged<Size> onChange;

  const MeasureSize({Key? key, required this.child, required this.onChange})
    : super(key: key);

  @override
  _MeasureSizeState createState() => _MeasureSizeState();
}

class _MeasureSizeState extends State<MeasureSize> {
  @override
  Widget build(BuildContext context) {
    return _MeasureSizeRenderObject(
      onChange: widget.onChange,
      child: widget.child,
    );
  }
}

class _MeasureSizeRenderObject extends SingleChildRenderObjectWidget {
  final ValueChanged<Size> onChange;

  const _MeasureSizeRenderObject({
    Key? key,
    required this.onChange,
    required Widget child,
  }) : super(key: key, child: child);

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _MeasureSizeRenderBox(onChange);
  }

  @override
  void updateRenderObject(
    BuildContext context,
    _MeasureSizeRenderBox renderObject,
  ) {
    renderObject.onChange = onChange;
  }
}

class _MeasureSizeRenderBox extends RenderProxyBox {
  ValueChanged<Size> onChange;
  Size? _oldSize;

  _MeasureSizeRenderBox(this.onChange);

  @override
  void performLayout() {
    super.performLayout();
    final child = this.child;
    if (child != null) {
      final newSize = child.size;
      if (_oldSize == newSize) return;
      _oldSize = newSize;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        onChange(newSize);
      });
    }
  }
}
