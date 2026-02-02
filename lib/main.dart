import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:plant_disease_detection_app/screens/home/home_landing_screen.dart';
import 'package:plant_disease_detection_app/screens/camera/cameraScreen.dart';
import 'package:plant_disease_detection_app/screens/reminder/reminder_main_screen.dart';
import 'package:plant_disease_detection_app/screens/settings/help_support_screen.dart';
import 'package:plant_disease_detection_app/screens/onboarding/onboarding_screen.dart';
import 'package:plant_disease_detection_app/widgets/app_drawer.dart';
import 'providers/settings_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  final isFirstLaunch = prefs.getBool('firstLaunch') ?? true;

  runApp(ProviderScope(child: MyApp(isFirstLaunch: isFirstLaunch)));
}

class MyApp extends ConsumerStatefulWidget {
  final bool isFirstLaunch;
  const MyApp({super.key, required this.isFirstLaunch});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = GoRouter(
      initialLocation: widget.isFirstLaunch ? '/onboarding' : '/',
      routes: [
        GoRoute(
          path: '/onboarding',
          builder: (context, state) => const OnboardingScreen(),
        ),
        ShellRoute(
          builder: (context, state, child) => AppShell(child: child),
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => HomeLandingScreen(),
            ),
            GoRoute(
              path: '/camera',
              builder: (context, state) => const CameraScreen(),
            ),
            GoRoute(
              path: '/reminders',
              builder: (context, state) => const ReminderScreen(),
            ),
            GoRoute(
              path: '/settings',
              builder: (context, state) => HelpSupportScreen(),
            ),
            GoRoute(
              path: '/history',
              builder: (context, state) =>
                  const Center(child: Text('Scan History - Coming Soon')),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
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
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
    );
  }
}

class AppShell extends ConsumerWidget {
  final Widget child;
  const AppShell({required this.child, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text('LeafMate'),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
      ),
      drawer: AppDrawer(),
      body: child,
      floatingActionButton: FloatingActionButton.large(
        backgroundColor: Colors.green,
        onPressed: () => context.go('/camera'),
        child: Icon(Icons.camera_enhance, size: 40, color: Colors.white),
      ),
    );
  }
}
