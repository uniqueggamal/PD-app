import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final localizationProvider = FutureProvider.family<Map<String, String>, String>(
  (ref, locale) async {
    String jsonString = await rootBundle.loadString(
      'assets/labels/app_text_${locale}.json',
    );
    Map<String, dynamic> jsonMap = json.decode(jsonString);
    return jsonMap.map((key, value) => MapEntry(key, value.toString()));
  },
);
