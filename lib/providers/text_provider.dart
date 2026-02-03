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
    // Always load English texts first as the base
    Map<String, String> englishTexts = {};
    try {
      final englishJsonString = await rootBundle.loadString(
        'assets/labels/app_text_en.json',
      );
      final Map<String, dynamic> englishJsonMap = json.decode(
        englishJsonString,
      );
      englishTexts = englishJsonMap.map(
        (key, value) => MapEntry(key, value.toString()),
      );
    } catch (e) {
      // If English file fails, return empty map
      return {};
    }

    // If locale is English, return English texts
    if (locale.languageCode == 'en') {
      return englishTexts;
    }

    // Load current language texts
    Map<String, String> currentTexts = {};
    try {
      final fileName = 'assets/labels/app_text_${locale.languageCode}.json';
      final jsonString = await rootBundle.loadString(fileName);
      final Map<String, dynamic> jsonMap = json.decode(jsonString);
      currentTexts = jsonMap.map(
        (key, value) => MapEntry(key, value.toString()),
      );
    } catch (e) {
      // If current language file fails, fall back to English
      return englishTexts;
    }

    // Merge: current language takes precedence, English fills missing keys
    return {...englishTexts, ...currentTexts};
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
