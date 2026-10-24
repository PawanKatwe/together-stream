import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../services/livekit_service.dart';

class ControlBar extends StatelessWidget {
  final bool isMicMuted;
  final bool isCameraMuted;
  final bool isScreenSharing;
  final ScreenQualityPreset currentPreset;
  final VoidCallback onToggleMic;
  final VoidCallback onToggleCamera;
  final VoidCallback onSwitchCamera;
  final VoidCallback onToggleScreenShare;
  final VoidCallback onOpenQualitySheet;
  final VoidCallback onLeaveCall;

  const ControlBar({
    super.key,
    required this.isMicMuted,
    required this.isCameraMuted,
    required this.isScreenSharing,
    required this.currentPreset,
    required this.onToggleMic,
    required this.onToggleCamera,
    required this.onSwitchCamera,
    required this.onToggleScreenShare,
    required this.onOpenQualitySheet,
    required this.onLeaveCall,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.surface.withOpacity(0.92),
        borderRadius: BorderRadius.circular(36),
        border: Border.all(
          color: AppTheme.primaryRose.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.55),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Microphone Toggle
          _ControlButton(
            icon: isMicMuted ? Icons.mic_off : Icons.mic,
            isActive: !isMicMuted,
            activeColor: AppTheme.primaryRose,
            inactiveColor: AppTheme.danger,
            tooltip: isMicMuted ? 'Unmute Mic' : 'Mute Mic',
            onTap: onToggleMic,
          ),
          const SizedBox(width: 10),

          // Camera Toggle
          _ControlButton(
            icon: isCameraMuted ? Icons.videocam_off : Icons.videocam,
            isActive: !isCameraMuted,
            activeColor: AppTheme.primaryRose,
            inactiveColor: AppTheme.danger,
            tooltip: isCameraMuted ? 'Turn Camera On' : 'Turn Camera Off',
            onTap: onToggleCamera,
          ),
          const SizedBox(width: 10),

          // Switch Front / Back Camera
          _ControlButton(
            icon: Icons.flip_camera_android,
            isActive: true,
            activeColor: AppTheme.lavenderAccent,
            tooltip: 'Flip Camera',
            onTap: onSwitchCamera,
          ),
          const SizedBox(width: 10),

          // Screen Share Toggle (Movie & Sound)
          _ControlButton(
            icon: isScreenSharing ? Icons.stop_screen_share : Icons.screen_share,
            isActive: isScreenSharing,
            activeColor: AppTheme.primaryRoseLight,
            inactiveColor: Colors.white70,
            tooltip: isScreenSharing ? 'Stop Screen Sharing' : 'Share Screen & Movie Sound',
            onTap: onToggleScreenShare,
          ),
          const SizedBox(width: 10),

          // Quality Selector
          Tooltip(
            message: 'Stream Quality (${currentPreset.label})',
            child: InkWell(
              onTap: onOpenQualitySheet,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceLight,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppTheme.primaryRose.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  currentPreset.label.split(' ').first,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryRoseLight,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),

          // End Call Button
          InkWell(
            onTap: onLeaveCall,
            borderRadius: BorderRadius.circular(24),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                color: AppTheme.danger,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.call_end,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final Color activeColor;
  final Color? inactiveColor;
  final String tooltip;
  final VoidCallback onTap;

  const _ControlButton({
    required this.icon,
    required this.isActive,
    required this.activeColor,
    this.inactiveColor,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive ? activeColor : (inactiveColor ?? Colors.grey);
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: color.withOpacity(0.18),
            shape: BoxShape.circle,
            border: Border.all(
              color: color.withOpacity(0.35),
              width: 1,
            ),
          ),
          child: Icon(
            icon,
            color: color,
            size: 19,
          ),
        ),
      ),
    );
  }
}
