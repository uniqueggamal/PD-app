// Stub implementation for web platform where TFLite is not supported
import 'package:image/image.dart' as img;
import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';

// ---------------------- Data Model ----------------------
class PredictionResult {
  final String diseaseName;
  final double confidence;
  final String cause;
  final String symptoms;
  final String prevention;
  final String treatment;
  final String description;

  const PredictionResult({
    required this.diseaseName,
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

// ------------------- AI Model Class (Web Stub) -------------------
class AiModel {
  late List<String> _labels;
  late Map<String, dynamic> _cureData;

  /// Public getter to access cure data outside this class
  Map<String, dynamic> get cureData => _cureData;

  // ------------------- Load model (stub for web) -------------------
  Future<void> loadModel({String lang = 'en'}) async {
    // Load class labels from JSON
    final rawLabelsJson = await rootBundle.loadString(
      "assets/labels/labels.json",
    );
    final labelsJson = json.decode(rawLabelsJson);
    _labels = List<String>.from(
      lang == 'en' ? labelsJson['en'] : labelsJson['ne'],
    );

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
      print("⚠️ Cure data not found or invalid. Skipping...");
    }

    print("Labels and cure data loaded successfully (web stub)");
  }

  // ------------------- Run prediction (stub for web) -------------------
  Future<PredictionResult?> predict(img.Image image) async {
    // Return null to indicate prediction is not available on web
    return null;
  }
}
