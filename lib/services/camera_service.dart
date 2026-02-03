import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image/image.dart' as img;
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';
import '../models/ai_model.dart';
import '../providers/settings_provider.dart';
import '../providers/home_provider.dart';

class CameraService {
  final WidgetRef ref;

  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  bool _isInitializing = false;

  final AiModel _aiModel = AiModel();
  final ImagePicker _picker = ImagePicker();

  CameraService(this.ref);

  Future<void> initializeCamera() async {
    if (_isInitializing) {
      debugPrint("Camera init already in progress, skipping...");
      return;
    }

    _isInitializing = true;
    debugPrint("Starting camera initialization...");

    try {
      // Request permission with better handling
      final status = await Permission.camera.request();
      if (!status.isGranted) {
        if (status.isPermanentlyDenied) {
          debugPrint("Camera permission permanently denied");
          openAppSettings(); // optional: prompt user to settings
        }
        throw Exception("Camera permission not granted: ${status.name}");
      }

      // Get cameras with timeout
      _cameras = await availableCameras().timeout(
        const Duration(seconds: 5),
        onTimeout: () =>
            throw TimeoutException("No cameras found after timeout"),
      );

      if (_cameras == null || _cameras!.isEmpty) {
        throw Exception("No cameras available on this device");
      }

      // Prefer back camera, fallback to first available
      CameraDescription cameraDesc = _cameras!.firstWhere(
        (cam) => cam.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras!.first,
      );

      debugPrint(
        "Using camera: ${cameraDesc.name} (${cameraDesc.lensDirection})",
      );

      _controller = CameraController(
        cameraDesc,
        ResolutionPreset
            .ultraHigh, // balanced: faster than high, better quality than low
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg, // most compatible
      );

      await _controller!.initialize().timeout(
        const Duration(seconds: 10),
        onTimeout: () =>
            throw TimeoutException("Camera controller init timeout"),
      );

      _isCameraInitialized = true;
      debugPrint("Camera initialized successfully");
    } catch (e, stack) {
      debugPrint("Camera init failed: $e\n$stack");
      // Clean up partial init
      if (_controller != null) {
        await _controller!.dispose().catchError((_) {});
        _controller = null;
      }
      rethrow; // Let caller handle UI error
    } finally {
      _isInitializing = false;
    }
  }

  Future<void> pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(
        source: source,
        imageQuality:
            85, // ← lowered from 100 — huge perf gain, still good quality
        preferredCameraDevice: CameraDevice.rear,
      );

      if (pickedFile != null) {
        ref.read(originalImagePathProvider.notifier).state = pickedFile.path;
        ref.read(processedImagePathProvider.notifier).state = pickedFile.path;
      }
    } catch (e) {
      debugPrint("Image picking failed: $e");
      rethrow;
    }
  }

  Future<void> takePhoto() async {
    if (!_isCameraInitialized ||
        _controller == null ||
        !_controller!.value.isInitialized) {
      throw Exception("Camera not ready");
    }

    try {
      final image = await _controller!.takePicture();
      ref.read(originalImagePathProvider.notifier).state = image.path;
      ref.read(processedImagePathProvider.notifier).state = image.path;
    } catch (e) {
      debugPrint("Photo capture failed: $e");
      rethrow;
    }
  }

  Future<void> cropImage() async {
    final originalPath = ref.read(originalImagePathProvider);
    if (originalPath == null || originalPath.isEmpty) return;

    try {
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: originalPath,
        aspectRatio: const CropAspectRatio(ratioX: 1.0, ratioY: 1.0),
        compressQuality: 85, // ← added: reduce file size
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Image',
            toolbarColor: Colors.deepOrange,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false,
          ),
          IOSUiSettings(title: 'Crop Image'),
        ],
      );

      if (croppedFile != null) {
        ref.read(processedImagePathProvider.notifier).state = croppedFile.path;
      }
    } catch (e) {
      debugPrint("Crop failed: $e");
      rethrow;
    }
  }

  Future<void> runPrediction() async {
    final imagePath = ref.read(processedImagePathProvider);
    if (imagePath == null || imagePath.isEmpty) return;

    try {
      // Ensure model is ready
      final interpreter = await ref.read(interpreterProvider.future);
      if (interpreter == null) {
        ref.read(statusMessageProvider.notifier).state = "AI model not loaded";
        return;
      }

      _aiModel.setInterpreter(interpreter);

      final locale = ref.read(localeProvider);
      await _aiModel.loadModel(lang: locale.languageCode);

      final imageFile = File(imagePath);
      final bytes = await imageFile.readAsBytes();
      final decoded = img.decodeImage(bytes);

      if (decoded == null) throw Exception("Failed to decode image");

      final resized = img.copyResize(decoded, width: 224, height: 224);

      final prediction = await _aiModel.predict(resized);

      if (prediction != null) {
        ref.read(predictionResultProvider.notifier).state = prediction;
      } else {
        ref.read(statusMessageProvider.notifier).state = "No prediction result";
      }
    } catch (e, stack) {
      debugPrint("Prediction failed: $e\n$stack");
      ref.read(statusMessageProvider.notifier).state = "Analysis failed: $e";
      rethrow;
    }
  }

  CameraController? get controller => _controller;
  bool get isInitialized =>
      _isCameraInitialized && _controller?.value.isInitialized == true;

  void dispose() {
    _controller?.dispose().catchError(
      (e) => debugPrint("Controller dispose error: $e"),
    );
    _controller = null;
    _isCameraInitialized = false;
    _aiModel.closeInterpreter();
    debugPrint("CameraService disposed");
  }
}
