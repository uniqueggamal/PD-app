import 'package:flutter_riverpod/flutter_riverpod.dart';
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
