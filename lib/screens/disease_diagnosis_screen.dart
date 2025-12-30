import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_tts/flutter_tts.dart';

import 'package:flora/api/gemini_service.dart';
import 'package:flora/utils/network_utils.dart';
import 'package:flora/services/plant_classifier_service.dart';
import 'package:flora/providers/diagnosis_provider.dart';
import 'package:flora/models/diagnosis_record.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';

class DiseaseDiagnosisScreen extends ConsumerStatefulWidget {
  const DiseaseDiagnosisScreen({super.key});

  @override
  ConsumerState<DiseaseDiagnosisScreen> createState() =>
      _DiseaseDiagnosisScreenState();
}

class _DiseaseDiagnosisScreenState
    extends ConsumerState<DiseaseDiagnosisScreen> {
  File? _selectedImage;
  String? _description;
  bool _isLoading = false;
  String? _loadingMessage;
  String? _diagnosisResult;
  final ImagePicker _picker = ImagePicker();
  final PlantClassifierService _classifierService = PlantClassifierService();
  final FlutterTts _flutterTts = FlutterTts();
  bool _isSpeaking = false;

  @override
  void initState() {
    super.initState();
    _initTts();
  }

  Future<void> _initTts() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setPitch(1.0);
    await _flutterTts.setSpeechRate(0.5);
    _flutterTts.setCompletionHandler(() {
      setState(() {
        _isSpeaking = false;
      });
    });
  }

  Future<void> _speakDiagnosis() async {
    if (_diagnosisResult == null) return;
    if (_isSpeaking) {
      await _flutterTts.stop();
      setState(() {
        _isSpeaking = false;
      });
    } else {
      setState(() {
        _isSpeaking = true;
      });
      // Strip markdown symbols for smoother speech
      final cleanText = _diagnosisResult!
          .replaceAll('**', '')
          .replaceAll('#', '')
          .replaceAll('*', '');
      await _flutterTts.speak(cleanText);
    }
  }

  @override
  void dispose() {
    _flutterTts.stop();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 80, // Optimize image size
      );
      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
          _diagnosisResult = null;
          _description = null;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error picking image: $e')));
    }
  }

  Future<void> _runDiagnosis() async {
    if (_selectedImage == null) return;

    // 1. GATEKEEPER: Check Internet Connection
    setState(() {
      _isLoading = true;
      _loadingMessage = "Checking connection...";
    });

    final hasInternet = await NetworkUtils.hasInternetConnection();
    if (!hasInternet) {
      setState(() {
        _isLoading = false;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(LucideIcons.wifiOff, color: Colors.white),
              SizedBox(width: 8),
              Expanded(
                child: Text("No internet. Diagnosis requires online access."),
              ),
            ],
          ),
          backgroundColor: Colors.redAccent,
          action: SnackBarAction(
            label: 'Retry',
            textColor: Colors.white,
            onPressed: _runDiagnosis,
          ),
        ),
      );
      return;
    }

    // 2. BOUNCER: Check if it's a plant (On-Device)
    setState(() {
      _loadingMessage = "Verifying image content...";
    });

    final isPlant = await _classifierService.isPlant(_selectedImage!.path);
    if (!isPlant) {
      setState(() {
        _isLoading = false;
      });
      _showNonPlantDialog();
      return;
    }

    // 3. DIAGNOSIS: Call Gemini API
    setState(() {
      _loadingMessage = "Consulting AI Botanist...";
    });

    try {
      final geminiService = ref.read(geminiServiceProvider);
      final imageData = await _selectedImage!.readAsBytes();

      // We append a specific instruction for strict JSON if we wanted,
      // but the service currently returns Markdown which is fine for now
      // as per our "soft" integration plan.
      final result = await geminiService.analyzePlantImage(
        imageData,
        additionalDetails: _description,
      );

      setState(() {
        _diagnosisResult = result;
      });

      // Save to history automatically
      final record = DiagnosisRecord(
        id: const Uuid().v4(),
        imagePath: _selectedImage!.path,
        diagnosis: result,
        date: DateTime.now(),
      );
      ref.read(diagnosisHistoryProvider.notifier).addDiagnosis(record);
    } catch (e) {
      _showErrorDialog("Failed to diagnose plant: $e");
    } finally {
      setState(() {
        _isLoading = false;
        _loadingMessage = null;
      });
    }
  }

  void _showNonPlantDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Is this a plant?"),
        content: const Text(
          "We couldn't detect a plant in this image. Please ensure the subject is clear and centered.\n\n"
          "If you are sure this is a plant, you can try again or proceed anyway.",
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _selectedImage = null; // Reset
              });
            },
            child: const Text("Retake"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              // Bypass check manually
              await _forceDiagnosis();
            },
            child: const Text("Proceed Anyway"),
          ),
        ],
      ),
    );
  }

  // Exact copy of diagnosis logic without the checks (used for "Proceed Anyway")
  Future<void> _forceDiagnosis() async {
    setState(() {
      _isLoading = true;
      _loadingMessage = "Consulting AI Botanist...";
    });
    try {
      final geminiService = ref.read(geminiServiceProvider);
      final imageData = await _selectedImage!.readAsBytes();
      final result = await geminiService.analyzePlantImage(
        imageData,
        additionalDetails: _description,
      );
      setState(() {
        _diagnosisResult = result;
      });

      // Save to history automatically
      final record = DiagnosisRecord(
        id: const Uuid().v4(),
        imagePath: _selectedImage!.path,
        diagnosis: result,
        date: DateTime.now(),
      );
      ref.read(diagnosisHistoryProvider.notifier).addDiagnosis(record);
    } catch (e) {
      _showErrorDialog("Failed to diagnose plant: $e");
    } finally {
      setState(() {
        _isLoading = false;
        _loadingMessage = null;
      });
    }
  }

  void _confirmDelete(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Verification"),
        content: const Text(
          "Are you sure you want to delete this diagnosis? This action cannot be undone.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref
                  .read(diagnosisHistoryProvider.notifier)
                  .deleteDiagnosis(index);
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Error"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  void _resetState() {
    setState(() {
      _selectedImage = null;
      _description = null;
      _isLoading = false;
      _diagnosisResult = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_diagnosisResult != null) {
      return _buildResultView();
    } else if (_selectedImage != null) {
      return _buildPreviewView();
    } else {
      return _buildSelectionView();
    }
  }

  // --- VIEW: 1. Selection (Camera/Gallery) ---
  Widget _buildSelectionView() {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Disease Diagnosis',
          style: TextStyle(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Stack(
        children: [
          Padding(
            padding: EdgeInsets.only(
              bottom: ref.watch(diagnosisHistoryProvider).isNotEmpty
                  ? MediaQuery.of(context).size.height * 0.18
                  : 0,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(),
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.primaryContainer.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    LucideIcons.scanLine,
                    size: 60, // Slightly smaller to fit
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'AI Plant Doctor',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Identify diseases, pests, and health issues instantly with advanced AI.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                Row(
                  children: [
                    Expanded(
                      child: _buildActionCard(
                        icon: LucideIcons.camera,
                        label: 'Take Photo',
                        onTap: () => _pickImage(ImageSource.camera),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildActionCard(
                        icon: LucideIcons.image,
                        label: 'Gallery',
                        onTap: () => _pickImage(ImageSource.gallery),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
          if (ref.watch(diagnosisHistoryProvider).isNotEmpty)
            _buildHistorySection(),
        ],
      ),
    );
  }

  // --- VIEW: 2. Preview & Analyze ---
  Widget _buildPreviewView() {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: _resetState,
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
                    _selectedImage!,
                    height: 300,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  initialValue: _description,
                  onChanged: (value) => _description = value,
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
                    onPressed: _isLoading ? null : _runDiagnosis,
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
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(color: Colors.white),
                    const SizedBox(height: 16),
                    Text(
                      _loadingMessage ?? "Processing...",
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

  // --- VIEW: 3. Results ---
  Widget _buildResultView() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Diagnosis Result'),
        leading: IconButton(
          icon: const Icon(LucideIcons.x),
          onPressed: _resetState,
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.share2),
            onPressed: () {
              if (_selectedImage != null && _diagnosisResult != null) {
                Share.shareXFiles([
                  XFile(_selectedImage!.path),
                ], text: 'Flora Diagnosis Report:\n\n$_diagnosisResult');
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
                    backgroundImage: FileImage(_selectedImage!),
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
                    onPressed: _speakDiagnosis,
                    icon: Icon(
                      _isSpeaking ? Icons.stop_circle : LucideIcons.volume2,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    tooltip: _isSpeaking
                        ? 'Stop Speaking'
                        : 'Listen to Diagnosis',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Markdown Content
            MarkdownBody(
              data: _diagnosisResult ?? '',
              selectable: true,
              styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context))
                  .copyWith(
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
              onPressed: _resetState,
              icon: const Icon(LucideIcons.scan),
              label: const Text('Scan Another Plant'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        height: 100,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 30, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistorySection() {
    final history = ref.watch(diagnosisHistoryProvider);
    if (history.isEmpty) return const SizedBox.shrink();

    return DraggableScrollableSheet(
      initialChildSize: 0.15,
      minChildSize: 0.15,
      maxChildSize: 0.6,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: SafeArea(
            bottom: false,
            child: ListView.separated(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
              itemCount: history.length + 1,
              separatorBuilder: (_, index) {
                if (index == 0) return const Divider();
                return const SizedBox(height: 12);
              },
              itemBuilder: (context, index) {
                // Header at index 0
                if (index == 0) {
                  return Column(
                    children: [
                      Container(
                        margin: const EdgeInsets.symmetric(vertical: 12),
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.outlineVariant,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8, // Reduced since parent has 16
                          vertical: 8,
                        ),
                        child: Row(
                          children: [
                            Text(
                              'Past Diagnoses',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const Spacer(),
                            Text(
                              '${history.length} Saved',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }

                // History Items
                final record = history[index - 1]; // Adjust index
                return ListTile(
                  contentPadding: const EdgeInsets.all(8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                  ),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      File(record.imagePath),
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 60,
                        height: 60,
                        color: Colors.grey[300],
                        child: const Icon(Icons.broken_image),
                      ),
                    ),
                  ),
                  title: Text(
                    DateFormat.yMMMd().format(record.date),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    record.diagnosis.split('\n').first,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () {
                    // View past diagnosis
                    setState(() {
                      _selectedImage = File(record.imagePath);
                      _diagnosisResult = record.diagnosis;
                    });
                  },
                  trailing: IconButton(
                    icon: const Icon(LucideIcons.trash2, size: 18),
                    onPressed: () {
                      _confirmDelete(index - 1);
                    },
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
