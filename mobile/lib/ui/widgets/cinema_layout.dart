import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart';
import '../../core/theme.dart';
import 'video_tile.dart';

class CinemaLayout extends StatelessWidget {
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
    required this.screenShareTrack,
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
    return Container(
      color: Colors.black,
      child: Column(
        children: [
          // Top ~80% (or 100% if strip hidden): Shared Screen Canvas
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Shared Screen Stream (Letterboxed, No Cropping)
                if (screenShareTrack != null)
                  VideoTrackRenderer(
                    screenShareTrack!,
                    fit: VideoViewFit.contain,
                  )
                else
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(color: AppTheme.primaryRose),
                        const SizedBox(height: 16),
                        Text(
                          'Starting screen & audio stream from $sharerName...',
                          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                        ),
                      ],
                    ),
                  ),

                // Sharer Tag Badge (Top Left)
                Positioned(
                  top: 14,
                  left: 14,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.primaryRose.withOpacity(0.35)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.movie, size: 13, color: AppTheme.primaryRoseLight),
                        const SizedBox(width: 6),
                        Text(
                          '$sharerName\'s Screen',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white),
                        ),
                      ],
                    ),
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

          // Bottom ~20%: Thin Horizontal Video Strip (Both Faces)
          AnimatedContainer(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeInOut,
            height: isVideoStripVisible ? 120 : 0,
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
