import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flora/models/plant.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

class BulkWaterDialog extends StatefulWidget {
  final List<Plant> plants;
  final Function(List<String> selectedIds) onConfirm;

  const BulkWaterDialog({
    super.key,
    required this.plants,
    required this.onConfirm,
  });

  @override
  State<BulkWaterDialog> createState() => _BulkWaterDialogState();
}

class _BulkWaterDialogState extends State<BulkWaterDialog> {
  late Set<String> _selectedIds;

  @override
  void initState() {
    super.initState();
    // Default all to selected
    _selectedIds = widget.plants.map((p) => p.id).toSet();
  }

  void _togglePlant(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  ImageProvider? _getImageProvider(String? url) {
    if (url == null || url.isEmpty) return null;
    if (url.startsWith('http')) {
      return NetworkImage(url);
    }
    return FileImage(File(url));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Row(
        children: [
          Icon(LucideIcons.droplets, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          const Text('Water Plants'),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select plants to mark as watered:',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: widget.plants.length,
                itemBuilder: (context, index) {
                  final plant = widget.plants[index];
                  final isSelected = _selectedIds.contains(plant.id);

                  return CheckboxListTile(
                    value: isSelected,
                    onChanged: (value) => _togglePlant(plant.id),
                    title: Text(plant.name),
                    subtitle: plant.species != null && plant.species!.isNotEmpty
                        ? Text(plant.species!)
                        : null,
                    secondary: CircleAvatar(
                      backgroundImage: _getImageProvider(plant.imageUrl),
                      child: _getImageProvider(plant.imageUrl) == null
                          ? const Icon(LucideIcons.flower2)
                          : null,
                    ),
                    activeColor: theme.colorScheme.primary,
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _selectedIds.isEmpty
              ? null
              : () {
                  widget.onConfirm(_selectedIds.toList());
                  Navigator.of(context).pop();
                },
          child: Text('Water ${_selectedIds.length} Plants'),
        ),
      ],
    );
  }
}
