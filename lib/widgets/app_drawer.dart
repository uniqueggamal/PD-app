import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/settings_provider.dart';
import '../providers/localization_provider.dart';
import '../screens/settings/about_screen.dart';

class AppDrawer extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final themeMode = ref.watch(themeModeProvider);
    final localizationAsync = ref.watch(
      localizationProvider(locale.languageCode),
    );

    return Drawer(
      child: localizationAsync.when(
        data: (localization) => ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green[700]!, Colors.green[900]!],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/img/leaf.png',
                    height: 60,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(Icons.eco, size: 60, color: Colors.white);
                    },
                  ),
                  Text(
                    'LeafMate',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      color: Colors.white,
                    ),
                  ),
                  Text('LeafMate', style: TextStyle(color: Colors.white70)),
                ],
              ),
            ),
            ListTile(
              leading: Icon(Icons.home),
              title: Text(localization['home'] ?? 'Home'),
              onTap: () {
                context.go('/');
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              leading: Icon(Icons.camera_alt),
              title: Text(localization['scanLeaf'] ?? 'Scan Leaf'),
              onTap: () {
                context.go('/camera');
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              leading: Icon(Icons.notifications),
              title: Text(localization['reminders'] ?? 'Reminders'),
              onTap: () {
                context.go('/reminders');
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              leading: Icon(Icons.history),
              title: Text(localization['scanHistory'] ?? 'Scan History'),
              onTap: () {
                context.go('/history');
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              leading: Icon(Icons.help),
              title: Text(localization['helpSupport'] ?? 'Help & Support'),
              onTap: () {
                context.go('/settings');
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              leading: Icon(Icons.info),
              title: Text(localization['about'] ?? 'About'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AboutScreen()),
                );
              },
            ),
            Divider(),
            ListTile(
              leading: Icon(Icons.language),
              title: Text(localization['language'] ?? 'Language'),
              trailing: DropdownButton<String>(
                value: locale.languageCode,
                items: [
                  DropdownMenuItem(
                    value: 'en',
                    child: Text(localization['english'] ?? 'English'),
                  ),
                  DropdownMenuItem(
                    value: 'ne',
                    child: Text(localization['nepali'] ?? 'नेपाली'),
                  ),
                ],
                onChanged: (newValue) {
                  if (newValue != null) {
                    ref.read(localeProvider.notifier).state = Locale(newValue);
                  }
                },
              ),
            ),
            ListTile(
              leading: Icon(
                themeMode == ThemeMode.dark
                    ? Icons.dark_mode
                    : Icons.light_mode,
              ),
              title: Text(localization['theme'] ?? 'Theme'),
              trailing: Switch(
                value: themeMode == ThemeMode.dark,
                onChanged: (value) {
                  ref.read(themeModeProvider.notifier).state = value
                      ? ThemeMode.dark
                      : ThemeMode.light;
                },
              ),
            ),
          ],
        ),
        loading: () => Center(child: CircularProgressIndicator()),
        error: (error, stack) =>
            Center(child: Text('Error loading localization')),
      ),
    );
  }
}
