import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/ai_model.dart';

// Provider for prediction result
final predictionResultProvider = StateProvider<PredictionResult?>(
  (ref) => null,
);

// Provider for selected image path
final selectedImagePathProvider = StateProvider<String?>((ref) => null);

// Provider for status message
final statusMessageProvider = StateProvider<String>((ref) => "");

// Provider for picking image state
final isPickingImageProvider = StateProvider<bool>((ref) => false);
