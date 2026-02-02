import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image/image.dart' as img;
import 'package:permission_handler/permission_handler.dart';

import '../models/ai_model.dart';
import '../providers/settings_provider.dart';
import '../providers/home_provider.dart';

class CameraService {
  final WidgetRef ref;

  late CameraController _controller;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  bool _isInitializing = false;

  final AiModel _aiModel = AiModel();
  final ImagePicker _picker = ImagePicker();

  CameraService(this.ref);

  // Camera Hardware: Initialize CameraController and handle permissions
  Future<void> initializeCamera() async {
    if (_isInitializing) {
      debugPrint(
        "Camera initialization already in progress, skipping concurrent call",
      );
      return;
    }

    _isInitializing = true;
    debugPrint("Starting camera initialization...");

    try {
      final status = await Permission.camera.request();
      debugPrint("Camera permission status: ${status.name}");

      if (!status.isGranted) {
        // Check if it was permanently denied to handle differently
        if (status.isPermanentlyDenied) {
          debugPrint("Camera permission permanently denied");
          throw Exception("Camera permission permanently denied");
        }
        debugPrint("Camera permission denied");
        throw Exception("Camera permission denied");
      }

      debugPrint("Fetching available cameras...");
      // 2. Add a timeout to prevent infinite hanging
      _cameras = await availableCameras().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          debugPrint("Timeout: No cameras found after 5 seconds");
          throw Exception("Timeout: No cameras found");
        },
      );
      debugPrint("Found ${_cameras?.length ?? 0} cameras");

      if (_cameras == null || _cameras!.isEmpty) {
        debugPrint("No cameras available on device");
        throw Exception("No cameras found");
      }

      // 3. Try to pick the back camera, or fallback to front
      CameraDescription cameraDesc = _cameras!.firstWhere(
        (cam) => cam.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras!.first,
      );
      debugPrint(
        "Selected camera: ${cameraDesc.name} (${cameraDesc.lensDirection})",
      );

      _controller = CameraController(
        cameraDesc, // Use the selected camera description
        ResolutionPreset.low, // Low resolution for faster hardware setup
        enableAudio: false,
      );
      debugPrint("Created CameraController with low resolution preset");

      // 4. Add timeout to the controller initialization as well
      debugPrint("Initializing camera controller...");
      await _controller.initialize().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          debugPrint(
            "Timeout: Camera controller failed to initialize after 10 seconds",
          );
          throw Exception("Timeout: Camera controller failed to initialize");
        },
      );
      debugPrint("Camera controller initialized successfully");

      _isCameraInitialized = true;
      debugPrint("Camera initialization completed successfully");
    } catch (e) {
      debugPrint("Camera initialization failed: $e");
      // Ensure we dispose if init fails partially
      if (_controller.value.isInitialized) {
        debugPrint("Disposing partially initialized controller");
        _controller.dispose();
      }
      throw Exception("Camera initialization failed: $e");
    } finally {
      _isInitializing = false;
    }
  }

  // Image Picking: Use ImagePicker to get images from Gallery or Camera, save to originalImagePathProvider
  Future<void> pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 100,
      );

      if (pickedFile != null) {
        ref.read(originalImagePathProvider.notifier).state = pickedFile.path;
        ref.read(processedImagePathProvider.notifier).state = pickedFile.path;
      }
    } catch (e) {
      throw Exception("Image picking failed: $e");
    }
  }

  // Take photo with camera
  Future<void> takePhoto() async {
    if (!_isCameraInitialized) return;

    try {
      final image = await _controller.takePicture();
      ref.read(originalImagePathProvider.notifier).state = image.path;
      ref.read(processedImagePathProvider.notifier).state = image.path;
    } catch (e) {
      throw Exception("Taking photo failed: $e");
    }
  }

  // Cropping: Use ImageCropper to crop from originalImagePathProvider and save to processedImagePathProvider
  Future<void> cropImage() async {
    final originalPath = ref.read(originalImagePathProvider);
    if (originalPath == null) return;

    try {
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: originalPath,
        aspectRatio: const CropAspectRatio(ratioX: 1.0, ratioY: 1.0),
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Cropper',
            toolbarColor: Colors.deepOrange,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false,
          ),
          IOSUiSettings(title: 'Cropper'),
        ],
      );

      if (croppedFile != null) {
        ref.read(processedImagePathProvider.notifier).state = croppedFile.path;
      }
    } catch (e) {
      throw Exception("Cropping failed: $e");
    }
  }

  // Prediction: runPrediction method that reads processedImagePathProvider, resizes using image package, runs AiModel with localeProvider language code, saves to predictionResultProvider
  Future<void> runPrediction() async {
    final imagePath = ref.read(processedImagePathProvider);
    if (imagePath == null) return;

    try {
      // Load model with current language
      final locale = ref.read(localeProvider);
      await _aiModel.loadModel(lang: locale.languageCode);

      final imageFile = File(imagePath);
      final rawBytes = await imageFile.readAsBytes();
      final decodedImage = img.decodeImage(rawBytes);

      if (decodedImage == null) {
        throw Exception("Failed to decode image");
      }

      final resizedImage = img.copyResize(
        decodedImage,
        width: 224,
        height: 224,
      );

      final prediction = await _aiModel.predict(resizedImage);

      if (prediction != null) {
        ref.read(predictionResultProvider.notifier).state = prediction;
      }
    } catch (e) {
      throw Exception("Prediction failed: $e");
    }
  }

  // Getters for camera access
  CameraController get controller => _controller;
  bool get isInitialized => _isCameraInitialized;

  // Disposal: Ensure dispose() properly closes the CameraController and TFLite interpreter
  void dispose() {
    if (_isCameraInitialized) {
      _controller.dispose();
    }
    _aiModel.closeInterpreter();
  }
}
