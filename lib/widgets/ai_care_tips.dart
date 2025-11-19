import 'package:flutter/material.dart';
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
    return Card(
      margin: EdgeInsets.zero, // Remove default margin
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              16.0,
              16.0,
              16.0,
              8.0,
            ), // Adjust padding
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      LucideIcons.lightbulb,
                      color: Theme.of(context).colorScheme.secondary,
                    ), // text-accent
                    const SizedBox(width: 8),
                    Text(
                      'AI-Powered Care Tips',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        // fontFamily: 'Headline', // Assuming you have a Headline font
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Get personalized care tips for your ${widget.plant.name} based on its details.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _additionalDetailsController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText:
                        "Add any additional details, e.g., 'leaves are turning yellow', 'slow growth'.",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.primary,
                        width: 2.0,
                      ),
                    ),
                  ),
                  enabled: !_loading,
                ),
                if (_loading)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Center(
                      child: Column(
                        children: [
                          CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Generating tips...',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ),
                if (_careTips.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 16.0),
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest
                          .withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(8.0),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Personalized Tips:',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _careTips,
                          style: Theme.of(
                            context,
                          ).textTheme.bodyMedium?.copyWith(height: 1.5),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading || _additionalDetailsController.text.isEmpty
                    ? null
                    : _handleGenerateTips,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                child: _loading
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            LucideIcons.loader,
                            size: 20,
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Generating Tips',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onPrimary,
                            ),
                          ),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            LucideIcons.lightbulb,
                            size: 20,
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Generate Tips',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onPrimary,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
