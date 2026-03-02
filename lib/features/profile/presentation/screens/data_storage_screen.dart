import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:wandermood/l10n/app_localizations.dart';
import '../providers/settings_providers.dart';
import '../widgets/settings_screen_template.dart';

class DataStorageScreen extends ConsumerStatefulWidget {
  const DataStorageScreen({super.key});

  @override
  ConsumerState<DataStorageScreen> createState() => _DataStorageScreenState();
}

class _DataStorageScreenState extends ConsumerState<DataStorageScreen> {
  bool _isExporting = false;
  bool _isClearing = false;
  String _storageSize = '24.5 MB';

  @override
  void initState() {
    super.initState();
    _calculateStorageSize();
  }

  Future<void> _calculateStorageSize() async {
    try {
      double totalSize = 0;
      final cacheDir = await getTemporaryDirectory();
      if (cacheDir.existsSync()) {
        totalSize += await _getDirectorySize(cacheDir);
      }
      final appDocDir = await getApplicationDocumentsDirectory();
      if (appDocDir.existsSync()) {
        totalSize += await _getDirectorySize(appDocDir);
      }
      setState(() {
        if (totalSize < 1024) {
          _storageSize = '${totalSize.toStringAsFixed(1)} B';
        } else if (totalSize < 1024 * 1024) {
          _storageSize = '${(totalSize / 1024).toStringAsFixed(1)} KB';
        } else {
          _storageSize = '${(totalSize / (1024 * 1024)).toStringAsFixed(1)} MB';
        }
      });
    } catch (e) {
      setState(() => _storageSize = '24.5 MB');
    }
  }

  Future<double> _getDirectorySize(Directory dir) async {
    double size = 0;
    try {
      if (dir.existsSync()) {
        await for (final entity in dir.list(recursive: true)) {
          if (entity is File) {
            size += await entity.length();
          }
        }
      }
    } catch (e) {
      // Ignore
    }
    return size;
  }

  Future<void> _exportData() async {
    setState(() => _isExporting = true);
    final l10n = AppLocalizations.of(context)!;
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user == null) return;

      final Map<String, dynamic> exportData = {
        'export_date': DateTime.now().toIso8601String(),
        'user_id': user.id,
        'email': user.email,
      };

      final jsonString = const JsonEncoder.withIndent('  ').convert(exportData);
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/wandermood_data_export.json');
      await file.writeAsString(jsonString);
      await Share.shareXFiles([XFile(file.path)], text: l10n.dataStorageExportFileTitle);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.dataStorageExportSuccess),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.dataStorageExportFailed(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  Future<void> _clearCache() async {
    setState(() => _isClearing = true);
    try {
      final cacheDir = await getTemporaryDirectory();
      if (cacheDir.existsSync()) {
        await cacheDir.delete(recursive: true);
      }
      await _calculateStorageSize();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.dataStorageCacheCleared),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.dataStorageCacheFailed(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isClearing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SettingsScreenTemplate(
      title: l10n.dataStorageTitle,
      onBack: () => context.pop(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFECFDFF),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFFCFFAFE),
                width: 2,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.dataStorageStorageUsedLabel,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF374151),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _storageSize,
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1F2937),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.download,
                  size: 40,
                  color: Color(0xFF06B6D4),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildSettingCard(
            icon: Icons.download,
            title: l10n.dataStorageExportTitle,
            subtitle: l10n.dataStorageExportSubtitle,
            onTap: _isExporting ? null : _exportData,
          ),
          const SizedBox(height: 16),
          _buildSettingCard(
            icon: Icons.delete_outline,
            title: l10n.dataStorageClearCacheTitle,
            subtitle: l10n.dataStorageClearCacheSubtitle,
            onTap: _isClearing ? null : _clearCache,
          ),
        ],
      ),
    );
  }

  Widget _buildSettingCard({
    required IconData icon,
    required String title,
    required String subtitle,
    String? badge,
    VoidCallback? onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFF3F4F6),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 1),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(icon, color: const Color(0xFF374151), size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: const Color(0xFF1F2937),
                              ),
                            ),
                          ),
                          if (badge != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFD1FAE5),
                                borderRadius: BorderRadius.circular(9999),
                              ),
                              child: Text(
                                badge,
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF16A34A),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.chevron_right,
                  color: Color(0xFF9CA3AF),
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
