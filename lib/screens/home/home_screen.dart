import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../providers/localization_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/home_provider.dart';
import '../../providers/text_provider.dart';
import '../../widgets/app_drawer.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool isSelectionMode = false;
  final Set<String> selectedScans = {};

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(localeProvider);
    final themeMode = ref.watch(themeModeProvider);
    final localizationAsync = ref.watch(
      localizationProvider(locale.languageCode),
    );
    final recentScansAsync = ref.watch(recentScansProvider);

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
    final selectedCardColor = isDark ? Colors.blue[700] : Colors.blue[100];

    return localizationAsync.when(
      data: (localization) => Scaffold(
        appBar: AppBar(
          title: Text(ref.watch(currentTextProvider('home')) ?? 'Home'),
          backgroundColor: Colors.green[700],
          foregroundColor: Colors.white,
        ),
        drawer: AppDrawer(),
        body: Container(
          decoration: BoxDecoration(gradient: backgroundGradient),
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 32),
            child: Column(
              children: [
                const SizedBox(height: 40),

                Image.asset(
                  'assets/img/leafcam.png',
                  height: 200,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.camera_alt,
                    size: 200,
                    color: Colors.green,
                  ),
                ),

                const SizedBox(height: 20),

                Text(
                  localization['detectPlantDiseasesInstantly'] ??
                      'Detect Plant Diseases Instantly',
                  style: GoogleFonts.poppins(fontSize: 28, color: textColor),
                  textAlign: TextAlign.center,
                ),

                Text(
                  localization['aiPoweredOfflineDetection'] ??
                      'AI-powered offline detection for 51+ diseases',
                  style: TextStyle(fontSize: 16, color: subtitleColor),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 30),

                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 20,
                    ),
                    backgroundColor: isDark
                        ? Colors.green[600]
                        : Colors.green[400],
                  ),
                  icon: const Icon(Icons.camera_alt, size: 30),
                  label: Text(
                    localization['scanLeafNow'] ?? 'Scan Leaf Now',
                    style: const TextStyle(fontSize: 20),
                  ),
                  onPressed: () => context.go('/camera'),
                ),

                const SizedBox(height: 40),

                // ===== Recent Scans =====
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ref.watch(currentTextProvider('recentScans')) ??
                            'Recent Scans',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 10),

                      recentScansAsync.when(
                        data: (scans) {
                          if (scans.isEmpty) {
                            return Center(
                              child: Text(
                                'No recent scans',
                                style: TextStyle(color: subtitleColor),
                              ),
                            );
                          }

                          return ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
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
                                color: selectedScans.contains(scan.id)
                                    ? selectedCardColor
                                    : cardColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(16),
                                  onLongPress: () {
                                    setState(() {
                                      isSelectionMode = true;
                                      selectedScans.add(scan.id);
                                    });
                                  },
                                  onTap: () {
                                    if (isSelectionMode) {
                                      setState(() {
                                        if (!selectedScans.remove(scan.id)) {
                                          selectedScans.add(scan.id);
                                        }
                                        if (selectedScans.isEmpty) {
                                          isSelectionMode = false;
                                        }
                                      });
                                    } else {
                                      context.go('/scan-detail/${scan.id}');
                                    }
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Row(
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          child: SizedBox(
                                            width: 80,
                                            height: 80,
                                            child: scan.imagePath.isNotEmpty
                                                ? Image.file(
                                                    File(scan.imagePath),
                                                    fit: BoxFit.cover,
                                                  )
                                                : const Icon(Icons.image),
                                          ),
                                        ),
                                        const SizedBox(width: 16),
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
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (_, __) => Center(
                          child: Text(
                            'Error loading scans',
                            // style: TextStyle(color: subtitleColor),
                          ),

                      
                        ),
                      ),

                      const SizedBox(height: 10),

                      TextButton(
                        onPressed: () => context.go('/history'),
                        child: Text(
                          'See More',
                          style: TextStyle(color: Colors.green[400]),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const Center(child: Text('Error loading localization')),
    );
  }
}
