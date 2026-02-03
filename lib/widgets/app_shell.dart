import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/settings_provider.dart'; // Import the settings provider
import '../providers/text_provider.dart'; // Import the text provider

class AppShell extends ConsumerWidget {
  const AppShell({required this.child, super.key});
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the centralized title provider
    final appBarTitle = ref.watch(currentRouteTitleProvider);
    final currentPath = ref.watch(currentRouteProvider);

    // Get localized text for actions
    final editText = ref.watch(currentTextProvider('edit')) ?? 'Edit';
    final deleteText = ref.watch(currentTextProvider('delete')) ?? 'Delete';

    // Determine if we should show action buttons based on current route
    final showActions = _shouldShowActions(currentPath);

    return Scaffold(
      appBar: AppBar(
        title: Text(appBarTitle),
        // GoRouter automatically handles the back button based on navigation stack
        // No leading override needed unless custom
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: showActions
            ? [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _handleEdit(context, currentPath),
                  tooltip: editText,
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => _handleDelete(context, currentPath),
                  tooltip: deleteText,
                ),
              ]
            : null,
      ),
      body: child,
    );
  }

  bool _shouldShowActions(String path) {
    // Show actions on scan detail pages
    return path.startsWith('/scan-detail');
  }

  void _handleEdit(BuildContext context, String path) {
    // Handle edit action based on current route
    if (path.startsWith('/scan-detail')) {
      // Extract scan ID from path
      final scanId = path.split('/').last;
      // Navigate to edit screen or show edit dialog
      // For now, just show a snackbar
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Edit scan: $scanId')));
    }
  }

  void _handleDelete(BuildContext context, String path) {
    // Handle delete action based on current route
    if (path.startsWith('/scan-detail')) {
      // Extract scan ID from path
      final scanId = path.split('/').last;
      // Show confirmation dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Delete Scan'),
          content: const Text('Are you sure you want to delete this scan?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Delete the scan
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Deleted scan: $scanId')),
                );
              },
              child: const Text('Delete'),
            ),
          ],
        ),
      );
    }
  }
}
