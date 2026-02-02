import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../providers/localization_provider.dart';
import '../../providers/settings_provider.dart';

class HomeLandingScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final themeMode = ref.watch(themeModeProvider);
    final localizationAsync = ref.watch(
      localizationProvider(locale.languageCode),
    );

    final isDark = themeMode == ThemeMode.dark;
    final backgroundGradient = LinearGradient(
      begin: Alignment.topCenter,
      colors: isDark
          ? [Colors.grey[700]!, Colors.grey[900]!]
          : [Colors.green[100]!, Colors.green[200]!, Colors.green[500]!],
    );
    final textColor = isDark ? Colors.white : Colors.white70;
    final subtitleColor = isDark ? Colors.grey[300] : Colors.white70;
    final cardColor = isDark ? Colors.grey[700] : Colors.green[50];

    return localizationAsync.when(
      data: (localization) => Container(
        decoration: BoxDecoration(gradient: backgroundGradient),
        child: SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(height: 40),
              Image.asset(
                'assets/img/leafcam.png',
                height: 200,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(Icons.camera_alt, size: 200, color: Colors.green);
                },
              ),
              SizedBox(height: 20),
              Text(
                localization['detectPlantDiseasesInstantly'] ??
                    'Detect Plant Diseases Instantly',
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  // fontWeight: FontWeight.semiBold,
                  color: textColor,
                ),
                textAlign: TextAlign.center,
              ),
              Text(
                localization['aiPoweredOfflineDetection'] ??
                    'AI-powered offline detection for 51+ diseases',
                style: TextStyle(fontSize: 16, color: subtitleColor),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 30),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                  backgroundColor: isDark
                      ? Colors.green[600]
                      : Colors.green[400],
                ),
                icon: Icon(Icons.camera_alt, size: 30, color: Colors.white),
                label: Text(
                  localization['scanLeafNow'] ?? 'Scan Leaf Now',
                  style: TextStyle(fontSize: 20, color: Colors.white),
                ),
                onPressed: () => context.go('/camera'),
              ),
              SizedBox(height: 40),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  children: [
                    Card(
                      color: cardColor,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.history,
                            size: 40,
                            color: Colors.green[400],
                          ),
                          Text(
                            localization['recentScans'] ?? 'Recent Scans',
                            style: TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                    Card(
                      color: cardColor,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.lightbulb,
                            size: 40,
                            color: Colors.green[400],
                          ),
                          Text(
                            localization['plantCareTips'] ?? 'Plant Care Tips',
                            style: TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                    Card(
                      color: cardColor,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.notifications,
                            size: 40,
                            color: Colors.green[400],
                          ),
                          Text(
                            localization['reminders'] ?? 'Reminders',
                            style: TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                    Card(
                      color: cardColor,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.eco, size: 40, color: Colors.green[400]),
                          Text(
                            localization['healthyPlants'] ?? 'Healthy Plants',
                            style: TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      loading: () => Center(child: CircularProgressIndicator()),
      error: (error, stack) =>
          Center(child: Text('Error loading localization')),
    );
  }
}
