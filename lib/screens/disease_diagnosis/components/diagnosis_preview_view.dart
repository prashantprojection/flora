import 'dart:io';
import 'package:flutter/material.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

class DiagnosisPreviewView extends StatelessWidget {
  final File selectedImage;
  final String? initialDescription;
  final ValueChanged<String> onDescriptionChanged;
  final VoidCallback onStartDiagnosis;
  final VoidCallback onReset;
  final bool isLoading;
  final String? loadingMessage;

  const DiagnosisPreviewView({
    super.key,
    required this.selectedImage,
    this.initialDescription,
    required this.onDescriptionChanged,
    required this.onStartDiagnosis,
    required this.onReset,
    required this.isLoading,
    this.loadingMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: onReset,
        ),
        title: const Text('Analyze Plant'),
        elevation: 0,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.file(
                    selectedImage,
                    height: 300,
                    fit: BoxFit.cover,
                    cacheWidth: 1000,
                  ),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  initialValue: initialDescription,
                  onChanged: onDescriptionChanged,
                  decoration: InputDecoration(
                    labelText: 'Observations (Optional)',
                    hintText: 'E.g. White spots, wilting leaves...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(LucideIcons.text),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 32),
                SizedBox(
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: isLoading ? null : onStartDiagnosis,
                    icon: const Icon(LucideIcons.sparkles),
                    label: const Text(
                      'START DIAGNOSIS',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (isLoading)
            Container(
               color: Colors.black54,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(color: Colors.white),
                    const SizedBox(height: 16),
                    Text(
                      loadingMessage ?? "Processing...",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
