import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../services/livekit_service.dart';

class ControlBar extends StatelessWidget {
  final bool isMicMuted;
  final bool isCameraMuted;
  final bool isScreenSharing;
  final bool isAnyMediaOrScreenActive;
  final bool isVideoStripVisible;
  final bool isFullscreen;
  final ScreenQualityPreset currentPreset;
  final VoidCallback onToggleMic;
  final VoidCallback onToggleCamera;
  final VoidCallback onSwitchCamera;
  final VoidCallback onPickLocalMovie;
  final VoidCallback onOpenYouTube;
  final VoidCallback onToggleScreenShare;
  final VoidCallback onToggleVideoStrip;
  final VoidCallback onToggleFullscreen;
  final VoidCallback onOpenQualitySheet;
  final VoidCallback onLeaveCall;

  const ControlBar({
    super.key,
    required this.isMicMuted,
    required this.isCameraMuted,
    required this.isScreenSharing,
    required this.isAnyMediaOrScreenActive,
    required this.isVideoStripVisible,
    required this.isFullscreen,
    required this.currentPreset,
    required this.onToggleMic,
    required this.onToggleCamera,
    required this.onSwitchCamera,
    required this.onPickLocalMovie,
    required this.onOpenYouTube,
    required this.onToggleScreenShare,
    required this.onToggleVideoStrip,
    required this.onToggleFullscreen,
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
          // 1. Pick Local Movie File (MP4, MKV)
          _ControlButton(
            icon: Icons.movie_creation_rounded,
            isActive: true,
            activeColor: AppTheme.primaryRose,
            tooltip: 'Pick Movie from Storage (MP4/MKV)',
            onTap: onPickLocalMovie,
          ),
          const SizedBox(width: 8),

          // 2. Watch YouTube Video Together
          _ControlButton(
            icon: Icons.play_circle_fill_rounded,
            isActive: true,
            activeColor: Colors.redAccent,
            tooltip: 'Paste YouTube Link to Watch Together',
            onTap: onOpenYouTube,
          ),
          const SizedBox(width: 8),

          // 3. Microphone Toggle
          _ControlButton(
            icon: isMicMuted ? Icons.mic_off : Icons.mic,
            isActive: !isMicMuted,
            activeColor: AppTheme.primaryRose,
            inactiveColor: AppTheme.danger,
            tooltip: isMicMuted ? 'Unmute Mic' : 'Mute Mic',
            onTap: onToggleMic,
          ),
          const SizedBox(width: 8),

          // 4. Camera Toggle
          _ControlButton(
            icon: isCameraMuted ? Icons.videocam_off : Icons.videocam,
            isActive: !isCameraMuted,
            activeColor: AppTheme.primaryRose,
            inactiveColor: AppTheme.danger,
            tooltip: isCameraMuted ? 'Turn Camera On' : 'Turn Camera Off',
            onTap: onToggleCamera,
          ),
          const SizedBox(width: 8),

          // 5. Flip Camera (Front / Back)
          _ControlButton(
            icon: Icons.flip_camera_android,
            isActive: true,
            activeColor: AppTheme.lavenderAccent,
            tooltip: 'Flip Camera',
            onTap: onSwitchCamera,
          ),
          const SizedBox(width: 8),

          // 6. Hide / Show Video Strip (Visible when movie is playing or screen is shared)
          if (isAnyMediaOrScreenActive) ...[
            _ControlButton(
              icon: isVideoStripVisible ? Icons.visibility : Icons.visibility_off,
              isActive: isVideoStripVisible,
              activeColor: AppTheme.primaryRose,
              inactiveColor: AppTheme.textSecondary,
              tooltip: isVideoStripVisible ? 'Hide Faces (Full Movie Height)' : 'Show Faces',
              onTap: onToggleVideoStrip,
            ),
            const SizedBox(width: 8),
          ],

          // 7. Fullscreen Toggle
          _ControlButton(
            icon: isFullscreen ? Icons.fullscreen_exit : Icons.fullscreen,
            isActive: isFullscreen,
            activeColor: AppTheme.primaryRose,
            inactiveColor: Colors.white70,
            tooltip: isFullscreen ? 'Exit Fullscreen' : 'Cinema Fullscreen',
            onTap: onToggleFullscreen,
          ),
          const SizedBox(width: 12),

          // 8. End Call Button
          InkWell(
            onTap: onLeaveCall,
            borderRadius: BorderRadius.circular(24),
            child: Container(
              padding: const EdgeInsets.all(9),
              decoration: const BoxDecoration(
                color: AppTheme.danger,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.call_end,
                color: Colors.white,
                size: 19,
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
          padding: const EdgeInsets.all(8.5),
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
            size: 18,
          ),
        ),
      ),
    );
  }
}
