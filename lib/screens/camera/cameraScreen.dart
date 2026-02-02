import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async'; // ← add this line
import '../../providers/text_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/home_provider.dart';
import '../../services/camera_service.dart';

enum CameraInitStatus { initializing, ready, timeout, error, permissionDenied }

class CameraScreen extends ConsumerStatefulWidget {
  const CameraScreen({super.key});

  @override
  ConsumerState<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends ConsumerState<CameraScreen>
    with WidgetsBindingObserver {
  late CameraService _cameraService;
  bool _isDialogShowing = false;

  CameraInitStatus _initStatus = CameraInitStatus.initializing;
  String? _errorMessage;

  // Store cure data here
  Map<String, dynamic> _cureData = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _cameraService = CameraService(ref);

    // Reload cure data if user changes language
    ref.listen<Locale>(localeProvider, (prev, next) {
      _loadCureData();
    });

    _initializeAsync();
  }

  Future<void> _loadCureData() async {
    final locale = ref.read(localeProvider);
    final cureFile = locale.languageCode == 'ne'
        ? 'assets/labels/cure_ne.json'
        : 'assets/labels/cure_en.json';

    try {
      final jsonString = await rootBundle.loadString(cureFile);
      if (mounted) {
        setState(() {
          _cureData = json.decode(jsonString);
        });
      }
    } catch (e) {
      debugPrint("Error loading cure data for ${locale.languageCode}: $e");
    }
  }

  Future<void> _initializeAsync() async {
    if (!mounted) return;

    setState(() {
      _initStatus = CameraInitStatus.initializing;
      _errorMessage = null;
    });

    try {
      // 1. Load cure data first (non-blocking for camera)
      await _loadCureData();

      // 2. Explicit permission check BEFORE camera init
      var status = await Permission.camera.status;
      if (!status.isGranted) {
        status = await Permission.camera.request();
        if (!status.isGranted) {
          if (mounted) {
            setState(() {
              _initStatus = CameraInitStatus.permissionDenied;
            });
            _showPermissionDialog();
          }
          return;
        }
      }

      // 3. Initialize camera with timeout
      debugPrint("Starting camera initialization...");
      await _cameraService.initializeCamera().timeout(
        const Duration(seconds: 12),
        onTimeout: () {
          throw TimeoutException("Camera initialization timeout");
        },
      );

      if (mounted) {
        setState(() {
          _initStatus = CameraInitStatus.ready;
        });
      }
    } catch (e, stack) {
      debugPrint("Camera initialization failed: $e\n$stack");

      String userMessage = "Failed to open camera. Please try again.";
      CameraInitStatus newStatus = CameraInitStatus.error;

      if (e is TimeoutException) {
        userMessage =
            "Camera is taking too long to start.\nThis can happen on first use or on some devices.";
        newStatus = CameraInitStatus.timeout;
      } else if (e.toString().contains("permission")) {
        newStatus = CameraInitStatus.permissionDenied;
        _showPermissionDialog();
      }

      if (mounted) {
        setState(() {
          _initStatus = newStatus;
          _errorMessage = userMessage;
        });
      }
    }
  }

  void _showPermissionDialog() {
    if (_isDialogShowing) return;
    _isDialogShowing = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("Camera Permission Required"),
        content: const Text("Please allow camera access to scan plant leaves."),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _isDialogShowing = false;
            },
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _isDialogShowing = false;
              openAppSettings();
            },
            child: const Text("Open Settings"),
          ),
        ],
      ),
    ).then((_) => _isDialogShowing = false);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _cameraService.controller;

    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      // Pause preview when app goes to background
      if (controller.value.isInitialized) {
        controller.pausePreview();
      }
    } else if (state == AppLifecycleState.resumed) {
      // Resume or re-init when coming back
      if (_initStatus == CameraInitStatus.ready &&
          controller.value.isInitialized) {
        controller.resumePreview();
      } else if (_initStatus != CameraInitStatus.ready) {
        _initializeAsync();
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraService.dispose();
    super.dispose();
  }

  // ──────────────────────────────────────────────
  // Your existing helper methods (unchanged)
  // ──────────────────────────────────────────────

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String content,
  }) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.green.shade700, size: 24),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              content,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade800,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildCureDetails(String diseaseName) {
    final cureInfo = _cureData[diseaseName] as Map<String, dynamic>?;
    if (cureInfo == null) return [];

    final textData = ref.watch(textProvider);

    String getLabel(String key, String fallback) {
      return textData.maybeWhen(
        data: (data) => data[key] ?? fallback,
        orElse: () => fallback,
      );
    }

    final widgets = <Widget>[];

    final details = [
      {'key': 'Description', 'fallback': 'Description', 'icon': Icons.article},
      {'key': 'Cause', 'fallback': 'Cause', 'icon': Icons.coronavirus},
      {'key': 'Symptoms', 'fallback': 'Symptoms', 'icon': Icons.monitor_heart},
      {'key': 'Prevention', 'fallback': 'Prevention', 'icon': Icons.shield},
      {
        'key': 'Treatment',
        'fallback': 'Treatment',
        'icon': Icons.medical_services,
      },
    ];

    for (var detail in details) {
      final jsonKey = detail['key'] as String;
      final labelKey = jsonKey.toLowerCase();
      final fallback = detail['fallback'] as String;
      final iconData = detail['icon'] as IconData;

      if (cureInfo[jsonKey] != null) {
        widgets.add(
          _buildInfoCard(
            icon: iconData,
            title: getLabel(labelKey, fallback),
            content: cureInfo[jsonKey],
          ),
        );
      }
    }
    return widgets;
  }

  Future<void> _pickImage(ImageSource source) async {
    final isPicking = ref.read(isPickingImageProvider);
    if (isPicking) return;
    ref.read(isPickingImageProvider.notifier).state = true;

    try {
      await _cameraService.pickImage(source);
      await _cameraService.runPrediction();
    } catch (e) {
      debugPrint("Gallery Error: $e");
    } finally {
      if (mounted) ref.read(isPickingImageProvider.notifier).state = false;
    }
  }

  Future<void> _takePhoto() async {
    try {
      await _cameraService.takePhoto();
      await _cameraService.runPrediction();
    } catch (e) {
      debugPrint("Capture Error: $e");
    }
  }

  Future<void> _cropImage() async {
    try {
      await _cameraService.cropImage();
      await _cameraService.runPrediction();
    } catch (e) {
      debugPrint("Crop Error: $e");
    }
  }

  void _revertToOriginal() {
    final originalPath = ref.read(originalImagePathProvider);
    if (originalPath != null) {
      ref.read(processedImagePathProvider.notifier).state = originalPath;
      _cameraService.runPrediction();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ref.watch(themeModeProvider) == ThemeMode.dark;
    final selectedImagePath = ref.watch(processedImagePathProvider);
    final originalPath = ref.watch(originalImagePathProvider);
    final statusMessage = ref.watch(statusMessageProvider);
    final predictionResult = ref.watch(predictionResultProvider);

    // ── RESULT SCREEN ──
    if (selectedImagePath != null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF1F8E9),
        appBar: AppBar(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          elevation: 0,
          title: const Text("Analysis Result"),
          actions: [
            if (selectedImagePath != originalPath)
              IconButton(
                icon: const Icon(Icons.restore),
                tooltip: "Revert to Original",
                onPressed: _revertToOriginal,
              ),
          ],
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                    child: Image.file(
                      File(selectedImagePath),
                      width: double.infinity,
                      height: 300,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    bottom: 16,
                    right: 16,
                    child: FloatingActionButton(
                      mini: true,
                      heroTag: 'crop_btn',
                      backgroundColor: Colors.white,
                      onPressed: _cropImage,
                      child: const Icon(Icons.crop, color: Colors.green),
                    ),
                  ),
                  if (statusMessage.isNotEmpty)
                    Container(
                      height: 300,
                      color: Colors.black.withOpacity(0.3),
                      child: Center(
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const CircularProgressIndicator(
                                  color: Colors.green,
                                ),
                                const SizedBox(height: 10),
                                Text(statusMessage),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              if (predictionResult != null) ...[
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Consumer(
                    builder: (context, ref, child) {
                      final textData = ref.watch(textProvider);
                      return Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.shade100,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: textData.maybeWhen(
                              data: (data) => Text(
                                "${data['confidence'] ?? 'Confidence'}: ${(predictionResult!.confidence * 100).toStringAsFixed(1)}%",
                                style: TextStyle(
                                  color: Colors.green.shade900,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              orElse: () => Text(
                                "Confidence: ${(predictionResult!.confidence * 100).toStringAsFixed(1)}%",
                                style: TextStyle(
                                  color: Colors.green.shade900,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            predictionResult!.diseaseName,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),
                ..._buildCureDetails(predictionResult!.diseaseName),
                const SizedBox(height: 30),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.refresh),
                      label: Consumer(
                        builder: (context, ref, child) {
                          final textData = ref.watch(textProvider);
                          return Text(
                            textData.maybeWhen(
                              data: (data) =>
                                  data['scanAgain'] ?? 'Scan Another Leaf',
                              orElse: () => 'Scan Another Leaf',
                            ),
                          );
                        },
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 3,
                      ),
                      onPressed: () {
                        ref.read(processedImagePathProvider.notifier).state =
                            null;
                        ref.read(originalImagePathProvider.notifier).state =
                            null;
                        ref.read(predictionResultProvider.notifier).state =
                            null;
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ],
          ),
        ),
      );
    }

    // ── CAMERA / LOADING / ERROR SCREEN ──
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Builder(
          builder: (context) {
            switch (_initStatus) {
              case CameraInitStatus.initializing:
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      CircularProgressIndicator(color: Colors.white),
                      SizedBox(height: 24),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          "Preparing camera... may take 5–15s on first use",
                          style: TextStyle(color: Colors.white, fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                );

              case CameraInitStatus.permissionDenied:
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.no_photography,
                        size: 80,
                        color: Colors.redAccent,
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        "Camera permission denied",
                        style: TextStyle(color: Colors.white, fontSize: 20),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.settings),
                        label: const Text("Grant Permission"),
                        onPressed: openAppSettings,
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: _initializeAsync,
                        child: const Text(
                          "Retry",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                );

              case CameraInitStatus.timeout:
              case CameraInitStatus.error:
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 80,
                          color: Colors.orange,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage ?? "Failed to open camera",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.refresh),
                          label: const Text("Try Again"),
                          onPressed: _initializeAsync,
                        ),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: openAppSettings,
                          child: const Text(
                            "Check Settings",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                );

              case CameraInitStatus.ready:
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    if (_cameraService.controller.value.isInitialized)
                      CameraPreview(_cameraService.controller)
                    else
                      const Center(
                        child: Text(
                          "Camera ready but preview not available",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    Positioned(
                      bottom: 40,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          GestureDetector(
                            onTap: () => _pickImage(ImageSource.gallery),
                            child: Container(
                              height: 60,
                              width: 60,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.9),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 10,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.photo_library,
                                color: Colors.black,
                                size: 28,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: _takePhoto,
                            child: Container(
                              height: 75,
                              width: 75,
                              decoration: BoxDecoration(
                                color: Colors.transparent,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 5,
                                ),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
            }
          },
        ),
      ),
    );
  }
}
