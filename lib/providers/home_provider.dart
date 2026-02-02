import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:tflite_flutter/tflite_flutter.dart'
    if (dart.library.html) 'package:flutter/foundation.dart';
import '../models/ai_model.dart';
import '../providers/settings_provider.dart';

// Provider for prediction result
final predictionResultProvider = StateProvider<PredictionResult?>(
  (ref) => null,
);

// Provider for original image path
final originalImagePathProvider = StateProvider<String?>((ref) => null);

// Provider for status message
final statusMessageProvider = StateProvider<String>((ref) => "");

// Provider for picking image state
final isPickingImageProvider = StateProvider<bool>((ref) => false);

// Provider for processed image path
final processedImagePathProvider = StateProvider<String?>((ref) => null);

// Provider for current language code
final currentLanguageCodeProvider = Provider<String>((ref) {
  final locale = ref.watch(localeProvider);
  return locale.languageCode;
});

// FutureProvider for TFLite interpreter (lazy loading)
final interpreterProvider = FutureProvider<Interpreter?>((ref) async {
  if (kIsWeb) return null;
  try {
    return await Interpreter.fromAsset(
      "assets/ai/models/mobilenetv2_51classes_quant.tflite",
    );
  } catch (e) {
    debugPrint("Error loading TFLite interpreter: $e");
    return null;
  }
});
