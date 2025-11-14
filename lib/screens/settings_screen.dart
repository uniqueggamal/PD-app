import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/auth_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/text_provider.dart';
import 'help_support_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textsAsync = ref.watch(textProvider);

    return textsAsync.when(
      data: (_) {
        final authState = ref.watch(authProvider);
        final authService = ref.read(authServiceProvider);

        return authState.when(
          data: (user) => _buildSettingsScreen(context, ref, user, authService),
          loading: () =>
              const Scaffold(body: Center(child: CircularProgressIndicator())),
          error: (error, stack) =>
              Scaffold(body: Center(child: Text('Error: $error'))),
        );
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stack) =>
          Scaffold(body: Center(child: Text('Error loading texts: $error'))),
    );
  }

  Widget _buildSettingsScreen(
    BuildContext context,
    WidgetRef ref,
    User? user,
    AuthService authService,
  ) {
    final themeMode = ref.watch(themeModeProvider);
    final isDarkMode = themeMode == ThemeMode.dark;
    final notificationsEnabled = ref.watch(notificationsProvider);
    final notificationPermissionGranted = ref.watch(
      notificationPermissionProvider,
    );
    final currentLocale = ref.watch(localeProvider);

    // Watch all texts to avoid ref.read in callbacks
    final permissionRequiredText = ref.watch(
      currentTextProvider('permissionRequired'),
    );
    final notificationPermissionRequiredText = ref.watch(
      currentTextProvider('notificationPermissionRequired'),
    );
    final cancelText = ref.watch(currentTextProvider('cancel'));
    final openSettingsText = ref.watch(currentTextProvider('openSettings'));
    final disableNotificationsText = ref.watch(
      currentTextProvider('disableNotifications'),
    );
    final enableNotificationsText = ref.watch(
      currentTextProvider('enableNotifications'),
    );
    final disableNotificationsConfirmText = ref.watch(
      currentTextProvider('disableNotificationsConfirm'),
    );
    final enableNotificationsConfirmText = ref.watch(
      currentTextProvider('enableNotificationsConfirm'),
    );
    final disableText = ref.watch(currentTextProvider('disable'));
    final enableText = ref.watch(currentTextProvider('enable'));

    return Scaffold(
      appBar: AppBar(
        title: Text(ref.watch(currentTextProvider('settings'))),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      backgroundColor: isDarkMode ? Colors.grey.shade900 : Colors.white,
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // User Profile Section
          if (user != null) ...[
            Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.green,
                  child: Text(
                    user.displayName?.isNotEmpty == true
                        ? user.displayName![0].toUpperCase()
                        : 'U',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                title: Text(user.displayName ?? 'User'),
                subtitle: Text(user.email ?? ''),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  // Navigate to profile details
                  _showProfileDialog(context, user, ref);
                },
              ),
            ),
            const SizedBox(height: 16),
          ],

          // App Settings
          Card(
            child: ExpansionTile(
              leading: const Icon(Icons.settings),
              title: Text(ref.watch(currentTextProvider('appSettings'))),
              children: [
                ListTile(
                  leading: const Icon(Icons.language),
                  title: Text(ref.watch(currentTextProvider('language'))),
                  subtitle: Text(
                    currentLocale.languageCode == 'en'
                        ? ref.watch(currentTextProvider('english'))
                        : ref.watch(currentTextProvider('nepali')),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () => _showLanguageDialog(context, ref),
                ),
                ListTile(
                  leading: const Icon(Icons.dark_mode),
                  title: Text(ref.watch(currentTextProvider('darkMode'))),
                  trailing: Switch(
                    value: isDarkMode,
                    onChanged: (value) {
                      ref.read(themeModeProvider.notifier).toggleTheme();
                    },
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.notifications),
                  title: Text(ref.watch(currentTextProvider('notifications'))),
                  subtitle: notificationPermissionGranted
                      ? Text(
                          '${ref.watch(currentTextProvider('permissionGranted'))} - ${notificationsEnabled ? ref.watch(currentTextProvider('enabled')) : ref.watch(currentTextProvider('disabled'))}',
                        )
                      : Text(
                          ref.watch(
                            currentTextProvider('permissionRequiredText'),
                          ),
                        ),
                  trailing: Switch(
                    value: notificationPermissionGranted,
                    onChanged: (value) async {
                      try {
                        if (!notificationPermissionGranted) {
                          // Request permission first
                          final granted = await ref
                              .read(notificationPermissionProvider.notifier)
                              .requestPermissionIfNeeded();

                          if (!granted) {
                            // Show dialog to guide user to settings
                            if (context.mounted) {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: Text(permissionRequiredText),
                                  content: Text(
                                    notificationPermissionRequiredText,
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: Text(cancelText),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.pop(context);
                                        // Open app settings
                                        // Note: This would require additional package like app_settings
                                      },
                                      child: Text(openSettingsText),
                                    ),
                                  ],
                                ),
                              );
                            }
                            return;
                          }
                        } else {
                          // Permission is granted, show confirmation dialog before toggling
                          final shouldToggle = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text(
                                notificationsEnabled
                                    ? disableNotificationsText
                                    : enableNotificationsText,
                              ),
                              content: Text(
                                notificationsEnabled
                                    ? disableNotificationsConfirmText
                                    : enableNotificationsConfirmText,
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: Text(cancelText),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: Text(
                                    notificationsEnabled
                                        ? disableText
                                        : enableText,
                                  ),
                                ),
                              ],
                            ),
                          );

                          if (shouldToggle == true) {
                            // Defer the toggle to avoid using ref after dispose
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              ref
                                  .read(notificationsProvider.notifier)
                                  .toggleNotifications();
                            });
                          }
                        }
                      } catch (e, stack) {
                        debugPrint('Notification toggle error: $e');
                        // Ignore if it's from disposed widget
                        if (e.toString().contains('disposed')) return;
                        // Otherwise, handle gracefully
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Something went wrong while updating notifications',
                              ),
                            ),
                          );
                        }
                      }
                    },
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Account Section
          Card(
            child: Column(
              children: [
                /*
                ListTile(
                  leading: const Icon(Icons.privacy_tip),
                  title: Text(ref.watch(currentTextProvider('privacyPolicy'))),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    // Navigate to privacy policy
                    _showInfoDialog(
                      context,
                      ref.watch(currentTextProvider('privacyPolicy')),
                      ref,
                    );
                  },
                ),
                */
                ListTile(
                  leading: const Icon(Icons.help_outline),
                  title: Text(ref.watch(currentTextProvider('helpSupport'))),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    // Navigate to help
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const HelpSupportScreen(),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: Text(ref.watch(currentTextProvider('aboutApp'))),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    _showAboutDialog(context, ref);
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Logout Button
          if (user != null)
            Card(
              color: Colors.red.shade50,
              child: ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: Text(
                  ref.watch(currentTextProvider('signOut')),
                  style: const TextStyle(color: Colors.red),
                ),
                onTap: () async {
                  await _showLogoutDialog(context, ref);
                },
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
    );
  }

  void _showLanguageDialog(BuildContext context, WidgetRef ref) {
    // ✅ Read before showDialog
    final selectLanguageText = ref.read(currentTextProvider('selectLanguage'));
    final englishText = ref.read(currentTextProvider('english'));
    final nepaliText = ref.read(currentTextProvider('nepali'));

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(selectLanguageText),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(englishText),
              leading: const Icon(Icons.language),
              onTap: () {
                ref.read(localeProvider.notifier).setLocale(const Locale('en'));
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: Text(nepaliText),
              leading: const Icon(Icons.language),
              onTap: () {
                ref.read(localeProvider.notifier).setLocale(const Locale('ne'));
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showProfileDialog(BuildContext context, User user, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(ref.watch(currentTextProvider('profile'))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${ref.watch(currentTextProvider('name'))}: ${user.displayName ?? 'N/A'}',
            ),
            Text(
              '${ref.watch(currentTextProvider('email'))}: ${user.email ?? 'N/A'}',
            ),
            if (user.photoURL != null) ...[
              const SizedBox(height: 8),
              Text(
                '${ref.watch(currentTextProvider('photoUrl'))}: ${user.photoURL}',
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(ref.watch(currentTextProvider('close'))),
          ),
        ],
      ),
    );
  }

  void _showInfoDialog(BuildContext context, String title, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(ref.watch(currentTextProvider('comingSoon'))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(ref.watch(currentTextProvider('ok'))),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(ref.watch(currentTextProvider('aboutApp'))),
        content: Text(ref.watch(currentTextProvider('aiPowered'))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(ref.watch(currentTextProvider('ok'))),
          ),
        ],
      ),
    );
  }

  Future<void> _showLogoutDialog(BuildContext context, WidgetRef ref) async {
    // Read texts before await to avoid dispose error
    final signOutText = ref.read(currentTextProvider('signOut'));
    final signOutConfirmText = ref.read(currentTextProvider('signOutConfirm'));
    final cancelText = ref.read(currentTextProvider('cancel'));
    final signedOutText = ref.read(currentTextProvider('signedOut'));
    final authService = ref.read(authServiceProvider);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(signOutText),
        content: Text(signOutConfirmText),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(cancelText),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(signOutText),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await authService.signOut();
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(signedOutText)));
      }
    }
  }
}
