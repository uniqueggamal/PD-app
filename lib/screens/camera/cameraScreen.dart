import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../models/ai_model.dart';
import '../../models/reminder_model.dart';
import '../../providers/text_provider.dart';
import '../../providers/reminder_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/home_provider.dart';
import '../../services/app_permissions.dart';
import '../reminder/reminder_edit_screen.dart';

class CameraScreen extends ConsumerStatefulWidget {
  const CameraScreen({super.key});

  @override
  ConsumerState<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends ConsumerState<CameraScreen> {
  final AiModel _aiModel = AiModel();

  @override
  void initState() {
    super.initState();
  }

  Future<void> _loadModel() async {
    try {
      final locale = ref.read(localeProvider);
      await _aiModel.loadModel(lang: locale.languageCode);
      if (!mounted) return;

      ref.read(statusMessageProvider.notifier).state =
          ref.read(currentTextProvider('takePhotos')) ?? 'Take a photo';
    } catch (e) {
      if (!mounted) return;
      ref.read(statusMessageProvider.notifier).state =
          "Error loading model: $e";
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    // Prevent multiple taps
    final isPicking = ref.read(isPickingImageProvider);
    if (isPicking) return;
    ref.read(isPickingImageProvider.notifier).state = true;

    try {
      debugPrint("--- Starting _pickImage from $source ---");

      // 1. Request Permission
      PermissionStatus status;
      if (source == ImageSource.camera) {
        status = await Permission.camera.request();
      } else {
        // Use photos for iOS/Android 13+, storage for older Android
        status = await Permission.photos.request();
      }

      debugPrint("Permission status: ${status.toString()}");

      // 2. Handle Permission Results
      if (!status.isGranted) {
        if (!mounted) return;

        String message;
        String title =
            ref.read(currentTextProvider('permissionDenied')) ??
            'Permission Denied';

        if (status.isPermanentlyDenied) {
          message = source == ImageSource.camera
              ? "Camera permission is permanently denied. Please enable it in App Settings."
              : "Gallery permission is permanently denied. Please enable it in App Settings.";
        } else {
          message = source == ImageSource.camera
              ? "Camera permission is required to take photos."
              : "Gallery permission is required to select photos.";
        }

        // Show Dialog
        await showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  ref.read(currentTextProvider('cancel')) ?? 'Cancel',
                ),
              ),
              if (status.isPermanentlyDenied)
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    openAppSettings();
                  },
                  child: Text(
                    ref.read(currentTextProvider('settings')) ?? 'Settings',
                  ),
                ),
            ],
          ),
        );
        return; // Stop execution if no permission
      }

      // 3. Pick Image
      debugPrint("Permissions granted. Launching ImagePicker...");
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        imageQuality: 80, // Reduce quality to prevent memory crashes
      );

      if (pickedFile != null) {
        debugPrint("Image picked: ${pickedFile.path}");
        if (!mounted) return;

        ref.read(selectedImagePathProvider.notifier).state = pickedFile.path;
        ref.read(predictionResultProvider.notifier).state = null;
        ref.read(statusMessageProvider.notifier).state =
            ref.read(currentTextProvider('predicting')) ?? 'Predicting...';

        await _runPrediction();
      } else {
        debugPrint("User cancelled picking image.");
      }
    } on PlatformException catch (e) {
      debugPrint("PLATFORM EXCEPTION in _pickImage: ${e.message}");
      if (!mounted) return;

      // Show specific error to user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Camera Error: ${e.message ?? 'Unknown error'}"),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e, stackTrace) {
      debugPrint("GENERAL EXCEPTION in _pickImage: $e");
      debugPrint(stackTrace.toString());
      if (!mounted) return;

      ref.read(statusMessageProvider.notifier).state = "Error: $e";
    } finally {
      if (mounted) ref.read(isPickingImageProvider.notifier).state = false;
    }
  }

  Future<void> _cropImage() async {
    final imagePath = ref.read(selectedImagePathProvider);
    if (imagePath == null) return;

    CroppedFile? croppedFile = await ImageCropper().cropImage(
      sourcePath: imagePath,
      maxWidth: 512,
      maxHeight: 512,
      compressQuality: 90,
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop Image',
          toolbarColor: Colors.deepOrange,
          toolbarWidgetColor: Colors.white,
          lockAspectRatio: false,
        ),
        IOSUiSettings(title: 'Crop Image'),
      ],
    );

    if (croppedFile != null) {
      ref.read(selectedImagePathProvider.notifier).state = croppedFile.path;
      ref.read(predictionResultProvider.notifier).state = null;
      ref.read(statusMessageProvider.notifier).state =
          ref.read(currentTextProvider('predicting')) ?? 'Predicting...';
      await _runPrediction();
    }
  }

  Future<void> _runPrediction() async {
    final imagePath = ref.read(selectedImagePathProvider);
    if (imagePath == null) return;

    try {
      // Load model here before prediction
      final locale = ref.read(localeProvider);
      await _aiModel.loadModel(lang: locale.languageCode);

      final selectedImage = File(imagePath);
      final rawBytes = await selectedImage.readAsBytes();
      final decodedImage = img.decodeImage(rawBytes);
      if (decodedImage == null) {
        ref.read(statusMessageProvider.notifier).state =
            "Error: Could not decode image";
        return;
      }

      final resizedImage = img.copyResize(
        decodedImage,
        width: 224,
        height: 224,
      );

      final prediction = await _aiModel.predict(resizedImage);
      if (!mounted) return;

      if (prediction == null) {
        ref.read(statusMessageProvider.notifier).state =
            "Unable to identify - Low confidence";
        return;
      }

      ref.read(predictionResultProvider.notifier).state = prediction;
      ref.read(statusMessageProvider.notifier).state = "";
    } catch (e) {
      if (!mounted) return;
      ref.read(statusMessageProvider.notifier).state =
          "Prediction failed - model may not be loaded properly";
      print("Prediction error: $e");
    }
  }

  void _addPredictionToReminder() {
    final predictionResult = ref.read(predictionResultProvider);
    final imagePath = ref.read(selectedImagePathProvider);
    if (predictionResult == null || imagePath == null) return;

    final reminder = ReminderModel(
      id: Random().nextInt(1000000).toString(),
      title: predictionResult.diseaseName,
      description: predictionResult.description,
      reminderTime: DateTime.now().add(const Duration(days: 1)),
      imagePath: imagePath,
      cause: predictionResult.cause,
      symptoms: predictionResult.symptoms,
      prevention: predictionResult.prevention,
      treatment: predictionResult.treatment,
    );

    ref.read(reminderProvider.notifier).addReminder(reminder);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddEditReminderScreen(reminder: reminder),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required String content,
    Color titleColor = Colors.black,
    Color contentColor = Colors.black87,
    Color surfaceTintColor = Colors.white,
  }) {
    if (content.isEmpty) return const SizedBox.shrink();
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      surfaceTintColor: surfaceTintColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (title.isNotEmpty)
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: titleColor,
                ),
              ),
            const SizedBox(height: 6),
            Text(content, style: TextStyle(fontSize: 14, color: contentColor)),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _aiModel.closeInterpreter();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ref.watch(themeModeProvider) == ThemeMode.dark;
    final selectedImagePath = ref.watch(selectedImagePathProvider);
    final statusMessage = ref.watch(statusMessageProvider);
    final isPickingImage = ref.watch(isPickingImageProvider);
    final predictionResult = ref.watch(predictionResultProvider);

    if (selectedImagePath != null) {
      // Show prediction results screen
      return Container(
        color: isDarkMode ? Colors.grey.shade900 : Colors.white,
        child: SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(height: 20),
              Center(
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _cropImage,
                      child: Image.file(
                        File(selectedImagePath),
                        height: 250,
                        width: MediaQuery.of(context).size.width * .94,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.crop),
                      label: Text(
                        ref.read(currentTextProvider('editCrop')) ??
                            'Crop Image',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orangeAccent.shade700,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: _cropImage,
                    ),
                  ],
                ),
              ),
              if (statusMessage.isNotEmpty) ...[
                const SizedBox(height: 20),
                Center(
                  child: Text(
                    statusMessage,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
              if (predictionResult != null) ...[
                const SizedBox(height: 20),
                _buildSectionCard(
                  title: ref.read(currentTextProvider('disease')) ?? 'Disease',
                  content:
                      "${predictionResult.diseaseName} (${(predictionResult.confidence * 100).toStringAsFixed(1)}%)",
                  titleColor: Colors.red,
                  contentColor: isDarkMode ? Colors.white70 : Colors.black87,
                  surfaceTintColor: isDarkMode ? Colors.red : Colors.redAccent,
                ),
                _buildSectionCard(
                  title:
                      ref.read(currentTextProvider('description')) ??
                      'Description',
                  content: predictionResult.description,
                  titleColor: isDarkMode
                      ? Colors.yellow.shade700
                      : Colors.yellow.shade900,
                  contentColor: isDarkMode ? Colors.white70 : Colors.black87,
                  surfaceTintColor: isDarkMode
                      ? Colors.yellow
                      : Colors.yellowAccent,
                ),
                _buildSectionCard(
                  title: ref.read(currentTextProvider('cause')) ?? 'Cause',
                  content: predictionResult.cause,
                  titleColor: isDarkMode ? Colors.cyanAccent : Colors.blue,
                  contentColor: isDarkMode ? Colors.white70 : Colors.black87,
                  surfaceTintColor: isDarkMode
                      ? Colors.blue
                      : Colors.lightBlueAccent,
                ),
                _buildSectionCard(
                  title:
                      ref.read(currentTextProvider('symptoms')) ?? 'Symptoms',
                  content: predictionResult.symptoms,
                  titleColor: isDarkMode
                      ? Colors.pinkAccent.shade100
                      : Colors.pinkAccent.shade700,
                  contentColor: isDarkMode ? Colors.white70 : Colors.black87,
                  surfaceTintColor: isDarkMode
                      ? Colors.pink
                      : Colors.pinkAccent,
                ),
                _buildSectionCard(
                  title:
                      ref.read(currentTextProvider('prevention')) ??
                      'Prevention',
                  content: predictionResult.prevention,
                  titleColor: isDarkMode ? Colors.amberAccent : Colors.orange,
                  contentColor: isDarkMode ? Colors.white70 : Colors.black87,
                  surfaceTintColor: isDarkMode
                      ? Colors.yellow.shade900
                      : Colors.amberAccent,
                ),
                _buildSectionCard(
                  title:
                      ref.read(currentTextProvider('treatment')) ?? 'Treatment',
                  content: predictionResult.treatment,
                  titleColor: isDarkMode
                      ? Colors.green.shade200
                      : Colors.green.shade400,
                  contentColor: isDarkMode ? Colors.white70 : Colors.black87,
                  surfaceTintColor: isDarkMode
                      ? Colors.green
                      : Colors.lightGreen,
                ),
                const SizedBox(height: 20),
                Center(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.add_alarm),
                    label: Text(
                      ref.read(currentTextProvider('addToReminders')) ??
                          'Add to Reminders',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    onPressed: _addPredictionToReminder,
                  ),
                ),
              ],
              const SizedBox(height: 30),
            ],
          ),
        ),
      );
    }

    // Show camera/gallery selection screen
    return Container(
      color: isDarkMode ? Colors.grey.shade900 : Colors.white,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Camera preview placeholder
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.camera_alt,
                    size: 100,
                    color: isDarkMode ? Colors.white54 : Colors.grey,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    statusMessage.isNotEmpty
                        ? statusMessage
                        : 'Select an option below',
                    style: TextStyle(
                      fontSize: 18,
                      color: isDarkMode ? Colors.white70 : Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),

          // Bottom controls
          Container(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Gallery button
                FloatingActionButton(
                  backgroundColor: Colors.white.withOpacity(0.9),
                  onPressed: isPickingImage
                      ? null
                      : () => _pickImage(ImageSource.gallery),
                  child: Icon(Icons.photo, color: Colors.black, size: 30),
                ),

                // Camera button
                FloatingActionButton(
                  backgroundColor: Colors.green,
                  onPressed: isPickingImage
                      ? null
                      : () => _pickImage(ImageSource.camera),
                  child: const Icon(Icons.camera_alt, size: 30),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
