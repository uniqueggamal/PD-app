import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/text_provider.dart';
import '../../providers/settings_provider.dart';

class AboutScreen extends ConsumerStatefulWidget {
  const AboutScreen({super.key});

  @override
  ConsumerState<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends ConsumerState<AboutScreen> {
  List<String> detectableClasses = [];
  bool classesLoaded = false;

  Future<void> _loadDetectableClasses(Map<String, String> texts) async {
    if (classesLoaded) return;
    final locale = ref.read(localeProvider);
    final languageCode = locale.languageCode;
    final fileName = 'assets/labels/class_labels_${languageCode}.txt';

    try {
      final content = await rootBundle.loadString(fileName);
      setState(() {
        detectableClasses = content
            .split('\n')
            .where((line) => line.isNotEmpty)
            .toList();
      });
    } catch (e) {
      // Fallback to English if file not found
      try {
        final content = await rootBundle.loadString(
          'assets/labels/class_labels_en.txt',
        );
        setState(() {
          detectableClasses = content
              .split('\n')
              .where((line) => line.isNotEmpty)
              .toList();
        });
      } catch (fallbackError) {
        setState(() {
          detectableClasses = [
            texts['errorLoadingClasses'] ?? 'Error loading classes',
          ];
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textsAsync = ref.watch(textProvider);

    return textsAsync.when(
      data: (texts) {
        // Load detectable classes if not already loaded
        if (!classesLoaded) {
          _loadDetectableClasses(texts);
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(texts['about'] ?? 'About'),
            backgroundColor: Colors.green[700],
            foregroundColor: Colors.white,
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // App Introduction Section
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.info_outline,
                            color: Colors.green,
                            size: 32,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            texts['aboutApp'] ?? 'About App',
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green[800],
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        texts['aboutIntroduction'] ?? 'App introduction',
                        style: Theme.of(context).textTheme.bodyLarge,
                        textAlign: TextAlign.justify,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Detectable Classes Section
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.list_alt,
                            color: Colors.green,
                            size: 32,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            texts['detectableClasses'] ?? 'Detectable Classes',
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green[800],
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        texts['detectableClassesDescription'] ??
                            'The app can detect the following plant diseases and conditions:',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (detectableClasses.isEmpty)
                        const Center(child: CircularProgressIndicator())
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: detectableClasses.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.check_circle,
                                    color: Colors.green,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      detectableClasses[index],
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodyMedium,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Version Footer
              Center(
                child: Text(
                  '${texts['version'] ?? 'Version'} 1.0.0',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
              ),
            ],
          ),
        );
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stack) => Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Error loading about content:\n$error',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
