import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/settings_provider.dart';

class AppDrawer extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);

    return Drawer(
      child: ListView(
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
                  'PD App',
                  style: GoogleFonts.poppins(fontSize: 24, color: Colors.white),
                ),
                Text(
                  locale == 'ne'
                      ? 'बिरुवा रोग पत्ता लगाउने'
                      : 'Plant Disease Detection',
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
          ListTile(
            leading: Icon(Icons.home),
            title: Text('Home'),
            onTap: () {
              context.go('/');
              Navigator.of(context).pop();
            },
          ),
          ListTile(
            leading: Icon(Icons.camera_alt),
            title: Text('Scan Leaf'),
            onTap: () {
              context.go('/camera');
              Navigator.of(context).pop();
            },
          ),
          ListTile(
            leading: Icon(Icons.notifications),
            title: Text('Reminders'),
            onTap: () {
              context.go('/reminders');
              Navigator.of(context).pop();
            },
          ),
          ListTile(
            leading: Icon(Icons.history),
            title: Text('Scan History'),
            onTap: () {
              context.go('/history');
              Navigator.of(context).pop();
            },
          ),
          ListTile(
            leading: Icon(Icons.settings),
            title: Text('Settings'),
            onTap: () {
              context.go('/settings');
              Navigator.of(context).pop();
            },
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.language),
            title: Text('Language'),
            trailing: DropdownButton<String>(
              value: locale.languageCode,
              items: [
                DropdownMenuItem(value: 'en', child: Text('English')),
                DropdownMenuItem(value: 'ne', child: Text('नेपाली')),
              ],
              onChanged: (newValue) {
                if (newValue != null) {
                  ref.read(localeProvider.notifier).state = Locale(newValue);
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
