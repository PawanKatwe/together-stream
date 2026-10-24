import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme.dart';

class DrmNoticeDialog extends StatefulWidget {
  final VoidCallback onConfirm;

  const DrmNoticeDialog({super.key, required this.onConfirm});

  static Future<void> showIfEnabled(BuildContext context, VoidCallback onConfirm) async {
    final prefs = await SharedPreferences.getInstance();
    final skipNotice = prefs.getBool('skip_drm_notice') ?? false;

    if (skipNotice) {
      onConfirm();
      return;
    }

    if (!context.mounted) return;
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => DrmNoticeDialog(onConfirm: onConfirm),
    );
  }

  @override
  State<DrmNoticeDialog> createState() => _DrmNoticeDialogState();
}

class _DrmNoticeDialogState extends State<DrmNoticeDialog> {
  bool _dontAskAgain = false;

  Future<void> _handleConfirm() async {
    if (_dontAskAgain) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('skip_drm_notice', true);
    }
    if (mounted) {
      Navigator.of(context).pop();
      widget.onConfirm();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(22.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryRose.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.screen_share,
                    color: AppTheme.primaryRose,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Text(
                    'Movie Share & Sound',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Your entire screen and device audio will be shared in HD with your partner.',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textPrimary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 14),

            // DRM Callout Box
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.withOpacity(0.3)),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, color: Colors.amber, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Streaming apps (Netflix, Prime Video, Disney+ Hotstar) use Android hardware DRM and will show a black screen.\n\nUse VLC, MX Player, personal video files, YouTube, or your laptop browser tab to watch together smoothly!',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: Color(0xFFFDE68A),
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Checkbox: Don't show again
            Row(
              children: [
                Checkbox(
                  value: _dontAskAgain,
                  activeColor: AppTheme.primaryRose,
                  onChanged: (val) {
                    setState(() => _dontAskAgain = val ?? false);
                  },
                ),
                const Text(
                  "Don't show this tip again",
                  style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _handleConfirm,
                  child: const Text('Start Sharing'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
