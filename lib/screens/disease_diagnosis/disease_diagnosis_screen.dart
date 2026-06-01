import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flora/services/image_picker_service.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:flutter_tts/flutter_tts.dart';

import 'package:flora/api/gemini_service.dart';
import 'package:flora/utils/network_utils.dart';
import 'package:flora/services/plant_classifier_service.dart';
import 'package:flora/providers/diagnosis_provider.dart';
import 'package:flora/models/diagnosis_record.dart';
import 'package:uuid/uuid.dart';

import 'package:flora/screens/disease_diagnosis/components/diagnosis_selection_view.dart';
import 'package:flora/screens/disease_diagnosis/components/diagnosis_preview_view.dart';
import 'package:flora/screens/disease_diagnosis/components/diagnosis_result_view.dart';
import 'package:flora/screens/disease_diagnosis/components/diagnosis_history_sheet.dart';

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
  String? _currentRecordId;
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

  Future<void> _pickImage(bool fromCamera) async {
    // Always stop any in-progress speech before starting a new session
    await _flutterTts.stop();
    setState(() => _isSpeaking = false);
    try {
      final File? pickedFile = await ImagePickerService.pickImage(
        fromCamera: fromCamera,
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
          content: const Row(
            children: [
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

      final result = await geminiService.analyzePlantImage(
        imageData,
        additionalDetails: _description,
      );

      final record = DiagnosisRecord(
        id: const Uuid().v4(),
        imagePath: _selectedImage!.path,
        diagnosis: result,
        date: DateTime.now(),
      );
      ref.read(diagnosisHistoryProvider.notifier).addDiagnosis(record);

      setState(() {
        _diagnosisResult = result;
        _currentRecordId = record.id;
      });
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
      final record = DiagnosisRecord(
        id: const Uuid().v4(),
        imagePath: _selectedImage!.path,
        diagnosis: result,
        date: DateTime.now(),
      );
      ref.read(diagnosisHistoryProvider.notifier).addDiagnosis(record);

      setState(() {
        _diagnosisResult = result;
        _currentRecordId = record.id;
      });
    } catch (e) {
      _showErrorDialog("Failed to diagnose plant: $e");
    } finally {
      setState(() {
        _isLoading = false;
        _loadingMessage = null;
      });
    }
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
    // Stop TTS immediately — the result view is being dismissed
    _flutterTts.stop();
    setState(() {
      _selectedImage = null;
      _description = null;
      _isLoading = false;
      _diagnosisResult = null;
      _currentRecordId = null;
      _isSpeaking = false;
    });
  }

  void _viewRecord(DiagnosisRecord record) {
    setState(() {
      _selectedImage = File(record.imagePath).existsSync()
          ? File(record.imagePath)
          : null;
      _diagnosisResult = record.diagnosis;
      _currentRecordId = record.id;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_diagnosisResult != null) {
      return DiagnosisResultView(
        selectedImage: _selectedImage,
        diagnosisResult: _diagnosisResult!,
        isSpeaking: _isSpeaking,
        onSpeak: _speakDiagnosis,
        onReset: _resetState,
        initialFeedback: ref.watch(diagnosisHistoryProvider).firstWhere(
            (r) => r.id == _currentRecordId, orElse: () => DiagnosisRecord(id: '', imagePath: '', diagnosis: '', date: DateTime.now())).isHelpful,
        onFeedback: (isHelpful) {
          if (_currentRecordId != null) {
            ref.read(diagnosisHistoryProvider.notifier).updateDiagnosisFeedback(_currentRecordId!, isHelpful);
          }
        },
      );
    } else if (_selectedImage != null) {
      return DiagnosisPreviewView(
        selectedImage: _selectedImage!,
        initialDescription: _description,
        onDescriptionChanged: (value) => _description = value,
        onStartDiagnosis: _runDiagnosis,
        onReset: _resetState,
        isLoading: _isLoading,
        loadingMessage: _loadingMessage,
      );
    } else {
      return Stack(
        children: [
          DiagnosisSelectionView(
            onPickImage: _pickImage,
          ),
          DiagnosisHistorySheet(
            onViewRecord: _viewRecord,
          ),
        ],
      );
    }
  }
}
