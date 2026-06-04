import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:flora/providers/plant_provider.dart';
import 'package:flora/services/backup_service.dart';
import 'package:flora/models/plant.dart';
import 'package:flora/widgets/animated_press.dart';

class SupportBackupCard extends ConsumerStatefulWidget {
  const SupportBackupCard({super.key});

  @override
  ConsumerState<SupportBackupCard> createState() => _SupportBackupCardState();
}

class _SupportBackupCardState extends ConsumerState<SupportBackupCard> {
  bool _isImporting = false;

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

  Future<void> _pickAndImportFile() async {
    setState(() => _isImporting = true);

    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.isEmpty) {
        setState(() => _isImporting = false);
        return;
      }

      final path = result.files.single.path;
      if (path == null) {
        _showSnackBar('Could not read selected file.', isError: true);
        setState(() => _isImporting = false);
        return;
      }

      final rawText = await File(path).readAsString();
      await _processImport(rawText);
    } catch (e) {
      _showSnackBar('Failed to open file: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isImporting = false);
    }
  }

  Future<void> _processImport(String rawText) async {
    if (rawText.trim().isEmpty) {
      _showSnackBar('The selected file is empty.', isError: true);
      return;
    }

    try {
      final importedPlants = BackupService.parseBackup(rawText);
      if (importedPlants.isEmpty) {
        _showSnackBar('No plants found in the backup file.', isError: true);
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
        'Failed to parse backup: Invalid or corrupted file.',
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
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: ExpansionTile(
        shape: const Border(),
        collapsedShape: const Border(),
        backgroundColor:
            theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.1),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            LucideIcons.databaseBackup,
            color: theme.colorScheme.primary,
            size: 18,
          ),
        ),
        title: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            'Backup & Share',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        subtitle: Text(
          'Export or import your garden data',
          style: theme.textTheme.bodySmall,
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
                child: AnimatedPress(
                  onTap: () {
                    final plants = ref.read(plantListProvider);
                    if (plants.isEmpty) {
                      _showSnackBar('No plants to export yet!', isError: true);
                      return;
                    }
                    BackupService.exportBackup(plants);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      border: Border.all(color: theme.colorScheme.outlineVariant),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(LucideIcons.share2, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Export',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AnimatedPress(
                  onTap: _isImporting ? null : _pickAndImportFile,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_isImporting)
                          const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        else
                          Icon(LucideIcons.folderOpen,
                              size: 18, color: theme.colorScheme.onPrimary),
                        const SizedBox(width: 8),
                        Text(
                          _isImporting ? 'Importing...' : 'Import',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onPrimary,
                          ),
                        ),
                      ],
                    ),
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
