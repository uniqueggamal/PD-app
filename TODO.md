# TODO: Fix Back Button Issue with ShellRoute

## Steps to Complete
- [x] Update lib/main.dart: Wrap routes in ShellRoute with AppShell as shell, nest GoRoutes for '/', '/camera', '/reminders', '/history', '/settings'
- [x] Modify AppShell in lib/main.dart to accept required Widget child and set body: child
- [ ] Create lib/screens/reminder/reminder_list_screen.dart for '/reminders' without Scaffold
- [ ] Create lib/screens/history/history_screen.dart for '/history' without Scaffold
- [x] Update lib/screens/camera/cameraScreen.dart: Remove Scaffold and AppBar, return body content
- [x] Update lib/screens/settings/help_support_screen.dart: Remove Scaffold and AppBar, return body content
- [x] Test navigation: Run flutter run and verify back button pops to home instead of closing app
