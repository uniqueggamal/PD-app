// lib/screens/history/history_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../models/scan_history_model.dart';
import '../../services/db_service.dart';
import '../../providers/localization_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/home_provider.dart';
import '../../widgets/app_drawer.dart';

// Changed to ConsumerStatefulWidget to handle list updates (setState)
class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  // State variable to hold the scans list
  List<ScanHistoryModel> scans = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadScans();
  }

  // Helper to refresh data from DB
  Future<void> _loadScans() async {
    setState(() => isLoading = true);
    try {
      final data = await DBService.getRecentScans(limit: 30);
      if (mounted) {
        setState(() {
          scans = data;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  // Confirm Delete Dialog
  Future<bool?> _showDeleteDialog({
    String title = 'Delete Item?',
    String content = 'Are you sure you want to delete this?',
  }) async {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );
  }

  // Handle Delete Single Item
  Future<void> _handleDeleteScan(String id) async {
    final confirm = await _showDeleteDialog();
    if (confirm == true) {
      await DBService.deleteScan(id);
      // Optimistic UI update: remove from list immediately
      setState(() {
        scans.removeWhere((scan) => scan.id == id);
      });
      // Invalidate recentScansProvider to refresh home screen
      ref.invalidate(recentScansProvider);
    }
  }

  // Handle Delete All
  Future<void> _handleDeleteAll() async {
    if (scans.isEmpty) return;
    final confirm = await _showDeleteDialog(
      title: 'Clear History?',
      content: 'Are you sure you want to delete all scan history?',
    );
    if (confirm == true) {
      await DBService.deleteAllScans();
      setState(() {
        scans = [];
      });
      // Invalidate recentScansProvider to refresh home screen
      ref.invalidate(recentScansProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
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
    final accentColor = Colors.green[400]!;

    return localizationAsync.when(
      data: (texts) => Scaffold(
        appBar: AppBar(
          title: Text(texts['recentScans'] ?? 'Recent Scans'),
          backgroundColor: Colors.green[700],
          foregroundColor: Colors.white,
          actions: [
            if (scans.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.delete_sweep, color: Colors.redAccent),
                tooltip: 'Delete All',
                onPressed: _handleDeleteAll,
              ),
          ],
        ),
        drawer: AppDrawer(),
        body: Container(
          decoration: BoxDecoration(gradient: backgroundGradient),
          child: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : scans.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.history_toggle_off,
                                size: 90,
                                color: accentColor.withOpacity(0.6),
                              ),
                              const SizedBox(height: 24),
                              Text(
                                texts['noScansYet'] ?? 'No scans yet',
                                style: GoogleFonts.poppins(
                                  fontSize: 22,
                                  color: textColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                texts['startScanning'] ??
                                    'Start scanning leaves to build your history',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: subtitleColor,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 32),
                              OutlinedButton.icon(
                                icon: const Icon(Icons.camera_alt),
                                label: Text(texts['scanNow'] ?? 'Scan Now'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: accentColor,
                                  side: BorderSide(color: accentColor),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 32,
                                    vertical: 14,
                                  ),
                                ),
                                onPressed: () => context.go('/camera'),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                          itemCount: scans.length,
                          itemBuilder: (context, index) {
                            final scan = scans[index];
                            final date = DateTime.fromMillisecondsSinceEpoch(
                              scan.timestamp,
                            );
                            final dateStr = DateFormat.yMMMd(
                              locale.languageCode,
                            ).format(date);
                            final timeStr = DateFormat.Hm(
                              locale.languageCode,
                            ).format(date);

                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              color: cardColor,
                              elevation: isDark ? 2 : 4,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: () {
                                  context.go('/scan-detail/${scan.id}');
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Thumbnail or placeholder
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Container(
                                          width: 80,
                                          height: 80,
                                          color: Colors.grey[300],
                                          child: scan.imagePath.isNotEmpty
                                              ? Image.file(
                                                  File(scan.imagePath),
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (_, __, ___) =>
                                                      const Icon(
                                                        Icons
                                                            .image_not_supported,
                                                        color: Colors.grey,
                                                      ),
                                                )
                                              : const Icon(
                                                  Icons.image,
                                                  color: Colors.grey,
                                                ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),

                                      // Main content
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              scan.diseaseName,
                                              style: GoogleFonts.poppins(
                                                fontSize: 17,
                                                fontWeight: FontWeight.w600,
                                                color: isDark
                                                    ? Colors.white
                                                    : Colors.black,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.calendar_today,
                                                  size: 14,
                                                  color: isDark
                                                      ? Colors.grey[300]
                                                      : Colors.black87,
                                                ),
                                                const SizedBox(width: 6),
                                                Text(
                                                  '$dateStr • $timeStr',
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    color: isDark
                                                        ? Colors.grey[300]
                                                        : Colors.black87,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 6),
                                            Row(
                                              children: [
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 10,
                                                        vertical: 4,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: accentColor
                                                        .withOpacity(0.18),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          12,
                                                        ),
                                                  ),
                                                  child: Text(
                                                    '${(scan.confidence * 100).toStringAsFixed(0)}%',
                                                    style: TextStyle(
                                                      color: accentColor,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                if (scan.isTreated)
                                                  Icon(
                                                    Icons.check_circle,
                                                    size: 18,
                                                    color: Colors.green[600],
                                                  )
                                                else
                                                  Icon(
                                                    Icons.warning_amber_rounded,
                                                    size: 18,
                                                    color: Colors.orange[700],
                                                  ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      // ADDED: Individual Delete Button
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete_outline,
                                          color: Colors.redAccent,
                                        ),
                                        tooltip: 'Delete Scan',
                                        onPressed: () =>
                                            _handleDeleteScan(scan.id),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stk) => Center(child: Text('Localization error: $err')),
    );
  }
}
