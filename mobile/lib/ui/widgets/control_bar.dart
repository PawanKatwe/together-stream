import 'package:flutter/material.dart';
import '../../core/theme.dart';

class ControlBar extends StatelessWidget {
  final bool isMicMuted;
  final bool isCameraMuted;
  final VoidCallback onToggleMic;
  final VoidCallback onToggleCamera;
  final VoidCallback onSwitchCamera;
  final VoidCallback onLeaveCall;

  const ControlBar({
    super.key,
    required this.isMicMuted,
    required this.isCameraMuted,
    required this.onToggleMic,
    required this.onToggleCamera,
    required this.onSwitchCamera,
    required this.onLeaveCall,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.surface.withOpacity(0.92),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: AppTheme.primaryRose.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 16,
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
          const SizedBox(width: 14),

          // Camera Toggle
          _ControlButton(
            icon: isCameraMuted ? Icons.videocam_off : Icons.videocam,
            isActive: !isCameraMuted,
            activeColor: AppTheme.primaryRose,
            inactiveColor: AppTheme.danger,
            tooltip: isCameraMuted ? 'Turn Camera On' : 'Turn Camera Off',
            onTap: onToggleCamera,
          ),
          const SizedBox(width: 14),

          // Switch Front / Back Camera
          _ControlButton(
            icon: Icons.flip_camera_android,
            isActive: true,
            activeColor: AppTheme.lavenderAccent,
            tooltip: 'Flip Camera',
            onTap: onSwitchCamera,
          ),
          const SizedBox(width: 18),

          // End Call Button
          InkWell(
            onTap: onLeaveCall,
            borderRadius: BorderRadius.circular(24),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: AppTheme.danger,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.call_end,
                color: Colors.white,
                size: 22,
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
          padding: const EdgeInsets.all(10),
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
            size: 20,
          ),
        ),
      ),
    );
  }
}
