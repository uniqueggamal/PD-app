import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:plant_disease_detection_app/screens/home/home_landing_screen.dart';
import 'package:plant_disease_detection_app/screens/camera/cameraScreen.dart';
import 'package:plant_disease_detection_app/screens/reminder/reminder_view_screen.dart';
import 'package:plant_disease_detection_app/screens/settings/help_support_screen.dart';
import 'package:plant_disease_detection_app/widgets/app_drawer.dart';
import 'firebase_options.dart';
import 'providers/settings_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);

    final GoRouter _router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (context, state) => AppShell()),
        GoRoute(path: '/home', builder: (context, state) => AppShell()),
        GoRoute(path: '/camera', builder: (context, state) => CameraScreen()),
        GoRoute(
          path: '/reminders',
          builder: (context, state) => Scaffold(
            appBar: AppBar(title: Text('Reminders')),
            body: Center(child: Text('Reminders List - Coming Soon')),
          ),
        ),
        GoRoute(
          path: '/settings',
          builder: (context, state) => HelpSupportScreen(),
        ),
        GoRoute(
          path: '/history',
          builder: (context, state) => Scaffold(
            appBar: AppBar(title: Text('Scan History')),
            body: Center(child: Text('Scan History - Coming Soon')),
          ),
        ),
      ],
    );

    return MaterialApp.router(
      title: 'Plant Disease Detection',
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
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text('PD App'),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.camera_alt),
            onPressed: () => context.go('/camera'),
          ),
        ],
      ),
      drawer: AppDrawer(),
      body: HomeLandingScreen(),
      floatingActionButton: FloatingActionButton.large(
        backgroundColor: Colors.green,
        onPressed: () => context.go('/camera'),
        child: Icon(Icons.camera_enhance, size: 40, color: Colors.white),
      ),
    );
  }
}
