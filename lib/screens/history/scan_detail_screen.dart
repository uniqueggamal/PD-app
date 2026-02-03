import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../models/scan_history_model.dart';
import '../../providers/localization_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/text_provider.dart';
import '../../services/db_service.dart';
import '../../widgets/app_drawer.dart';

class ScanDetailScreen extends StatefulWidget {
  final String scanId;

  const ScanDetailScreen({super.key, required this.scanId});

  @override
  State<ScanDetailScreen> createState() => _ScanDetailScreenState();
}

class _ScanDetailScreenState extends State<ScanDetailScreen> {
  Map<String, dynamic> _cureData = {};

  @override
  void initState() {
    super.initState();
    _loadCureData();
  }

  Future<void> _loadCureData() async {
    // Load cure data after build is complete
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final ref = ProviderScope.containerOf(context);
      final locale = ref.read(localeProvider);
      final cureFile = locale.languageCode == 'ne'
          ? 'assets/labels/cure_ne.json'
          : 'assets/labels/cure_en.json';

      try {
        final jsonString = await rootBundle.loadString(cureFile);
        final decoded = json.decode(jsonString);
        if (mounted) {
          setState(() => _cureData = decoded);
        }
      } catch (e) {
        debugPrint("ERROR loading cure data: $e");
      }
    });
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String content,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: colorScheme.primary, size: 24),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              content,
              style: TextStyle(
                fontSize: 14,
                color: colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildCureDetails(String diseaseKey) {
    if (_cureData.isEmpty) {
      return [
        _buildInfoCard(
          icon: Icons.info_outline,
          title: "No information available",
          content: "Cure data not loaded.",
        ),
      ];
    }

    final cleanKey = diseaseKey
        .replaceAll('_', ' ')
        .replaceAll('-', ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    var cureInfo = _cureData[diseaseKey] ?? _cureData[cleanKey];
    if (cureInfo != null) {
      return _generateCureWidgets(cureInfo);
    }

    for (var key in _cureData.keys) {
      final clean = key
          .replaceAll('_', ' ')
          .replaceAll('-', ' ')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim()
          .toLowerCase();

      if (clean == cleanKey.toLowerCase() ||
          clean.contains(cleanKey.toLowerCase()) ||
          cleanKey.toLowerCase().contains(clean)) {
        cureInfo = _cureData[key];
        return _generateCureWidgets(cureInfo);
      }
    }

    return [
      _buildInfoCard(
        icon: Icons.info_outline,
        title: "No cure information available",
        content: "No detailed information found for this disease.",
      ),
    ];
  }

  List<Widget> _generateCureWidgets(Map<String, dynamic> cureInfo) {
    final widgets = <Widget>[];

    final fields = [
      {'key': 'Description', 'fallback': 'Description', 'icon': Icons.article},
      {'key': 'Cause', 'fallback': 'Cause', 'icon': Icons.coronavirus},
      {'key': 'Symptoms', 'fallback': 'Symptoms', 'icon': Icons.monitor_heart},
      {'key': 'Prevention', 'fallback': 'Prevention', 'icon': Icons.shield},
      {
        'key': 'Treatment',
        'fallback': 'Treatment',
        'icon': Icons.medical_services,
      },
    ];

    for (var f in fields) {
      final key = f['key'] as String;
      if (cureInfo.containsKey(key) &&
          cureInfo[key] != null &&
          cureInfo[key].toString().isNotEmpty) {
        widgets.add(
          _buildInfoCard(
            icon: f['icon'] as IconData,
            title: f['fallback'] as String,
            content: cureInfo[key].toString(),
          ),
        );
      }
    }

    if (widgets.isEmpty) {
      widgets.add(
        _buildInfoCard(
          icon: Icons.info_outline,
          title: "No cure information available",
          content: "No detailed information found for this disease.",
        ),
      );
    }

    return widgets;
  }

  Future<ScanHistoryModel?> _getScanById(String id) async {
    final scans = await DBService.getRecentScans(limit: 100);
    return scans.cast<ScanHistoryModel?>().firstWhere(
      (scan) => scan?.id == id,
      orElse: () => null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final locale = ref.watch(localeProvider);
        final themeMode = ref.watch(themeModeProvider);
        final isDark = themeMode == ThemeMode.dark;

        final backgroundGradient = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? [Colors.grey[850]!, Colors.grey[900]!, Colors.black87]
              : [Colors.green[50]!, Colors.green[100]!, Colors.green[200]!],
        );

        final textColor = isDark ? Colors.white : Colors.green[900]!;
        final subtitleColor = isDark ? Colors.grey[400] : Colors.green[700]!;
        final cardColor = isDark
            ? Colors.grey[800]!.withOpacity(0.85)
            : Colors.white.withOpacity(0.92);

        return FutureBuilder<ScanHistoryModel?>(
          future: _getScanById(widget.scanId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Scaffold(
                body: Container(
                  decoration: BoxDecoration(gradient: backgroundGradient),
                  child: const Center(child: CircularProgressIndicator()),
                ),
              );
            }

            if (snapshot.hasError || snapshot.data == null) {
              return Scaffold(
                body: Container(
                  decoration: BoxDecoration(gradient: backgroundGradient),
                  child: Center(
                    child: Text(
                      'Scan not found',
                      style: TextStyle(color: textColor),
                    ),
                  ),
                ),
              );
            }

            final scan = snapshot.data!;
            final date = DateTime.fromMillisecondsSinceEpoch(scan.timestamp);
            final dateStr = DateFormat.yMMMd(locale.languageCode).format(date);
            final timeStr = DateFormat.Hm(locale.languageCode).format(date);

            return Scaffold(
              appBar: AppBar(
                title: Text(
                  'Scan Details',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
                centerTitle: true,
                backgroundColor: Colors.green[700],
                foregroundColor: Colors.white,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => context.go('/history'),
                ),
              ),
              body: Container(
                decoration: BoxDecoration(gradient: backgroundGradient),
                child: SafeArea(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Full Image
                        Card(
                          color: cardColor,
                          elevation: isDark ? 2 : 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: scan.imagePath.isNotEmpty
                                ? Image.file(
                                    File(scan.imagePath),
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: 250,
                                    errorBuilder: (_, __, ___) => Container(
                                      height: 250,
                                      color: Colors.grey[300],
                                      child: const Icon(
                                        Icons.image_not_supported,
                                        size: 80,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  )
                                : Container(
                                    height: 250,
                                    color: Colors.grey[300],
                                    child: const Icon(
                                      Icons.image,
                                      size: 80,
                                      color: Colors.grey,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Disease Details
                        Card(
                          color: cardColor,
                          elevation: isDark ? 2 : 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  scan.diseaseName,
                                  style: GoogleFonts.poppins(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w600,
                                    color: textColor,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.green[400]!.withOpacity(0.18),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '${(scan.confidence * 100).toStringAsFixed(0)}% Confidence',
                                    style: TextStyle(
                                      color: Colors.green[400],
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Cure Details
                        ..._buildCureDetails(
                          scan.diseaseKey ?? scan.diseaseName,
                        ),
                        const SizedBox(height: 20),

                        // Action Buttons
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.add_alarm),
                                label: Text(
                                  ref.watch(
                                        currentTextProvider('addToReminders'),
                                      ) ??
                                      'Add to Reminders',
                                ),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  backgroundColor: Colors.green[400],
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed: () {
                                  // Navigate to add reminder screen with scan data
                                  final diseaseKey =
                                      scan.diseaseKey ?? scan.diseaseName;
                                  final cleanKey = diseaseKey
                                      .replaceAll('_', ' ')
                                      .replaceAll('-', ' ')
                                      .replaceAll(RegExp(r'\s+'), ' ')
                                      .trim();

                                  var cureInfo =
                                      _cureData[diseaseKey] ??
                                      _cureData[cleanKey];
                                  if (cureInfo == null) {
                                    for (var key in _cureData.keys) {
                                      final clean = key
                                          .replaceAll('_', ' ')
                                          .replaceAll('-', ' ')
                                          .replaceAll(RegExp(r'\s+'), ' ')
                                          .trim()
                                          .toLowerCase();

                                      if (clean == cleanKey.toLowerCase() ||
                                          clean.contains(
                                            cleanKey.toLowerCase(),
                                          ) ||
                                          cleanKey.toLowerCase().contains(
                                            clean,
                                          )) {
                                        cureInfo = _cureData[key];
                                        break;
                                      }
                                    }
                                  }

                                  context.go(
                                    '/reminder/edit',
                                    extra: {
                                      'scan': scan,
                                      'diseaseKey': scan.diseaseKey,
                                      'cureInfo': cureInfo,
                                    },
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
