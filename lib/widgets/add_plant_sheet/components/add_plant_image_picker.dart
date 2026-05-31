import 'dart:io';
import 'package:flutter/material.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

class AddPlantImagePicker extends StatelessWidget {
  final File? selectedImageFile;
  final String? initialImageUrl;
  final VoidCallback onPickImage;
  final VoidCallback onTakePhoto;

  const AddPlantImagePicker({
    super.key,
    required this.selectedImageFile,
    required this.initialImageUrl,
    required this.onPickImage,
    required this.onTakePhoto,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasImage = selectedImageFile != null || initialImageUrl != null;

    return Column(
      children: [
        GestureDetector(
          onTap: onPickImage,
          child: Container(
            width: double.infinity,
            height: 200,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(24),
              border: hasImage
                  ? null
                  : Border.all(
                      color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                      width: 2,
                    ),
              image: hasImage
                  ? DecorationImage(
                      image: selectedImageFile != null
                          ? FileImage(selectedImageFile!)
                          : (initialImageUrl!.startsWith('http')
                              ? NetworkImage(initialImageUrl!)
                              : FileImage(File(initialImageUrl!))) as ImageProvider,
                      fit: BoxFit.cover,
                    )
                  : null,
              boxShadow: hasImage
                  ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ]
                  : [],
            ),
            child: hasImage
                ? Stack(
                    children: [
                      Positioned(
                        top: 16,
                        right: 16,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.6),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(LucideIcons.pencil, color: Colors.white, size: 18),
                        ),
                      ),
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          LucideIcons.imagePlus,
                          size: 32,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Tap to choose from gallery',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: onTakePhoto,
                icon: const Icon(LucideIcons.camera, size: 18),
                label: const Text('Take Photo (Smart Scan)'),
                style: FilledButton.styleFrom(
                  backgroundColor: theme.colorScheme.secondaryContainer,
                  foregroundColor: theme.colorScheme.onSecondaryContainer,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
