import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:flora/providers/plant_provider.dart';
import 'package:flora/services/backup_service.dart';
import 'package:flora/models/plant.dart';

class SupportBackupCard extends ConsumerStatefulWidget {
  const SupportBackupCard({super.key});

  @override
  ConsumerState<SupportBackupCard> createState() => _SupportBackupCardState();
}

class _SupportBackupCardState extends ConsumerState<SupportBackupCard> {
  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            isError ? Colors.red : Theme.of(context).colorScheme.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showImportDialog() {
    final theme = Theme.of(context);
    final textController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
            ),
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Text(
                      'Import Garden Data 🌿',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(LucideIcons.x),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Paste your Flora garden backup JSON text below to import or restore your plants.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: textController,
                  maxLines: 8,
                  decoration: InputDecoration(
                    hintText: '[{"id": "...", "name": "...", ...}]',
                    hintStyle: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                    filled: true,
                    fillColor: theme.colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.3),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () => _processImport(textController.text),
                  icon: const Icon(LucideIcons.arrowDownToLine),
                  label: const Text(
                    'Parse & Import',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _processImport(String rawText) async {
    Navigator.pop(context);
    if (rawText.trim().isEmpty) return;

    try {
      final importedPlants = BackupService.parseBackup(rawText);
      if (importedPlants.isEmpty) {
        _showSnackBar('No plants found in the backup data.', isError: true);
        return;
      }

      final existingPlants = ref.read(plantListProvider);
      final duplicateIds =
          importedPlants
              .map((ip) => ip.id)
              .where((id) => existingPlants.any((ep) => ep.id == id))
              .toList();

      if (duplicateIds.isNotEmpty) {
        _showDuplicateStrategyDialog(importedPlants, duplicateIds.length);
      } else {
        ref
            .read(plantListProvider.notifier)
            .importPlants(importedPlants, duplicateStrategy: 'skip');
        _showSnackBar('Successfully imported ${importedPlants.length} plants!');
      }
    } catch (e) {
      _showSnackBar(
        'Failed to parse backup data: Invalid format.',
        isError: true,
      );
    }
  }

  void _showDuplicateStrategyDialog(List<Plant> plants, int duplicateCount) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Text(
            'Duplicate Plants Detected ⚠️',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'We found $duplicateCount plants in this backup that already exist in your garden.',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              Text(
                'Choose how you want to handle these duplicates:',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            OutlinedButton(
              onPressed: () {
                Navigator.pop(context);
                ref
                    .read(plantListProvider.notifier)
                    .importPlants(plants, duplicateStrategy: 'keep_both');
                _showSnackBar(
                  'Imported ${plants.length} plants (kept both copies)!',
                );
              },
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Keep Both (Creates copies)'),
            ),
            OutlinedButton(
              onPressed: () {
                Navigator.pop(context);
                ref
                    .read(plantListProvider.notifier)
                    .importPlants(plants, duplicateStrategy: 'replace');
                _showSnackBar(
                  'Imported ${plants.length} plants (replaced existing data)!',
                );
              },
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Replace (Overwrite existing)'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                ref
                    .read(plantListProvider.notifier)
                    .importPlants(plants, duplicateStrategy: 'skip');
                _showSnackBar(
                  'Imported new plants (skipped existing duplicates)!',
                );
              },
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Skip Duplicates (Keep current data)'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: ExpansionTile(
        shape: const Border(),
        collapsedShape: const Border(),
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.1),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            LucideIcons.databaseBackup,
            color: Theme.of(context).colorScheme.primary,
            size: 20,
          ),
        ),
        title: Text(
          'Backup & Household Share',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          'Export or import your garden data',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        childrenPadding: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
        children: [
          const Text(
            'Keep your plant records safe, restore them on a new device, or share your entire garden with household members.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    final plants = ref.read(plantListProvider);
                    if (plants.isEmpty) {
                      _showSnackBar('No plants to export yet!', isError: true);
                      return;
                    }
                    BackupService.exportBackup(plants);
                  },
                  icon: const Icon(LucideIcons.share2, size: 18),
                  label: const Text(
                    'Export',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  onPressed: _showImportDialog,
                  icon: const Icon(LucideIcons.download, size: 18),
                  label: const Text(
                    'Import',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
