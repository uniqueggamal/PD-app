import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../providers/text_provider.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.green.shade300, Colors.green.shade700],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo/Title
                Icon(Icons.eco, size: 100, color: Colors.white),
                const SizedBox(height: 24),
                Text(
                  ref.read(currentTextProvider('plantDiseaseDetector')),
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  ref.read(currentTextProvider('identifyPlantDiseases')),
                  style: TextStyle(fontSize: 16, color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),

                // Features list
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      _buildFeatureItem(
                        Icons.camera_alt,
                        ref.read(currentTextProvider('takePhotos')),
                      ),
                      _buildFeatureItem(
                        Icons.analytics,
                        ref.read(currentTextProvider('aiPoweredDetection')),
                      ),
                      _buildFeatureItem(
                        Icons.healing,
                        ref.read(currentTextProvider('getTreatment')),
                      ),
                      _buildFeatureItem(
                        Icons.notifications,
                        ref.read(currentTextProvider('setReminders')),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 48),

                // Skip Authentication Button (Temporary)
                ElevatedButton.icon(
                  onPressed: () async {
                    // Temporarily skip authentication and navigate to main screen
                    // TODO: Re-enable proper authentication later
                    Navigator.of(context).pushReplacementNamed('/home');
                  },
                  icon: const Icon(Icons.skip_next),
                  label: Text(ref.read(currentTextProvider('skipLogin'))),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black87,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(width: 12),
          Text(text, style: const TextStyle(color: Colors.white, fontSize: 14)),
        ],
      ),
    );
  }
}
