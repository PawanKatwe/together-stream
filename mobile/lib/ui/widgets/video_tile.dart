import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart';
import '../../core/theme.dart';

class VideoTile extends StatelessWidget {
  final String title;
  final VideoTrack? track;
  final bool isMuted;
  final bool isSpeaking;
  final bool isLocal;

  const VideoTile({
    super.key,
    required this.title,
    this.track,
    this.isMuted = false,
    this.isSpeaking = false,
    this.isLocal = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSpeaking ? AppTheme.primaryRose : AppTheme.surfaceLight,
          width: isSpeaking ? 2.5 : 1.0,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Video Layer or Avatar Placeholder
          if (track != null)
            VideoTrackWidget(
              track!,
              fit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
              mirror: isLocal,
            )
          else
            Container(
              color: AppTheme.surface,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: AppTheme.roseDark.withOpacity(0.5),
                      child: Text(
                        title.isNotEmpty ? title[0].toUpperCase() : '?',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryRoseLight,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Camera Off',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.textSecondary.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Name and Status Badge (Bottom-Left)
          Positioned(
            left: 10,
            bottom: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.65),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (isMuted) ...[
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.mic_off,
                      size: 14,
                      color: AppTheme.danger,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
