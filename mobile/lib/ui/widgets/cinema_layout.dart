import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:livekit_client/livekit_client.dart';
import '../../core/theme.dart';
import 'video_tile.dart';

class CinemaLayout extends StatelessWidget {
  final Widget? mediaWidget;
  final VideoTrack? screenShareTrack;
  final String sharerName;
  final VideoTrack? myVideoTrack;
  final VideoTrack? partnerVideoTrack;
  final String myName;
  final String partnerName;
  final bool isMyMicMuted;
  final bool isPartnerMicMuted;
  final bool isMyCameraMuted;
  final bool isVideoStripVisible;
  final VoidCallback onToggleVideoStrip;

  const CinemaLayout({
    super.key,
    this.mediaWidget,
    this.screenShareTrack,
    required this.sharerName,
    required this.myVideoTrack,
    required this.partnerVideoTrack,
    required this.myName,
    required this.partnerName,
    required this.isMyMicMuted,
    required this.isPartnerMicMuted,
    required this.isMyCameraMuted,
    required this.isVideoStripVisible,
    required this.onToggleVideoStrip,
  });

  @override
  Widget build(BuildContext context) {
    final isPortrait = MediaQuery.of(context).orientation == Orientation.portrait;

    return Container(
      color: Colors.black,
      child: Column(
        children: [
          // Top Canvas: Shared Media Canvas (strictly contained, zero distortion)
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Priority 1: In-App Cinema Media Player (MP4/MKV/YouTube)
                if (mediaWidget != null)
                  mediaWidget!
                // Priority 2: Screen Share Stream from Laptop/Partner (Strict Contain, zero stretching)
                else if (screenShareTrack != null)
                  Center(
                    child: VideoTrackRenderer(
                      screenShareTrack!,
                      fit: RTCVideoViewObjectFit.RTCVideoViewObjectFitContain,
                    ),
                  )
                else
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(color: AppTheme.primaryRose),
                        const SizedBox(height: 16),
                        Text(
                          'Starting media stream from $sharerName...',
                          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                        ),
                      ],
                    ),
                  ),

                // Restore Video Strip Floating Pill (Visible when strip is hidden)
                if (!isVideoStripVisible)
                  Positioned(
                    bottom: 16,
                    right: 16,
                    child: InkWell(
                      onTap: onToggleVideoStrip,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.surface.withOpacity(0.85),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppTheme.primaryRose.withOpacity(0.4)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.visibility, size: 14, color: AppTheme.primaryRoseLight),
                            SizedBox(width: 6),
                            Text(
                              'Show Faces',
                              style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Bottom: Video Strip (Both Faces) with adaptive height
          AnimatedContainer(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeInOut,
            height: isVideoStripVisible ? (isPortrait ? 140.0 : 110.0) : 0,
            child: isVideoStripVisible
                ? Container(
                    decoration: BoxDecoration(
                      color: AppTheme.surface.withOpacity(0.95),
                      border: Border(
                        top: BorderSide(color: AppTheme.surfaceLight.withOpacity(0.8), width: 1),
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    child: Row(
                      children: [
                        // Partner Camera Tile
                        Expanded(
                          child: VideoTile(
                            title: partnerName,
                            track: partnerVideoTrack,
                            isMuted: isPartnerMicMuted,
                            isLocal: false,
                          ),
                        ),
                        const SizedBox(width: 8),

                        // My Camera Tile
                        Expanded(
                          child: VideoTile(
                            title: myName,
                            track: isMyCameraMuted ? null : myVideoTrack,
                            isMuted: isMyMicMuted,
                            isLocal: true,
                          ),
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
