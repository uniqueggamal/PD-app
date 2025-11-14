import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'home_screen.dart';
import 'reminder_main_screen.dart';
import 'settings_screen.dart';
import '../providers/text_provider.dart';
import '../providers/settings_provider.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  int _selectedIndex = 0;
  late PageController _pageController;

  static final List<Widget> _screens = <Widget>[
    const HomeScreen(),
    const ReminderScreen(),
    const SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final textsAsync = ref.watch(textProvider);
    final locale = ref.watch(localeProvider);

    // Listen to locale changes and reset to home page
    ref.listen(localeProvider, (previous, next) {
      if (previous != next) {
        setState(() {
          _selectedIndex = 0;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_pageController.hasClients) {
            _pageController.jumpToPage(0);
          }
        });
      }
    });

    return textsAsync.when(
      data: (_) => Scaffold(
        body: PageView(
          controller: _pageController,
          onPageChanged: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          children: _screens,
        ),
        bottomNavigationBar: BottomNavigationBar(
          items: <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: const Icon(Icons.home),
              label: ref.read(currentTextProvider('home')),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.notifications),
              label: ref.read(currentTextProvider('reminders')),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.settings),
              label: ref.read(currentTextProvider('settings')),
            ),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: Colors.green,
          onTap: _onItemTapped,
        ),
      ),
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stack) =>
          Scaffold(body: Center(child: Text('Error loading texts: $error'))),
    );
  }
}
