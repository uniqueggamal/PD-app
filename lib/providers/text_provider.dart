import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'settings_provider.dart';

class TextProvider extends AsyncNotifier<Map<String, String>> {
  @override
  Future<Map<String, String>> build() async {
    final locale = ref.watch(localeProvider);
    return await loadTexts(locale);
  }

  Future<Map<String, String>> loadTexts(Locale locale) async {
    try {
      final languageCode = locale.languageCode;
      final fileName = 'assets/labels/app_text_${languageCode}.json';

      final jsonString = await rootBundle.loadString(fileName);
      final Map<String, dynamic> jsonMap = json.decode(jsonString);

      return jsonMap.map((key, value) => MapEntry(key, value.toString()));
    } catch (e) {
      // Fallback to English if file not found
      try {
        final jsonString = await rootBundle.loadString(
          'assets/labels/app_text_en.json',
        );
        final Map<String, dynamic> jsonMap = json.decode(jsonString);
        return jsonMap.map((key, value) => MapEntry(key, value.toString()));
      } catch (fallbackError) {
        return {};
      }
    }
  }
}

final textProvider = AsyncNotifierProvider<TextProvider, Map<String, String>>(
  () => TextProvider(),
);

final currentTextProvider = Provider.family<String, String>((ref, key) {
  final asyncTexts = ref.watch(textProvider);
  return asyncTexts.maybeWhen(
    data: (texts) => texts[key] ?? '',
    orElse: () => '',
  );
});
