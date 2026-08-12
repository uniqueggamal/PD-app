import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:plant_disease_detection_app/screens/home/home_screen.dart';
import 'package:plant_disease_detection_app/screens/camera/cameraScreen.dart';
import 'package:plant_disease_detection_app/screens/reminder/reminder_main_screen.dart';
import 'package:plant_disease_detection_app/screens/reminder/reminder_edit_screen.dart';
import 'package:plant_disease_detection_app/screens/reminder/reminder_view_screen.dart';
import 'package:plant_disease_detection_app/models/reminder_model.dart';
import 'package:plant_disease_detection_app/screens/settings/help_support_screen.dart';
import 'package:plant_disease_detection_app/screens/settings/about_screen.dart';
import 'package:plant_disease_detection_app/screens/onboarding/onboarding_screen.dart';
import 'package:plant_disease_detection_app/screens/history/history_screen.dart';
import 'package:plant_disease_detection_app/screens/history/scan_detail_screen.dart';
import 'package:plant_disease_detection_app/widgets/app_drawer.dart';
import 'providers/settings_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  // final isFirstLaunch = prefs.getBool('firstLaunch') ?? true; // Commented out onboarding

  // Create router
  final router = GoRouter(
    initialLocation: '/', // Always start at home, onboarding commented out
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(path: '/', builder: (context, state) => HomeScreen()),
      GoRoute(
        path: '/camera',
        builder: (context, state) => const CameraScreen(),
      ),
      GoRoute(
        path: '/reminders',
        builder: (context, state) => const ReminderScreen(),
      ),
      GoRoute(
        path: '/reminder/edit',
        builder: (context, state) => AddEditReminderScreen(
          reminder: state.extra is ReminderModel
              ? state.extra as ReminderModel
              : null,
          extraData: state.extra is Map<String, dynamic>
              ? state.extra as Map<String, dynamic>
              : null,
        ),
      ),
      GoRoute(
        path: '/reminder/view',
        builder: (context, state) {
          final reminder = state.extra as ReminderModel?;
          return ReminderViewScreen(reminder: reminder!);
        },
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => HelpSupportScreen(),
      ),
      GoRoute(path: '/about', builder: (context, state) => const AboutScreen()),
      GoRoute(
        path: '/history',
        builder: (context, state) => const HistoryScreen(),
      ),
      GoRoute(
        path: '/scan-detail/:scanId',
        builder: (context, state) {
          final scanId = state.pathParameters['scanId']!;
          return ScanDetailScreen(scanId: scanId);
        },
      ),
    ],
  );

  runApp(
    ProviderScope(
      overrides: [
        goRouterProvider.overrideWith((ref) {
          final notifier = GoRouterNotifier();
          notifier.setRouter(router);
          return notifier;
        }),
      ],
      child: MyApp(router: router),
    ),
  );
}

class MyApp extends ConsumerWidget {
  final GoRouter router;
  const MyApp({super.key, required this.router});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);

    return MaterialApp.router(
      title: 'LeafMate',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      darkTheme: ThemeData.dark().copyWith(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.green,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: themeMode,
      locale: locale,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'), // English
        Locale('ne'), // Nepali
      ],
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}

class AppShell extends ConsumerWidget {
  final Widget child;
  const AppShell({required this.child, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appBarTitle = ref.watch(currentRouteTitleProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(appBarTitle),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
      ),
      drawer: AppDrawer(),
      body: child,
    );
  }
}
