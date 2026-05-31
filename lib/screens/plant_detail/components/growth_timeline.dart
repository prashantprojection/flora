import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:flora/models/plant.dart';
import 'package:flora/models/care_event.dart';

class GrowthTimeline extends StatelessWidget {
  final Plant plant;
  const GrowthTimeline({super.key, required this.plant});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Extract all care history events that have photos
    final photoEvents = plant.careHistory
        .where((e) => e.photoUrl != null && e.photoUrl!.isNotEmpty)
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date)); // Oldest to newest

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: [
              Icon(
                LucideIcons.images,
                size: 18,
                color: theme.colorScheme.secondary,
              ),
              const SizedBox(width: 8),
              Text(
                'Growth Journal (${photoEvents.length})',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        if (photoEvents.isEmpty)
          _buildEmptyState(context)
        else ...[
          if (photoEvents.length >= 2) ...[
            _buildBeforeAfterCard(context, photoEvents),
            const SizedBox(height: 16),
          ],
          _buildTimelineStrip(context, photoEvents),
        ],
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              shape: BoxShape.circle,
            ),
            child: Icon(
              LucideIcons.camera,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'No photos yet',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Add progress photos when logging care events to see your plant grow!',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBeforeAfterCard(BuildContext context, List<CareEvent> events) {
    final theme = Theme.of(context);
    final oldest = events.first;
    final newest = events.last;
    final daysOfGrowth = newest.date.difference(oldest.date).inDays;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.surfaceContainerHigh,
            theme.colorScheme.surfaceContainer,
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.7),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Then vs Now',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$daysOfGrowth days of growth',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildBeforeAfterImage(
                    context,
                    oldest.photoUrl!,
                    'Then (${DateFormat.MMMd().format(oldest.date)})',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildBeforeAfterImage(
                    context,
                    newest.photoUrl!,
                    'Now (${DateFormat.MMMd().format(newest.date)})',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBeforeAfterImage(BuildContext context, String path, String label) {
    final theme = Theme.of(context);
    final file = File(path);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AspectRatio(
          aspectRatio: 1,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: GestureDetector(
              onTap: () => _openFullScreenImage(context, path, label),
              child: file.existsSync()
                  ? Image.file(
                      file,
                      fit: BoxFit.cover,
                      cacheWidth: 400,
                    )
                  : Container(
                      color: theme.colorScheme.surfaceContainerHighest,
                      child: const Icon(LucideIcons.imageOff),
                    ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          textAlign: TextAlign.center,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineStrip(BuildContext context, List<CareEvent> events) {
    final theme = Theme.of(context);

    return SizedBox(
      height: 125,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: events.length,
        itemBuilder: (context, index) {
          final event = events[index];
          final file = File(event.photoUrl!);
          final dateStr = DateFormat.MMMd().format(event.date);

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6.0),
            child: Column(
              children: [
                GestureDetector(
                  onTap: () => _openFullScreenImage(
                    context,
                    event.photoUrl!,
                    'Progress Photo - $dateStr',
                  ),
                  child: Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: theme.colorScheme.outlineVariant,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: file.existsSync()
                        ? Image.file(
                            file,
                            fit: BoxFit.cover,
                            cacheWidth: 400,
                          )
                        : const Icon(LucideIcons.imageOff),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  dateStr,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _openFullScreenImage(BuildContext context, String path, String title) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: true,
        pageBuilder: (context, _, __) {
          return _FullScreenImageViewer(path: path, title: title);
        },
      ),
    );
  }
}

class _FullScreenImageViewer extends StatefulWidget {
  final String path;
  final String title;

  const _FullScreenImageViewer({required this.path, required this.title});

  @override
  State<_FullScreenImageViewer> createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<_FullScreenImageViewer> {
  double _dragOffset = 0.0;

  @override
  Widget build(BuildContext context) {
    final file = File(widget.path);

    return Scaffold(
      backgroundColor: Colors.black.withValues(alpha: 1.0 - (_dragOffset.abs() / 300).clamp(0.0, 0.7)),
      body: GestureDetector(
        onVerticalDragUpdate: (details) {
          setState(() {
            _dragOffset += details.primaryDelta ?? 0.0;
          });
        },
        onVerticalDragEnd: (details) {
          if (_dragOffset.abs() > 100 || (details.primaryVelocity ?? 0.0).abs() > 300) {
            Navigator.of(context).pop();
          } else {
            setState(() {
              _dragOffset = 0.0;
            });
          }
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Centered Image
            Center(
              child: Transform.translate(
                offset: Offset(0.0, _dragOffset),
                child: Hero(
                  tag: widget.path,
                  child: file.existsSync()
                      ? Image.file(
                          file,
                          fit: BoxFit.contain,
                        )
                      : const Icon(
                          LucideIcons.imageOff,
                          color: Colors.white60,
                          size: 64,
                        ),
                ),
              ),
            ),

            // Top overlay bar
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.black54, Colors.transparent],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 48),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(LucideIcons.chevronLeft, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
