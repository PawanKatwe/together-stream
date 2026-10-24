import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/theme.dart';

class OverlayService {
  static const MethodChannel _channel = MethodChannel('com.togetherstream.app/overlay');

  static Future<bool> isPermissionGranted() async {
    try {
      final bool granted = await _channel.invokeMethod('checkOverlayPermission');
      return granted;
    } catch (e) {
      debugPrint('Error checking overlay permission: $e');
      return false;
    }
  }

  static Future<void> requestPermission() async {
    try {
      await _channel.invokeMethod('requestOverlayPermission');
    } catch (e) {
      debugPrint('Error requesting overlay permission: $e');
    }
  }

  static Future<void> showFloatingBubble(String partnerName) async {
    try {
      await _channel.invokeMethod('showOverlay', {'partnerName': partnerName});
    } catch (e) {
      debugPrint('Error showing floating overlay: $e');
    }
  }

  static Future<void> hideFloatingBubble() async {
    try {
      await _channel.invokeMethod('hideOverlay');
    } catch (e) {
      debugPrint('Error hiding floating overlay: $e');
    }
  }

  // Helpful permission guidance dialog for Realme / ColorOS users
  static Future<bool> promptOverlayPermission(BuildContext context) async {
    final bool alreadyGranted = await isPermissionGranted();
    if (alreadyGranted) return true;

    if (!context.mounted) return false;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.layers, color: AppTheme.primaryRose),
            SizedBox(width: 10),
            Text('Floating Video Bubble', style: TextStyle(color: AppTheme.textPrimary, fontSize: 17)),
          ],
        ),
        content: const Text(
          'To see your partner\'s face in a floating circle while you play a movie in VLC or YouTube, TogetherStream needs the "Display over other apps" permission.',
          style: TextStyle(color: AppTheme.textSecondary, fontSize: 13.5, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Not Now', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx, true);
              await requestPermission();
            },
            child: const Text('Enable Permission'),
          ),
        ],
      ),
    );

    return result ?? false;
  }
}
