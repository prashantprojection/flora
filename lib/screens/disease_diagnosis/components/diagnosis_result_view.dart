import 'dart:io';
import 'package:flutter/material.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flora/services/platform_share_service.dart';

class DiagnosisResultView extends StatelessWidget {
  final File? selectedImage;
  final String diagnosisResult;
  final bool isSpeaking;
  final VoidCallback onSpeak;
  final VoidCallback onReset;

  const DiagnosisResultView({
    super.key,
    required this.selectedImage,
    required this.diagnosisResult,
    required this.isSpeaking,
    required this.onSpeak,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Diagnosis Result'),
        leading: IconButton(
          icon: const Icon(LucideIcons.x),
          onPressed: onReset,
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.share2),
            onPressed: () {
              if (selectedImage != null) {
                PlatformShareService.shareFiles(
                  [selectedImage!.path],
                  text: 'Flora Diagnosis Report:\n\n$diagnosisResult',
                );
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor:
                        Theme.of(context).colorScheme.primaryContainer,
                    backgroundImage:
                        selectedImage != null && selectedImage!.existsSync()
                            ? FileImage(selectedImage!)
                            : null,
                    child: selectedImage == null || !selectedImage!.existsSync()
                        ? Icon(
                            LucideIcons.imageOff,
                            color: Theme.of(context).colorScheme.primary,
                          )
                        : null,
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Text(
                      "Analysis Complete",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  IconButton(
                    onPressed: onSpeak,
                    icon: Icon(
                      isSpeaking ? Icons.stop_circle : LucideIcons.volume2,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    tooltip:
                        isSpeaking ? 'Stop Speaking' : 'Listen to Diagnosis',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Markdown Content
            MarkdownBody(
              data: diagnosisResult,
              selectable: true,
              styleSheet:
                  MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
                    p: Theme.of(
                      context,
                    ).textTheme.bodyLarge?.copyWith(height: 1.6),
                    h1: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                    h2: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Theme.of(context).colorScheme.secondary,
                      fontWeight: FontWeight.bold,
                      height: 2.0,
                    ),
                    blockquote: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                    ),
                    blockquoteDecoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                      border: Border(
                        left: BorderSide(
                          color: Theme.of(context).colorScheme.primary,
                          width: 4,
                        ),
                      ),
                    ),
                  ),
            ),
            const SizedBox(height: 40),

            // Footer Actions
            FilledButton.tonalIcon(
              onPressed: onReset,
              icon: const Icon(LucideIcons.scan),
              label: const Text('Scan Another Plant'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
