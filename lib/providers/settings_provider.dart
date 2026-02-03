import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:go_router/go_router.dart';
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

// 📱 APP BAR TITLE PROVIDER
final appBarTitleProvider = StateNotifierProvider<AppBarTitleNotifier, String>((
  ref,
) {
  return AppBarTitleNotifier(ref);
});

class AppBarTitleNotifier extends StateNotifier<String> {
  final Ref ref;

  AppBarTitleNotifier(this.ref) : super('LeafMate') {
    // Default to app title
  }

  void setTitle(String key) {
    final text = ref.read(currentTextProvider(key)) ?? key;
    state = text;
  }

  void resetToDefault() {
    state = 'LeafMate';
  }
}

// 🧭 GO ROUTER PROVIDER
final goRouterProvider = StateNotifierProvider<GoRouterNotifier, GoRouter>((
  ref,
) {
  return GoRouterNotifier();
});

class GoRouterNotifier extends StateNotifier<GoRouter> {
  GoRouterNotifier() : super(GoRouter(routes: [])); // dummy router

  void setRouter(GoRouter router) {
    state = router;
  }
}

// 🛣️ CURRENT ROUTE PROVIDER
final currentRouteProvider =
    StateNotifierProvider<CurrentRouteNotifier, String>((ref) {
      return CurrentRouteNotifier(ref);
    });

class CurrentRouteNotifier extends StateNotifier<String> {
  final Ref ref;
  GoRouter? _router;

  CurrentRouteNotifier(this.ref) : super('/') {
    // Listen to router changes
    ref.listen<GoRouter>(goRouterProvider, (previous, next) {
      _setRouter(next);
    });
  }

  void _setRouter(GoRouter router) {
    // Remove listener from old router
    if (_router != null) {
      _router!.routerDelegate.removeListener(_onRouteChanged);
    }
    _router = router;
    _router!.routerDelegate.addListener(_onRouteChanged);
    _onRouteChanged(); // initial
  }

  void _onRouteChanged() {
    if (_router != null) {
      final location = _router!.routerDelegate.currentConfiguration.uri
          .toString();
      state = location;
    }
  }

  @override
  void dispose() {
    if (_router != null) {
      _router!.routerDelegate.removeListener(_onRouteChanged);
    }
    super.dispose();
  }
}

// --- 1. Mapping Logic (Route Path -> JSON Key) ---

String _getTitleKeyFromPath(String path) {
  // Handle dynamic routes first (e.g., /scan-detail/abc123)
  if (path.startsWith('/scan-detail')) return 'scanDetail';

  switch (path) {
    case '/':
      return 'home';
    case '/camera':
      return 'camera';
    case '/history':
      return 'scanHistory';
    case '/reminders':
      return 'reminders';
    case '/settings':
      return 'helpSupport';
    case '/about':
      return 'about';
    default:
      return 'appTitle'; // Fallback for unknown routes
  }
}

// 📋 CURRENT ROUTE TITLE PROVIDER
final currentRouteTitleProvider = Provider<String>((ref) {
  // A. Watch the current route
  final currentPath = ref.watch(currentRouteProvider);

  final titleKey = _getTitleKeyFromPath(currentPath);

  // B. Watch the text provider to rebuild when language changes
  final textAsync = ref.watch(textProvider);

  // C. Return the localized string
  return textAsync.when(
    data: (texts) {
      // Return specific key, or fallback to 'appTitle', or generic string
      return texts[titleKey] ?? texts['appTitle'] ?? 'LeafMate';
    },
    loading: () => '...', // Show loading dots while JSON loads
    error: (err, stack) => 'LeafMate', // Fallback on error
  );
});
