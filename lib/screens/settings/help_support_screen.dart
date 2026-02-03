import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/text_provider.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/app_drawer.dart';

class HelpSupportScreen extends ConsumerStatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  ConsumerState<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends ConsumerState<HelpSupportScreen> {
  @override
  Widget build(BuildContext context) {
    final textsAsync = ref.watch(textProvider);
    final themeMode = ref.watch(themeModeProvider);
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

    return Scaffold(
      appBar: AppBar(
        title: Text('Help & Support'),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
      ),
      drawer: AppDrawer(),
      body: Container(
        decoration: BoxDecoration(gradient: backgroundGradient),
        child: SafeArea(
          child: textsAsync.when(
            data: (texts) {
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // ===== Hero Section =====
                  Container(
                    height: 300,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: cardColor,
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          texts['welcomeToHelpSupport'] ?? 'Help & Support',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.green[800],
                            fontWeight: FontWeight.bold,
                            fontSize: 26,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          texts['helpSupportDescription'] ??
                              'We\'re here to help you get the most out of PD App',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ===== Getting Started =====
                  _buildExpansionTile(
                    icon: Icons.play_arrow,
                    color: Colors.green,
                    title: texts['gettingStarted'] ?? 'Getting Started',
                    children: [
                      _buildHelpItem(
                        title: texts['takingPhotos'] ?? 'Taking Good Photos',
                        description:
                            texts['takingPhotosDescription'] ??
                            'Use natural daylight, place the leaf flat, and fill the frame.',
                      ),
                      _buildHelpItem(
                        title: texts['diseaseDetection'] ?? 'Disease Detection',
                        description:
                            texts['diseaseDetectionDescription'] ??
                            'The AI analyzes the leaf and shows disease name with confidence score.',
                      ),
                      _buildHelpItem(
                        title: texts['settingReminders'] ?? 'Setting Reminders',
                        description:
                            texts['settingRemindersDescription'] ??
                            'Add watering, fertilizing, or check-up reminders easily.',
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // ===== Troubleshooting =====
                  _buildExpansionTile(
                    icon: Icons.build,
                    color: Colors.orange,
                    title: texts['troubleshooting'] ?? 'Troubleshooting',
                    children: [
                      _buildHelpItem(
                        title:
                            texts['poorPhotoQuality'] ?? 'Poor Photo Quality',
                        description:
                            texts['poorPhotoQualityDescription'] ??
                            'Hold steady, use good light, and avoid shadows on the leaf.',
                      ),
                      _buildHelpItem(
                        title:
                            texts['appNotResponding'] ?? 'App Not Responding',
                        description:
                            texts['appNotRespondingDescription'] ??
                            'Restart the app or clear cache. Works fully offline.',
                      ),
                      _buildHelpItem(
                        title: texts['permissionIssues'] ?? 'Permission Issues',
                        description:
                            texts['permissionIssuesDescription'] ??
                            'Allow camera & storage access for scanning and saving results.',
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // ===== Features Guide =====
                  _buildExpansionTile(
                    icon: Icons.lightbulb,
                    color: Colors.blue,
                    title: texts['featuresGuide'] ?? 'Features Guide',
                    children: [
                      _buildHelpItem(
                        title:
                            texts['aiDiseaseDetection'] ??
                            'AI Disease Detection',
                        description:
                            texts['aiDiseaseDetectionDescription'] ??
                            'Detects 51+ diseases using MobileNetV2 – works offline.',
                      ),
                      _buildHelpItem(
                        title:
                            texts['plantCareReminders'] ??
                            'Plant Care Reminders',
                        description:
                            texts['plantCareRemindersDescription'] ??
                            'Set custom notifications for watering, fertilizing, etc.',
                      ),
                      _buildHelpItem(
                        title:
                            texts['treatmentDatabase'] ?? 'Treatment Database',
                        description:
                            texts['treatmentDatabaseDescription'] ??
                            'Prevention & treatment tips in English and Nepali.',
                      ),
                      _buildHelpItem(
                        title:
                            texts['multiLanguageSupport'] ??
                            'Multi-Language Support',
                        description:
                            texts['multiLanguageSupportDescription'] ??
                            'Switch between English and नेपाली anytime.',
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // ===== Contact Support =====
                  Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Row(
                            children: const [
                              Icon(
                                Icons.contact_support,
                                color: Colors.green,
                                size: 32,
                              ),
                              SizedBox(width: 12),
                              Text(
                                'Contact Support',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Text(
                            texts['needMoreHelp'] ??
                                'Need more help? Reach out to us!',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.email, color: Colors.green),
                              const SizedBox(width: 8),
                              SelectableText(
                                texts['supportEmail'] ?? 'support@pdapp.np',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // ===== Version =====
                  Center(
                    child: Text(
                      '${texts['version'] ?? 'Version'} 1.0.0',
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ),
                ],
              );
            },
            loading: () => const Center(
              child: CircularProgressIndicator(color: Colors.green),
            ),
            error: (error, _) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading help content:\n$error',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ===== Reusable Widgets =====

  Widget _buildExpansionTile({
    required IconData icon,
    required Color color,
    required String title,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 3,
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.15),
          child: Icon(icon, color: color),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: children,
      ),
    );
  }

  Widget _buildHelpItem({required String title, required String description}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.green.shade700,
            ),
          ),
          const SizedBox(height: 6),
          Text(description),
        ],
      ),
    );
  }
}
