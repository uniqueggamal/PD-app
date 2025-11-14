import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/ai_model.dart';
import '../models/reminder_model.dart';
import '../providers/text_provider.dart';
import '../providers/reminder_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/home_provider.dart';
import 'reminder_edit_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final AiModel _aiModel = AiModel();

  @override
  void initState() {
    super.initState();
    _loadModel();
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
    final isPicking = ref.read(isPickingImageProvider);
    if (isPicking) return;
    ref.read(isPickingImageProvider.notifier).state = true;

    try {
      // Check & request permission
      PermissionStatus status;
      if (source == ImageSource.camera) {
        status = await Permission.camera.request();
      } else {
        status = await Permission.photos
            .request(); // or Permission.storage for Android <13
      }

      if (!status.isGranted) {
        if (!mounted) return;

        // Determine proper message based on source
        final message = source == ImageSource.camera
            ? ref.read(currentTextProvider('cameraPermissionDenied')) ??
                  'Camera permission denied. Please enable it in settings.'
            : ref.read(currentTextProvider('galleryPermissionDenied')) ??
                  'Gallery permission denied. Please enable it in settings.';

        // Show a dialog guiding user to settings
        await showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: Text(
              ref.read(currentTextProvider('permissionDenied')) ??
                  'Permission denied',
            ),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  ref.read(currentTextProvider('cancel')) ?? 'Cancel',
                ),
              ),
              TextButton(
                onPressed: () {
                  openAppSettings(); // Open system app settings
                  Navigator.pop(context);
                },
                child: Text(
                  ref.read(currentTextProvider('settings')) ?? 'Settings',
                ),
              ),
            ],
          ),
        );
        return;
      }

      // Pick image if permission granted
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: source);

      if (pickedFile != null && mounted) {
        ref.read(selectedImagePathProvider.notifier).state = pickedFile.path;
        ref.read(predictionResultProvider.notifier).state = null;
        ref.read(statusMessageProvider.notifier).state =
            ref.read(currentTextProvider('predicting')) ?? 'Predicting...';
        await _runPrediction();
      }
    } on PlatformException catch (e) {
      if (!mounted) return;
      ref.read(statusMessageProvider.notifier).state =
          "Error picking image: ${e.message}";
    } catch (e) {
      if (!mounted) return;
      ref.read(statusMessageProvider.notifier).state =
          "Error picking image: $e";
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

    final selectedImage = File(imagePath);
    final rawBytes = await selectedImage.readAsBytes();
    final decodedImage = img.decodeImage(rawBytes);
    if (decodedImage == null) {
      ref.read(statusMessageProvider.notifier).state =
          "Error: Could not decode image";
      return;
    }

    final resizedImage = img.copyResize(decodedImage, width: 224, height: 224);

    try {
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
          "Error during prediction: $e";
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
  Widget build(BuildContext context) {
    final isDarkMode = ref.watch(themeModeProvider) == ThemeMode.dark;
    final selectedImagePath = ref.watch(selectedImagePathProvider);
    final statusMessage = ref.watch(statusMessageProvider);
    final isPickingImage = ref.watch(isPickingImageProvider);
    final predictionResult = ref.watch(predictionResultProvider);
    return Scaffold(
      backgroundColor: isDarkMode ? Colors.grey.shade900 : Colors.white,
      appBar: AppBar(
        title: Text(
          ref.read(currentTextProvider('appTitle')) ??
              'Plant Disease Detection',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.green,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: 20),
            Center(
              child: selectedImagePath != null
                  ? Column(
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
                    )
                  : Image.asset('assets/img/leafcam.png', height: 250),
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
            SizedBox(height: 20),
            Center(
              child: Wrap(
                spacing: 20,
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.photo),
                    label: Text(
                      ref.read(currentTextProvider('gallery')) ?? 'Gallery',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.lightGreen,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: isPickingImage
                        ? null
                        : () => _pickImage(ImageSource.gallery),
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.camera_alt),
                    label: Text(
                      ref.read(currentTextProvider('camera')) ?? 'Camera',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: isPickingImage
                        ? null
                        : () => _pickImage(ImageSource.camera),
                  ),
                ],
              ),
            ),

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
                title: ref.read(currentTextProvider('symptoms')) ?? 'Symptoms',
                content: predictionResult.symptoms,
                titleColor: isDarkMode
                    ? Colors.pinkAccent.shade100
                    : Colors.pinkAccent.shade700,
                contentColor: isDarkMode ? Colors.white70 : Colors.black87,
                surfaceTintColor: isDarkMode ? Colors.pink : Colors.pinkAccent,
              ),
              _buildSectionCard(
                title:
                    ref.read(currentTextProvider('prevention')) ?? 'Prevention',
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
                surfaceTintColor: isDarkMode ? Colors.green : Colors.lightGreen,
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
}
