import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import '../../providers/home_provider.dart';
import '../../providers/text_provider.dart';
import '../../providers/settings_provider.dart';
import '../../services/camera_service.dart';
import '../../services/db_service.dart';
import '../../models/scan_history_model.dart';
import '../../models/ai_model.dart';
import '../../widgets/app_drawer.dart';

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
  bool _isProcessing = false;
  bool _isFlashOn = false;

  CameraInitStatus _initStatus = CameraInitStatus.initializing;
  String? _errorMessage;

  Map<String, dynamic> _cureData = {};
  bool _hasSavedScan = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _cameraService = CameraService(ref);

    // Load initial cure data
    _loadCureData();

    // Note: Removed illegal ref.listen<Locale> from here
    // Locale change handling moved to build() if needed (or use ref.watch + effect)

    _initializeAsync();
  }

  Future<void> _loadCureData() async {
    final locale = ref.read(localeProvider);
    final cureFile = locale.languageCode == 'ne'
        ? 'assets/labels/cure_ne.json'
        : 'assets/labels/cure_en.json';

    debugPrint("Loading cure data for ${locale.languageCode}: $cureFile");

    try {
      final jsonString = await rootBundle.loadString(cureFile);
      final decoded = json.decode(jsonString);
      debugPrint("CURE DATA LOADED: ${decoded.length} entries");
      debugPrint("Sample keys: ${decoded.keys.take(5).join(' | ')}...");

      if (mounted) {
        setState(() => _cureData = decoded);
      }
    } catch (e) {
      debugPrint("ERROR loading cure data: $e");
    }
  }

  Future<void> _initializeAsync() async {
    if (!mounted) return;

    setState(() {
      _initStatus = CameraInitStatus.initializing;
      _errorMessage = null;
    });

    try {
      await _loadCureData();

      var status = await Permission.camera.status;
      if (!status.isGranted) {
        status = await Permission.camera.request();
        if (!status.isGranted) {
          setState(() => _initStatus = CameraInitStatus.permissionDenied);
          _showPermissionDialog();
          return;
        }
      }

      debugPrint("Starting camera initialization...");
      await _cameraService.initializeCamera().timeout(
        const Duration(seconds: 12),
        onTimeout: () =>
            throw TimeoutException("Camera initialization timeout"),
      );

      if (mounted) {
        setState(() => _initStatus = CameraInitStatus.ready);
      }
    } catch (e, stack) {
      debugPrint("Camera init failed: $e\n$stack");
      String msg = "Failed to open camera. Please try again.";
      CameraInitStatus status = CameraInitStatus.error;

      if (e is TimeoutException) {
        msg = "Camera taking too long to start.\nThis can happen on first use.";
        status = CameraInitStatus.timeout;
      } else if (e.toString().toLowerCase().contains("permission")) {
        status = CameraInitStatus.permissionDenied;
        _showPermissionDialog();
      }

      if (mounted) {
        setState(() {
          _initStatus = status;
          _errorMessage = msg;
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
      builder: (_) => AlertDialog(
        title: const Text("Camera Permission Required"),
        content: const Text("Please allow camera access to scan leaves."),
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
    if (controller == null || !controller.value.isInitialized) return;

    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      controller.setFlashMode(FlashMode.off);
      _isFlashOn = false;
      controller.stopImageStream();
      controller.pausePreview();
      debugPrint("LIFECYCLE PAUSE: Torch OFF + preview paused");
    } else if (state == AppLifecycleState.resumed) {
      if (_initStatus == CameraInitStatus.ready) {
        controller.resumePreview();
        debugPrint("LIFECYCLE RESUME: Preview resumed");
      } else {
        _initializeAsync();
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    final controller = _cameraService.controller;
    if (controller != null && controller.value.isInitialized) {
      controller.setFlashMode(FlashMode.off);
      _isFlashOn = false;
      controller.stopImageStream();
      controller.dispose();
      debugPrint("DISPOSE: Torch FORCED OFF + camera disposed");
    }
    _cameraService.dispose();
    super.dispose();
  }

  Future<void> _toggleFlash() async {
    final controller = _cameraService.controller;
    if (controller == null || !controller.value.isInitialized) return;

    try {
      if (_isFlashOn) {
        await controller.setFlashMode(FlashMode.off);
        debugPrint("Flash turned OFF");
      } else {
        await controller.setFlashMode(FlashMode.torch);
        debugPrint("Flash turned ON (torch)");
      }
      if (mounted) setState(() => _isFlashOn = !_isFlashOn);
    } catch (e) {
      debugPrint("Flash toggle error: $e");
    }
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String content,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: colorScheme.primary, size: 24),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              content,
              style: TextStyle(
                fontSize: 14,
                color: colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildCureDetails(String diseaseKey) {
    debugPrint("=== CURE LOOKUP START ===");
    debugPrint("Using diseaseKey from model: '$diseaseKey'");

    if (_cureData.isEmpty) {
      debugPrint("CURE DATA IS EMPTY - no keys available");
      return [
        _buildInfoCard(
          icon: Icons.info_outline,
          title: "कुनै जानकारी उपलब्ध छैन",
          content: "उपचार डाटा लोड भएको छैन।",
        ),
      ];
    }

    debugPrint("Total cure entries: ${_cureData.length}");
    debugPrint("First 5 keys: ${_cureData.keys.take(5).join(' | ')}");

    final cleanKey = diseaseKey
        .replaceAll('_', ' ')
        .replaceAll('-', ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    debugPrint("Cleaned key for lookup: '$cleanKey'");

    var cureInfo = _cureData[diseaseKey] ?? _cureData[cleanKey];
    if (cureInfo != null) {
      debugPrint("EXACT MATCH found for '$diseaseKey' or '$cleanKey'");
      return _generateCureWidgets(cureInfo);
    }

    debugPrint("No exact match → trying fuzzy contains...");
    for (var key in _cureData.keys) {
      final clean = key
          .replaceAll('_', ' ')
          .replaceAll('-', ' ')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim()
          .toLowerCase();

      if (clean == cleanKey.toLowerCase() ||
          clean.contains(cleanKey.toLowerCase()) ||
          cleanKey.toLowerCase().contains(clean)) {
        debugPrint("FUZZY MATCH FOUND: '$key'");
        cureInfo = _cureData[key];
        return _generateCureWidgets(cureInfo);
      }
    }

    debugPrint("NO MATCH FOUND AT ALL - showing fallback");
    return [
      _buildInfoCard(
        icon: Icons.info_outline,
        title: "कुनै उपचार जानकारी उपलब्ध छैन",
        content: "यो रोगको लागि नेपाली भाषामा उपचार जानकारी उपलब्ध छैन।",
      ),
    ];
  }

  List<Widget> _generateCureWidgets(Map<String, dynamic> cureInfo) {
    final textData = ref.watch(textProvider);

    String getLabel(String key, String fallback) {
      return textData.maybeWhen(
        data: (data) => data[key] ?? fallback,
        orElse: () => fallback,
      );
    }

    final widgets = <Widget>[];

    final fields = [
      {'key': 'Description', 'fallback': 'विवरण', 'icon': Icons.article},
      {'key': 'Cause', 'fallback': 'कारण', 'icon': Icons.coronavirus},
      {'key': 'Symptoms', 'fallback': 'लक्षणहरू', 'icon': Icons.monitor_heart},
      {'key': 'Prevention', 'fallback': 'रोकथाम', 'icon': Icons.shield},
      {'key': 'Treatment', 'fallback': 'उपचार', 'icon': Icons.medical_services},
    ];

    for (var f in fields) {
      final key = f['key'] as String;
      if (cureInfo.containsKey(key) &&
          cureInfo[key] != null &&
          cureInfo[key].toString().isNotEmpty) {
        widgets.add(
          _buildInfoCard(
            icon: f['icon'] as IconData,
            title: getLabel(key.toLowerCase(), f['fallback'] as String),
            content: cureInfo[key].toString(),
          ),
        );
      }
    }

    if (widgets.isEmpty) {
      widgets.add(
        _buildInfoCard(
          icon: Icons.info_outline,
          title: "कुनै उपचार जानकारी उपलब्ध छैन",
          content: "यो रोगको लागि नेपाली भाषामा विवरण उपलब्ध छैन।",
        ),
      );
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
    setState(() => _isProcessing = true);
    try {
      await _cameraService.takePhoto();
      await _cameraService.runPrediction();
    } catch (e) {
      debugPrint("Capture Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error capturing photo: $e")));
      }
    } finally {
      final controller = _cameraService.controller;
      if (controller != null && controller.value.isInitialized) {
        await controller.setFlashMode(FlashMode.off);
        _isFlashOn = false;
        debugPrint("Photo taken → torch FORCED OFF");
      }
      if (mounted) setState(() => _isProcessing = false);
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
    final colorScheme = Theme.of(context).colorScheme;
    final backgroundColor = isDarkMode
        ? colorScheme.surface
        : const Color(0xFFF1F8E9);

    final selectedImagePath = ref.watch(processedImagePathProvider);
    final predictionResult = ref.watch(predictionResultProvider);
    final statusMessage = ref.watch(statusMessageProvider);

    // Safe place for ref.listen — runs only when result changes
    ref.listen<PredictionResult?>(predictionResultProvider, (previous, next) {
      if (next == null || _hasSavedScan) return;
      final path = ref.read(processedImagePathProvider);
      if (path == null || path.isEmpty) return;

      // Get cure information for the disease
      String? cause, symptoms, prevention, treatment, description;
      final cureKey = next.diseaseKey ?? next.diseaseName;
      final cleanKey = cureKey
          .replaceAll('_', ' ')
          .replaceAll('-', ' ')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();
      var cureInfo = _cureData[cureKey] ?? _cureData[cleanKey];
      if (cureInfo == null) {
        for (var key in _cureData.keys) {
          final clean = key
              .replaceAll('_', ' ')
              .replaceAll('-', ' ')
              .replaceAll(RegExp(r'\s+'), ' ')
              .trim()
              .toLowerCase();
          if (clean == cleanKey.toLowerCase() ||
              clean.contains(cleanKey.toLowerCase()) ||
              cleanKey.toLowerCase().contains(clean)) {
            cureInfo = _cureData[key];
            break;
          }
        }
      }
      if (cureInfo != null) {
        cause = cureInfo['Cause'];
        symptoms = cureInfo['Symptoms'];
        prevention = cureInfo['Prevention'];
        treatment = cureInfo['Treatment'];
        description = cureInfo['Description'];
      }

      // Create detailed notes from cure information
      String? detailedNotes;
      if (description != null ||
          cause != null ||
          symptoms != null ||
          prevention != null ||
          treatment != null) {
        final notesList = <String>[];
        if (description != null && description.isNotEmpty)
          notesList.add('Description: $description');
        if (cause != null && cause.isNotEmpty) notesList.add('Cause: $cause');
        if (symptoms != null && symptoms.isNotEmpty)
          notesList.add('Symptoms: $symptoms');
        if (prevention != null && prevention.isNotEmpty)
          notesList.add('Prevention: $prevention');
        if (treatment != null && treatment.isNotEmpty)
          notesList.add('Treatment: $treatment');
        detailedNotes = notesList.join('\n\n');
      }

      // Save scan asynchronously
      () async {
        await DBService.insertScan(
          ScanHistoryModel(
            id: '${DateTime.now().millisecondsSinceEpoch}_${next.diseaseKey ?? 'unknown'}',
            imagePath: path,
            diseaseKey: next.diseaseKey ?? next.diseaseName,
            diseaseName: next.diseaseName,
            confidence: next.confidence,
            plantType: 'Unknown', // Could be enhanced to detect plant type
            notes: detailedNotes,
            timestamp: DateTime.now().millisecondsSinceEpoch,
          ),
        );

        // Invalidate recentScansProvider to refresh home screen
        ref.invalidate(recentScansProvider);

        _hasSavedScan = true;
      }();
    });

    // Force torch OFF in result screen
    if (selectedImagePath != null) {
      final controller = _cameraService.controller;
      if (controller != null && controller.value.isInitialized) {
        controller.setFlashMode(FlashMode.off);
        _isFlashOn = false;
        debugPrint("RESULT SCREEN → torch FORCED OFF");
      }
    }

    if (selectedImagePath != null) {
      final themeMode = ref.watch(themeModeProvider);
      final isDark = themeMode == ThemeMode.dark;

      final backgroundGradient = LinearGradient(
        begin: Alignment.topCenter,
        colors: isDark
            ? [Colors.grey[700]!, Colors.grey[900]!]
            : [Colors.green[100]!, Colors.green[200]!, Colors.green[500]!],
      );

      final textColor = isDark ? Colors.white : Colors.white70;
      final subtitleColor = isDark ? Colors.grey[300] : Colors.white70;
      final cardColor = isDark ? Colors.grey[700] : Colors.green[50];

      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.green[700],
          foregroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              ref.read(processedImagePathProvider.notifier).state = null;
              ref.read(originalImagePathProvider.notifier).state = null;
              ref.read(predictionResultProvider.notifier).state = null;
              _hasSavedScan = false; // allow saving next scan
            },
          ),
          title: Consumer(
            builder: (context, ref, child) {
              final textData = ref.watch(textProvider);
              return Text(
                textData.maybeWhen(
                  data: (data) => data['analysisResult'] ?? 'Analysis Result',
                  orElse: () => 'Analysis Result',
                ),
              );
            },
          ),
        ),
        body: Container(
          decoration: BoxDecoration(gradient: backgroundGradient),
          child: SingleChildScrollView(
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
                        backgroundColor: colorScheme.surface,
                        onPressed: _cropImage,
                        child: Icon(Icons.crop, color: colorScheme.primary),
                      ),
                    ),
                    if (statusMessage.isNotEmpty)
                      Container(
                        height: 300,
                        color: Colors.black.withOpacity(0.4),
                        child: Center(
                          child: Card(
                            color: colorScheme.surface,
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CircularProgressIndicator(
                                    color: colorScheme.primary,
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    statusMessage,
                                    style: TextStyle(
                                      color: colorScheme.onSurface,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    if (_isProcessing)
                      Container(
                        height: 300,
                        color: Colors.black.withOpacity(0.5),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(
                                color: colorScheme.primary,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                "Analyzing...",
                                style: TextStyle(color: Colors.white),
                              ),
                            ],
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
                                color: colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: textData.maybeWhen(
                                data: (data) => Text(
                                  "${predictionResult!.diseaseName} (${(predictionResult!.confidence * 100).toStringAsFixed(1)}%)",
                                  style: TextStyle(
                                    color: colorScheme.onPrimaryContainer,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                                orElse: () => Text(
                                  "${predictionResult!.diseaseName} (${(predictionResult!.confidence * 100).toStringAsFixed(1)}%)",
                                  style: TextStyle(
                                    color: colorScheme.onPrimaryContainer,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                  ..._buildCureDetails(
                    predictionResult!.diseaseKey ??
                        predictionResult!.diseaseName,
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.add_alarm),
                            label: Consumer(
                              builder: (context, ref, child) {
                                final textData = ref.watch(textProvider);
                                return Text(
                                  textData.maybeWhen(
                                    data: (data) =>
                                        data['addReminder'] ?? 'Add Reminder',
                                    orElse: () => 'Add Reminder',
                                  ),
                                );
                              },
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.yellowAccent,
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              elevation: 3,
                            ),
                            onPressed: () {
                              // Get cure information for the disease
                              final cureKey =
                                  predictionResult!.diseaseKey ??
                                  predictionResult!.diseaseName;
                              final cleanKey = cureKey
                                  .replaceAll('_', ' ')
                                  .replaceAll('-', ' ')
                                  .replaceAll(RegExp(r'\s+'), ' ')
                                  .trim();
                              var cureInfo =
                                  _cureData[cureKey] ?? _cureData[cleanKey];
                              if (cureInfo == null) {
                                for (var key in _cureData.keys) {
                                  final clean = key
                                      .replaceAll('_', ' ')
                                      .replaceAll('-', ' ')
                                      .replaceAll(RegExp(r'\s+'), ' ')
                                      .trim()
                                      .toLowerCase();
                                  if (clean == cleanKey.toLowerCase() ||
                                      clean.contains(cleanKey.toLowerCase()) ||
                                      cleanKey.toLowerCase().contains(clean)) {
                                    cureInfo = _cureData[key];
                                    break;
                                  }
                                }
                              }

                              final extraData = {
                                'title': predictionResult!.diseaseName,
                                'description':
                                    cureInfo?['Description']?.toString() ?? '',
                                'cause': cureInfo?['Cause']?.toString() ?? '',
                                'symptoms':
                                    cureInfo?['Symptoms']?.toString() ?? '',
                                'prevention':
                                    cureInfo?['Prevention']?.toString() ?? '',
                                'treatment':
                                    cureInfo?['Treatment']?.toString() ?? '',
                                'imagePath': selectedImagePath,
                                'reminderTime': DateTime.now()
                                    .add(const Duration(minutes: 1))
                                    .millisecondsSinceEpoch,
                              };
                              context.push('/reminder/edit', extra: extraData);
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.refresh),
                            label: Consumer(
                              builder: (context, ref, child) {
                                final textData = ref.watch(textProvider);
                                return Text(
                                  textData.maybeWhen(
                                    data: (data) =>
                                        data['scanAgain'] ??
                                        'Scan Another Leaf',
                                    orElse: () => 'Scan Another Leaf',
                                  ),
                                );
                              },
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colorScheme.primary,
                              foregroundColor: colorScheme.onPrimary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              elevation: 3,
                            ),
                            onPressed: () {
                              ref
                                      .read(processedImagePathProvider.notifier)
                                      .state =
                                  null;
                              ref
                                      .read(originalImagePathProvider.notifier)
                                      .state =
                                  null;
                              ref
                                      .read(predictionResultProvider.notifier)
                                      .state =
                                  null;
                              _hasSavedScan = false; // allow saving next scan
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }

    // ── CAMERA PREVIEW ──
    return Scaffold(
      appBar: AppBar(
        title: Text(ref.watch(currentTextProvider('camera')) ?? 'Camera'),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
      ),
      drawer: AppDrawer(),
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Builder(
          builder: (context) {
            switch (_initStatus) {
              case CameraInitStatus.initializing:
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
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

              case CameraInitStatus.ready:
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    CameraPreview(_cameraService.controller!),
                    if (_isProcessing)
                      Container(
                        color: Colors.black54,
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                "Analyzing image...",
                                style: TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
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
                            onTap: _toggleFlash,
                            child: Container(
                              height: 60,
                              width: 60,
                              decoration: BoxDecoration(
                                color: _isFlashOn
                                    ? Colors.amber.withOpacity(0.9)
                                    : Colors.white.withOpacity(0.9),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 10,
                                  ),
                                ],
                              ),
                              child: Icon(
                                _isFlashOn ? Icons.flash_on : Icons.flash_off,
                                color: _isFlashOn
                                    ? Colors.black
                                    : Colors.black54,
                                size: 28,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: _isProcessing ? null : _takePhoto,
                            child: Container(
                              height: 75,
                              width: 75,
                              decoration: BoxDecoration(
                                color: _isProcessing
                                    ? Colors.grey
                                    : Colors.transparent,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 5,
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: _isProcessing
                                  ? const CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    )
                                  : null,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
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
            }
          },
        ),
      ),
    );
  }
}
