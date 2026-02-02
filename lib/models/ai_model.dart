import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';
import 'package:tflite_flutter/tflite_flutter.dart'
    if (dart.library.html) 'package:flutter/foundation.dart';

// ---------------------- Data Model ----------------------
class PredictionResult {
  final String diseaseName;
  final String diseaseKey;
  final double confidence;
  final String cause;
  final String symptoms;
  final String prevention;
  final String treatment;
  final String description;

  const PredictionResult({
    required this.diseaseName,
    required this.diseaseKey,
    required this.confidence,
    required this.cause,
    required this.symptoms,
    required this.prevention,
    required this.treatment,
    required this.description,
  });

  @override
  String toString() =>
      '$diseaseName (${(confidence * 100).toStringAsFixed(2)}%)';
}

// ---------------------- AI Model Class ----------------------
class AiModel {
  Interpreter? _interpreter; // Changed to nullable
  List<String> _labels = [];
  List<String> _labelsEn = [];
  List<String> _labelsNe = [];
  Map<String, dynamic> _cureData = {};
  String? _currentLang; // Track loaded language to prevent reloading

  /// Public getter to access cure data outside this class
  Map<String, dynamic> get cureData => _cureData;

  /// Load model, labels, and cure info
  Future<void> loadModel({String lang = 'en'}) async {
    // FIX 1: Do not reload if model is already loaded for this language
    if (_interpreter != null && _currentLang == lang) {
      print("Model already loaded for $lang. Skipping...");
      return;
    }

    if (!kIsWeb) {
      try {
        _interpreter = await Interpreter.fromAsset(
          "assets/ai/models/mobilenetv2_51classes_quant.tflite",
        );
      } catch (e) {
        print("Error loading TFLite model: $e");
        rethrow;
      }
    }

    // Load class labels from JSON
    final rawLabelsJson = await rootBundle.loadString(
      "assets/labels/labels.json",
    );
    final labelsJson = json.decode(rawLabelsJson);
    _labelsEn = List<String>.from(labelsJson['en']);
    _labelsNe = List<String>.from(labelsJson['ne']);
    _labels = lang == 'en' ? _labelsEn : _labelsNe;

    // Load cure info JSON
    try {
      final rawCureData = await rootBundle.loadString(
        lang == 'en'
            ? "assets/labels/cure_en.json"
            : "assets/labels/cure_ne.json",
      );
      _cureData = json.decode(rawCureData);
    } catch (e) {
      _cureData = {};
      print("Cure data not found or invalid. Skipping...");
    }

    _currentLang = lang; // Remember which language we loaded
    print("Model and labels loaded successfully for $lang");
  }

  /// Run prediction
  Future<PredictionResult?> predict(img.Image image) async {
    if (kIsWeb) return null;
    if (_interpreter == null) {
      print("Interpreter not initialized. Call loadModel first.");
      return null;
    }

    // FIX 2: RESIZE FIRST.
    // Don't process a 12-megapixel image. Resize to 224x224 immediately.
    final resized = img.copyResize(image, width: 224, height: 224);

    // Now normalize the small image (much faster)
    final normalized = _normalizeLighting(resized);

    final input = List.generate(
      1,
      (_) => List.generate(
        224,
        (y) => List.generate(224, (x) {
          final pixel = normalized.getPixel(x, y);
          return [
            (pixel.r / 127.5) - 1.0,
            (pixel.g / 127.5) - 1.0,
            (pixel.b / 127.5) - 1.0,
          ];
        }),
      ),
    );

    var output = List.filled(_labels.length, 0.0).reshape([1, _labels.length]);

    // Run inference
    _interpreter!.run(input, output);

    double maxProb = output[0][0];
    int maxIndex = 0;
    for (int i = 1; i < _labels.length; i++) {
      if (output[0][i] > maxProb) {
        maxProb = output[0][i];
        maxIndex = i;
      }
    }

    const double threshold = 0.3;
    if (maxProb < threshold) return null;

    final diseaseName = _labels[maxIndex];
    final cureInfo =
        _cureData[_labelsEn[maxIndex]] ??
        {
          'Cause': 'Information not available',
          'Symptoms': 'Information not available',
          'Prevention': 'Information not available',
          'Treatment': 'Information not available',
          'Description': 'Description not available',
        };

    print(diseaseName);
    return PredictionResult(
      diseaseName: diseaseName,
      diseaseKey: _labelsEn[maxIndex],
      confidence: maxProb,
      cause: cureInfo['Cause'] ?? 'Information not available',
      symptoms: cureInfo['Symptoms'] ?? 'Information not available',
      prevention: cureInfo['Prevention'] ?? 'Information not available',
      treatment: cureInfo['Treatment'] ?? 'Information not available',
      description: cureInfo['Description'] ?? 'Description not available',
    );
  }

  /// Adjust image brightness for better predictions
  img.Image _normalizeLighting(img.Image image) {
    double sum = 0;
    // This loop is now only 224x224, very fast!
    for (final pixel in image) {
      sum += pixel.r + pixel.g + pixel.b;
    }
    final avgBrightness = sum / (image.length * 3.0) / 255.0;
    final gamma = avgBrightness < 0.5 ? 1.2 : 0.8;
    return img.adjustColor(image, gamma: gamma);
  }

  /// Close the interpreter to free resources
  void closeInterpreter() {
    _interpreter?.close();
    _interpreter = null;
  }
}
