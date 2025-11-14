import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'text_provider.dart';

// 🌗 THEME MODE PROVIDER
final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((
  ref,
) {
  return ThemeModeNotifier();
});

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.light) {
    _loadThemeMode();
  }

  Future<void> _loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool('isDarkMode') ?? false;
    state = isDark ? ThemeMode.dark : ThemeMode.light;
  }

  Future<void> toggleTheme() async {
    state = state == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', state == ThemeMode.dark);
  }
}

// 🌍 LOCALE PROVIDER
final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  return LocaleNotifier();
});

class LocaleNotifier extends StateNotifier<Locale> {
  LocaleNotifier() : super(const Locale('en')) {
    _loadLocale();
  }

  Future<void> _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString('languageCode') ?? 'en';
    state = Locale(languageCode);
  }

  Future<void> setLocale(Locale locale) async {
    state = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('languageCode', locale.languageCode);
  }
}

// 🔔 NOTIFICATION PERMISSION PROVIDER
final notificationPermissionProvider =
    StateNotifierProvider<NotificationPermissionNotifier, bool>((ref) {
      return NotificationPermissionNotifier();
    });

class NotificationPermissionNotifier extends StateNotifier<bool> {
  NotificationPermissionNotifier() : super(false) {
    _checkPermissionSilently(); // now silent, no prompt
  }

  Future<void> _checkPermissionSilently() async {
    final status = await Permission.notification.status;
    state = status.isGranted;
  }

  Future<bool> requestPermissionIfNeeded() async {
    final status = await Permission.notification.status;

    if (status.isGranted) {
      state = true;
      return true;
    }

    final newStatus = await Permission.notification.request(); // only asks now
    state = newStatus.isGranted;
    return newStatus.isGranted;
  }
}

// 🪄 NOTIFICATIONS TOGGLE PROVIDER
final notificationsProvider =
    StateNotifierProvider<NotificationsNotifier, bool>((ref) {
      return NotificationsNotifier(ref);
    });

class NotificationsNotifier extends StateNotifier<bool> {
  final Ref ref;

  NotificationsNotifier(this.ref) : super(true) {
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool('notificationsEnabled') ?? true;
  }

  /// ✅ Toggles notifications, requests permission only when turning ON
  Future<void> toggleNotifications() async {
    final permissionNotifier = ref.read(
      notificationPermissionProvider.notifier,
    );

    if (!state) {
      // User is turning notifications ON
      final granted = await permissionNotifier.requestPermissionIfNeeded();
      if (!granted) {
        // Permission denied — keep notifications off
        state = false;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('notificationsEnabled', state);
        return;
      }
    }

    // Now safe to toggle
    state = !state;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notificationsEnabled', state);
  }
}
