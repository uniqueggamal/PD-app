import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/text_provider.dart';

class HelpSupportScreen extends ConsumerWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textsAsync = ref.watch(textProvider);

    return textsAsync.when(
      data: (_) => Scaffold(
        appBar: AppBar(
          title: Text(ref.watch(currentTextProvider('helpSupport'))),
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
        ),
        body: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Introduction
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ref.watch(currentTextProvider('welcomeToHelpSupport')),
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      ref.watch(currentTextProvider('helpSupportDescription')),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Getting Started
            Card(
              child: ExpansionTile(
                leading: const Icon(Icons.play_arrow, color: Colors.green),
                title: Text(ref.watch(currentTextProvider('gettingStarted'))),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHelpItem(
                          context,
                          ref.watch(currentTextProvider('takingPhotos')),
                          ref.watch(
                            currentTextProvider('takingPhotosDescription'),
                          ),
                        ),
                        _buildHelpItem(
                          context,
                          ref.watch(currentTextProvider('diseaseDetection')),
                          ref.watch(
                            currentTextProvider('diseaseDetectionDescription'),
                          ),
                        ),
                        _buildHelpItem(
                          context,
                          ref.watch(currentTextProvider('settingReminders')),
                          ref.watch(
                            currentTextProvider('settingRemindersDescription'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Troubleshooting
            Card(
              child: ExpansionTile(
                leading: const Icon(Icons.build, color: Colors.orange),
                title: Text(ref.watch(currentTextProvider('troubleshooting'))),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHelpItem(
                          context,
                          ref.watch(currentTextProvider('poorPhotoQuality')),
                          ref.watch(
                            currentTextProvider('poorPhotoQualityDescription'),
                          ),
                        ),
                        _buildHelpItem(
                          context,
                          ref.watch(currentTextProvider('appNotResponding')),
                          ref.watch(
                            currentTextProvider('appNotRespondingDescription'),
                          ),
                        ),
                        _buildHelpItem(
                          context,
                          ref.watch(currentTextProvider('permissionIssues')),
                          ref.watch(
                            currentTextProvider('permissionIssuesDescription'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Features Guide
            Card(
              child: ExpansionTile(
                leading: const Icon(Icons.lightbulb, color: Colors.blue),
                title: Text(ref.watch(currentTextProvider('featuresGuide'))),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHelpItem(
                          context,
                          ref.watch(currentTextProvider('aiDiseaseDetection')),
                          ref.watch(
                            currentTextProvider(
                              'aiDiseaseDetectionDescription',
                            ),
                          ),
                        ),
                        _buildHelpItem(
                          context,
                          ref.watch(currentTextProvider('plantCareReminders')),
                          ref.watch(
                            currentTextProvider(
                              'plantCareRemindersDescription',
                            ),
                          ),
                        ),
                        _buildHelpItem(
                          context,
                          ref.watch(currentTextProvider('treatmentDatabase')),
                          ref.watch(
                            currentTextProvider('treatmentDatabaseDescription'),
                          ),
                        ),
                        _buildHelpItem(
                          context,
                          ref.watch(
                            currentTextProvider('multiLanguageSupport'),
                          ),
                          ref.watch(
                            currentTextProvider(
                              'multiLanguageSupportDescription',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Contact Support
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.contact_support, color: Colors.green),
                        const SizedBox(width: 8),
                        Text(
                          ref.watch(currentTextProvider('contactSupport')),
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      ref.watch(currentTextProvider('needMoreHelp')),
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.email, size: 20),
                        const SizedBox(width: 8),
                        Text(ref.watch(currentTextProvider('supportEmail'))),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // App Version
            Center(
              child: Text(
                '${ref.watch(currentTextProvider('version'))} 1.0.0',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stack) => Scaffold(
        body: Center(child: Text('Error loading help content: $error')),
      ),
    );
  }

  Widget _buildHelpItem(
    BuildContext context,
    String title,
    String description,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.green.shade700,
            ),
          ),
          const SizedBox(height: 4),
          Text(description, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}
