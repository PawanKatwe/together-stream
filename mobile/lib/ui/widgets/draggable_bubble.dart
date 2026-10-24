import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart';
import '../../core/theme.dart';
import 'video_tile.dart';

class DraggableBubble extends StatefulWidget {
  final VideoTrack? partnerVideoTrack;
  final String partnerName;
  final bool isPartnerMicMuted;
  final VoidCallback? onTap;

  const DraggableBubble({
    super.key,
    required this.partnerVideoTrack,
    required this.partnerName,
    this.isPartnerMicMuted = false,
    this.onTap,
  });

  @override
  State<DraggableBubble> createState() => _DraggableBubbleState();
}

class _DraggableBubbleState extends State<DraggableBubble> {
  Offset _position = const Offset(16, 120);
  bool _isMinimized = false;

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final bubbleWidth = _isMinimized ? 64.0 : 130.0;
    final bubbleHeight = _isMinimized ? 64.0 : 180.0;

    return Positioned(
      left: _position.dx,
      top: _position.dy,
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            final newX = (_position.dx + details.delta.dx).clamp(8.0, screenSize.width - bubbleWidth - 8.0);
            final newY = (_position.dy + details.delta.dy).clamp(40.0, screenSize.height - bubbleHeight - 60.0);
            _position = Offset(newX, newY);
          });
        },
        onPanEnd: (_) {
          // Snap to nearest horizontal edge (left or right)
          final snapToLeft = _position.dx + (bubbleWidth / 2) < screenSize.width / 2;
          final targetX = snapToLeft ? 12.0 : screenSize.width - bubbleWidth - 12.0;

          setState(() {
            _position = Offset(targetX, _position.dy);
          });
        },
        onDoubleTap: () {
          setState(() => _isMinimized = !_isMinimized);
        },
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: bubbleWidth,
          height: bubbleHeight,
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(_isMinimized ? 32 : 16),
            border: Border.all(
              color: AppTheme.primaryRose,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.6),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: _isMinimized
              ? Center(
                  child: Text(
                    widget.partnerName.isNotEmpty ? widget.partnerName[0] : 'P',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryRoseLight,
                    ),
                  ),
                )
              : VideoTile(
                  title: widget.partnerName,
                  track: widget.partnerVideoTrack,
                  isMuted: widget.isPartnerMicMuted,
                  isLocal: false,
                ),
        ),
      ),
    );
  }
}
