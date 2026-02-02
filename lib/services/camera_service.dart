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

final AiModel _aiModel = AiModel();
final ImagePicker _picker = ImagePicker();

CameraService(this.ref);

// Camera Hardware: Initialize CameraController and handle permissions
Future<void> initializeCamera() async {
final status = await Permission.camera.request();
if (!status.isGranted) {
throw Exception("Camera permission denied");
}

try {
_cameras = await availableCameras();
if (_cameras == null || _cameras!.isEmpty) {
throw Exception("No cameras found");
}

_controller = CameraController(
_cameras!.first,
ResolutionPreset.medium,
enableAudio: false,
);

await _controller.initialize();
_isCameraInitialized = true;
} catch (e) {
throw Exception("Camera initialization failed: $e");
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