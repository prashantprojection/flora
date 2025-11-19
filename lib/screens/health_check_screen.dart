import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:camera/camera.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flora/widgets/bottom_nav_bar.dart';
import 'package:flora/api/gemini_service.dart';

class HealthCheckScreen extends ConsumerStatefulWidget {
  const HealthCheckScreen({super.key});

  @override
  ConsumerState<HealthCheckScreen> createState() => _HealthCheckScreenState();
}

class _HealthCheckScreenState extends ConsumerState<HealthCheckScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  File? _selectedImage;
  String? _description;
  bool _isLoading = false;
  String? _diagnosisResult;
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    _cameras = await availableCameras();
    if (_cameras != null && _cameras!.isNotEmpty) {
      _cameraController = CameraController(
        _cameras![0],
        ResolutionPreset.medium,
        enableAudio: false,
      );
      _cameraController!
          .initialize()
          .then((_) {
            if (!mounted) {
              return;
            }
            setState(() {});
          })
          .catchError((Object e) {
            if (e is CameraException) {
              // Handle camera errors here, e.g., show a snackbar.
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error initializing camera: ${e.description}'),
                ),
              );
            }
          });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
        _diagnosisResult = null;
      });
    }
  }

  Future<void> _takePhoto() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Camera not available or initialized.')),
      );
      return;
    }
    try {
      final XFile file = await _cameraController!.takePicture();
      setState(() {
        _selectedImage = File(file.path);
        _diagnosisResult = null;
      });
    } catch (e) {
      // TODO: Handle take photo error
    }
  }

  Future<void> _diagnosePlant() async {
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select or capture an image.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _diagnosisResult = null;
    });

    try {
      final geminiService = ref.read(geminiServiceProvider);
      final imageData = await _selectedImage!.readAsBytes();
      _diagnosisResult = await geminiService.analyzePlantImage(
        imageData,
        additionalDetails: _description,
      );
    } catch (e) {
      _diagnosisResult = "Failed to diagnose plant: $e";
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
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
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Health Check',
          style: TextStyle(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ), // Removed unnecessary semi-bold
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(LucideIcons.upload), text: 'Upload'),
            Tab(icon: Icon(LucideIcons.camera), text: 'Camera'),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Plant Health Check',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium, // Changed to titleMedium for consistency
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Get an AI-powered health diagnosis for your plant. Use your camera or upload a photo.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 300,
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          // Upload Tab Content
                          _selectedImage != null
                              ? Image.file(_selectedImage!, fit: BoxFit.contain)
                              : GestureDetector(
                                  onTap: () => _pickImage(ImageSource.gallery),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.outline,
                                      ), // Using outline color
                                      borderRadius: BorderRadius.circular(
                                        8,
                                      ), // lg
                                    ),
                                    child: Center(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const Icon(
                                            LucideIcons.upload,
                                            size: 40,
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'Click to upload a photo',
                                            style: Theme.of(
                                              context,
                                            ).textTheme.bodyMedium,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                          // Camera Tab Content
                          _selectedImage != null
                              ? Image.file(_selectedImage!, fit: BoxFit.contain)
                              : (_cameraController != null &&
                                        _cameraController!.value.isInitialized
                                    ? Column(
                                        children: [
                                          Expanded(
                                            child: CameraPreview(
                                              _cameraController!,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          ElevatedButton(
                                            onPressed: _takePhoto,
                                            child: const Text('Capture Photo'),
                                          ),
                                        ],
                                      )
                                    : Center(
                                        child: CircularProgressIndicator(
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                Theme.of(
                                                  context,
                                                ).colorScheme.primary,
                                              ),
                                        ),
                                      )),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      initialValue: _description,
                      onChanged: (value) => _description = value,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        hintText:
                            'Optional: Add any details, e.g. \'leaves are yellow and have brown spots\'.',
                        // Removed unnecessary border and focusedBorder, relying on theme defaults
                      ),
                    ),
                    const SizedBox(height: 16),
                    _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : ElevatedButton(
                            onPressed: _selectedImage != null
                                ? _diagnosePlant
                                : null,
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(LucideIcons.heartPulse),
                                SizedBox(width: 8),
                                Text('Diagnose Plant'),
                              ],
                            ),
                          ),
                    if (_selectedImage != null || _diagnosisResult != null)
                      TextButton(
                        onPressed: _resetState,
                        child: const Text('Start Over'),
                      ),
                  ],
                ),
              ),
            ),
            if (_diagnosisResult != null)
              Card(
                margin: const EdgeInsets.only(top: 16.0),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Diagnosis Result',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      MarkdownBody(
                        data: _diagnosisResult!,
                        styleSheet: MarkdownStyleSheet.fromTheme(
                          Theme.of(context),
                        ).copyWith(p: Theme.of(context).textTheme.bodyMedium),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: const BottomNavBar(),
    );
  }
}
