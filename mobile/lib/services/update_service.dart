import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../core/theme.dart';

class UpdateInfo {
  final bool hasUpdate;
  final String latestVersion;
  final String releaseNotes;
  final String downloadUrl;

  UpdateInfo({
    required this.hasUpdate,
    required this.latestVersion,
    required this.releaseNotes,
    required this.downloadUrl,
  });
}

class UpdateService {
  static const String currentVersion = '1.2.0';
  static const String releasesApiUrl =
      'https://api.github.com/repos/PawanKatwe/together-stream/releases/latest';
  static const String fallbackDownloadUrl =
      'https://together-stream-server.onrender.com/download';

  static Future<UpdateInfo?> checkForUpdate() async {
    try {
      final response = await http
          .get(Uri.parse(releasesApiUrl), headers: {
            'Accept': 'application/vnd.github.v3+json',
            'User-Agent': 'TogetherStream-App',
          })
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final tagName = (data['tag_name'] as String? ?? '').replaceFirst('v', '');
        final releaseNotes = (data['body'] as String? ?? '').trim();
        final assets = data['assets'] as List<dynamic>? ?? [];

        String downloadUrl = fallbackDownloadUrl;
        for (final asset in assets) {
          final name = asset['name'] as String? ?? '';
          if (name.endsWith('.apk')) {
            downloadUrl = asset['browser_download_url'] as String? ?? fallbackDownloadUrl;
            break;
          }
        }

        if (_isNewerVersion(tagName, currentVersion)) {
          return UpdateInfo(
            hasUpdate: true,
            latestVersion: 'v$tagName',
            releaseNotes: releaseNotes.isNotEmpty ? releaseNotes : 'New enhancements & bug fixes!',
            downloadUrl: downloadUrl,
          );
        }
      }
    } catch (e) {
      debugPrint('Update check failed (safe to ignore if offline): $e');
    }
    return null;
  }

  static bool _isNewerVersion(String latest, String current) {
    try {
      final latestParts = latest.split('.').map((e) => int.tryParse(e) ?? 0).toList();
      final currentParts = current.split('.').map((e) => int.tryParse(e) ?? 0).toList();

      for (int i = 0; i < 3; i++) {
        final l = i < latestParts.length ? latestParts[i] : 0;
        final c = i < currentParts.length ? currentParts[i] : 0;
        if (l > c) return true;
        if (l < c) return false;
      }
    } catch (_) {}
    return false;
  }

  static void showUpdateDialog(BuildContext context, UpdateInfo update) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: AppTheme.primaryRose.withOpacity(0.4), width: 1.5),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryRose.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.system_update_rounded, color: AppTheme.primaryRose, size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Update Available! 🎉',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Version ${update.latestVersion} (Current: v$currentVersion)',
                          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  update.releaseNotes,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: AppTheme.textPrimary),
                ),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: const Text('Later', style: TextStyle(color: AppTheme.textSecondary)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        Navigator.of(ctx).pop();
                        final uri = Uri.parse(update.downloadUrl);
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryRose,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      icon: const Icon(Icons.download_rounded, size: 18),
                      label: const Text('Update Now ❤️', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
