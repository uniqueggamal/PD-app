import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart'; // Add to pubspec: url_launcher: ^6.3.0
import '../../providers/text_provider.dart'; // Your bilingual text provider

class HelpSupportScreen extends ConsumerStatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  ConsumerState<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends ConsumerState<HelpSupportScreen> {
  Map<String, String>? texts;

  @override
  Widget build(BuildContext context) {
    final textsAsync = ref.watch(textProvider);

    return textsAsync.when(
      data: (data) {
        texts = data; // Cache the texts once – better performance
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Hero Section
            Container(
              height: 300,
              width: double.infinity,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Container(
                  height: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: Colors.green.shade100,
                  ),
                  child: Column(
                    // crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Text(
                            texts?['welcomeToHelpSupport'] ?? 'Help & Support',
                            style: Theme.of(context).textTheme.headlineMedium
                                ?.copyWith(
                                  color: Colors.green.shade800,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 26,
                                ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            texts?['helpSupportDescription'] ??
                                'We\'re here to help you get the most out of PD App',
                            style: TextStyle(
                              color: Colors.green.shade600,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Getting Started Section
            _buildExpansionTile(
              icon: Icons.play_arrow,
              color: Colors.green,
              title: texts?['gettingStarted'] ?? 'Getting Started',
              children: [
                _buildHelpItem(
                  title: texts?['takingPhotos'] ?? 'Taking Good Photos',
                  description:
                      texts?['takingPhotosDescription'] ??
                      'Use natural daylight, place the leaf flat, and fill the frame.',
                ),
                _buildHelpItem(
                  title: texts?['diseaseDetection'] ?? 'Disease Detection',
                  description:
                      texts?['diseaseDetectionDescription'] ??
                      'The AI analyzes the leaf and shows disease name with confidence score.',
                ),
                _buildHelpItem(
                  title: texts?['settingReminders'] ?? 'Setting Reminders',
                  description:
                      texts?['settingRemindersDescription'] ??
                      'Add watering, fertilizing, or check-up reminders easily.',
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Troubleshooting Section
            _buildExpansionTile(
              icon: Icons.build,
              color: Colors.orange,
              title: texts?['troubleshooting'] ?? 'Troubleshooting',
              children: [
                _buildHelpItem(
                  title: texts?['poorPhotoQuality'] ?? 'Poor Photo Quality',
                  description:
                      texts?['poorPhotoQualityDescription'] ??
                      'Hold steady, use good light, and avoid shadows on the leaf.',
                ),
                _buildHelpItem(
                  title: texts?['appNotResponding'] ?? 'App Not Responding',
                  description:
                      texts?['appNotRespondingDescription'] ??
                      'Restart the app or clear cache. Works fully offline.',
                ),
                _buildHelpItem(
                  title: texts?['permissionIssues'] ?? 'Permission Issues',
                  description:
                      texts?['permissionIssuesDescription'] ??
                      'Allow camera & storage access for scanning and saving results.',
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Features Guide Section
            _buildExpansionTile(
              icon: Icons.lightbulb,
              color: Colors.blue,
              title: texts?['featuresGuide'] ?? 'Features Guide',
              children: [
                _buildHelpItem(
                  title: texts?['aiDiseaseDetection'] ?? 'AI Disease Detection',
                  description:
                      texts?['aiDiseaseDetectionDescription'] ??
                      'Detects 51+ diseases using MobileNetV2 – works offline.',
                ),
                _buildHelpItem(
                  title: texts?['plantCareReminders'] ?? 'Plant Care Reminders',
                  description:
                      texts?['plantCareRemindersDescription'] ??
                      'Set custom notifications for watering, fertilizing, etc.',
                ),
                _buildHelpItem(
                  title: texts?['treatmentDatabase'] ?? 'Treatment Database',
                  description:
                      texts?['treatmentDatabaseDescription'] ??
                      'Prevention & treatment tips in English and Nepali.',
                ),
                _buildHelpItem(
                  title:
                      texts?['multiLanguageSupport'] ??
                      'Multi-Language Support',
                  description:
                      texts?['multiLanguageSupportDescription'] ??
                      'Switch between English and नेपाली anytime.',
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Contact Support Section
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.contact_support,
                          color: Colors.green,
                          size: 32,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          texts?['contactSupport'] ?? 'Contact Support',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      texts?['needMoreHelp'] ??
                          'Need more help? Reach out to us!',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.email, color: Colors.green),
                        const SizedBox(width: 8),
                        SelectableText(
                          texts?['supportEmail'] ?? 'support@pdapp.np',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Version Footer
            Center(
              child: Text(
                '${texts?['version'] ?? 'Version'} 1.0.0',
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
            ),
            const SizedBox(height: 16),
          ],
        );
      },
      loading: () =>
          const Center(child: CircularProgressIndicator(color: Colors.green)),
      error: (error, stack) => Center(
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
    );
  }

  // Reusable ExpansionTile with Icon & Color
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
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        childrenPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
        children: children,
      ),
    );
  }

  // Reusable Help Item
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
          Text(description, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}
