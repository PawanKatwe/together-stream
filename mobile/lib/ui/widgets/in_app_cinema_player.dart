import 'dart:async';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../../core/theme.dart';
import '../../services/media_sync_service.dart';

class InAppCinemaPlayer extends StatefulWidget {
  final MediaSyncService mediaService;
  final String myIdentity;
  final Future<void> Function(String) sendDataFn;
  final VoidCallback? onToggleOrientation;

  const InAppCinemaPlayer({
    super.key,
    required this.mediaService,
    required this.myIdentity,
    required this.sendDataFn,
    this.onToggleOrientation,
  });

  @override
  State<InAppCinemaPlayer> createState() => _InAppCinemaPlayerState();
}

class _InAppCinemaPlayerState extends State<InAppCinemaPlayer> {
  bool _showControls = true;
  Timer? _hideTimer;
  BoxFit _fitMode = BoxFit.contain;

  @override
  void initState() {
    super.initState();
    _startHideTimer();
  }

  void _startHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 4), () {
      if (mounted && widget.mediaService.isPlaying) {
        setState(() => _showControls = false);
      }
    });
  }

  void _onTapCanvas() {
    setState(() {
      _showControls = !_showControls;
    });
    if (_showControls) {
      _startHideTimer();
    }
  }

  void _toggleFitMode() {
    setState(() {
      _fitMode = _fitMode == BoxFit.contain ? BoxFit.fitWidth : BoxFit.contain;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_fitMode == BoxFit.contain ? 'Aspect Ratio: Fit to Screen' : 'Aspect Ratio: Fill Width'),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '$hours:${twoDigits(minutes)}:${twoDigits(seconds)}';
    } else {
      return '${twoDigits(minutes)}:${twoDigits(seconds)}';
    }
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final service = widget.mediaService;

    return GestureDetector(
      onTap: _onTapCanvas,
      behavior: HitTestBehavior.opaque,
      child: Container(
        color: Colors.black,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // 1. Media View (Local File or YouTube) with strictly preserved aspect ratio
            Center(
              child: _buildMediaSurface(service),
            ),

            // 2. Romantic Action Notice Toast (e.g. "Paused by Priya ❤️")
            if (service.lastActionNotice != null)
              Positioned(
                top: 20,
                child: AnimatedOpacity(
                  opacity: 1.0,
                  duration: const Duration(milliseconds: 300),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.surface.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.primaryRose.withOpacity(0.5), width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryRose.withOpacity(0.2),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Text(
                      service.lastActionNotice!,
                      style: const TextStyle(
                        color: AppTheme.primaryRose,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ),

            // 3. Top Title Bar (Visible when controls shown)
            AnimatedPositioned(
              duration: const Duration(milliseconds: 250),
              top: _showControls ? 16 : -60,
              left: 16,
              right: 16,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.75),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.primaryRose.withOpacity(0.35)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('🎬', style: TextStyle(fontSize: 14)),
                        const SizedBox(width: 8),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 180),
                          child: Text(
                            service.currentTitle ?? 'In-App Cinema',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  // Fit Mode Button (Contain vs Fill Width)
                  IconButton(
                    onPressed: _toggleFitMode,
                    tooltip: 'Aspect Ratio / Fit',
                    icon: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.75),
                        shape: BoxShape.circle,
                        border: Border.all(color: AppTheme.primaryRose.withOpacity(0.5)),
                      ),
                      child: Icon(
                        _fitMode == BoxFit.contain ? Icons.aspect_ratio_rounded : Icons.fit_screen_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                  // Orientation Toggle Button (Portrait / Landscape)
                  if (widget.onToggleOrientation != null)
                    IconButton(
                      onPressed: widget.onToggleOrientation,
                      tooltip: 'Rotate Screen (Portrait / Landscape)',
                      icon: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.75),
                          shape: BoxShape.circle,
                          border: Border.all(color: AppTheme.primaryRose.withOpacity(0.5)),
                        ),
                        child: const Icon(Icons.screen_rotation_rounded, color: Colors.white, size: 18),
                      ),
                    ),
                  // Close Cinema Button
                  IconButton(
                    onPressed: () {
                      service.closeMedia(
                        myIdentity: widget.myIdentity,
                        sendDataFn: widget.sendDataFn,
                      );
                    },
                    icon: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.75),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.redAccent.withOpacity(0.5)),
                      ),
                      child: const Icon(Icons.close_rounded, color: Colors.white, size: 18),
                    ),
                    tooltip: 'Close Cinema',
                  ),
                ],
              ),
            ),

            // 4. Center Play / Pause Icon
            if (_showControls || !service.isPlaying)
              Center(
                child: IconButton(
                  iconSize: 64,
                  icon: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.65),
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.primaryRose.withOpacity(0.6), width: 2),
                    ),
                    child: Icon(
                      service.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 42,
                    ),
                  ),
                  onPressed: () {
                    service.togglePlayPause(
                      myIdentity: widget.myIdentity,
                      sendDataFn: widget.sendDataFn,
                    );
                    _startHideTimer();
                  },
                ),
              ),

            // 5. Bottom Scrub & Progress Bar (Visible when controls shown)
            AnimatedPositioned(
              duration: const Duration(milliseconds: 250),
              bottom: _showControls ? 12 : -70,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.75),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.15)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Text(
                          _formatDuration(service.currentPosition),
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                        Expanded(
                          child: SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              activeTrackColor: AppTheme.primaryRose,
                              inactiveTrackColor: Colors.white24,
                              thumbColor: AppTheme.primaryRose,
                              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                              overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                            ),
                            child: Slider(
                              value: service.currentPosition.inMilliseconds
                                  .toDouble()
                                  .clamp(0.0, service.totalDuration.inMilliseconds.toDouble() > 0
                                      ? service.totalDuration.inMilliseconds.toDouble()
                                      : 1.0),
                              max: service.totalDuration.inMilliseconds.toDouble() > 0
                                  ? service.totalDuration.inMilliseconds.toDouble()
                                  : 1.0,
                              onChanged: (val) {
                                service.seekTo(
                                  Duration(milliseconds: val.toInt()),
                                  myIdentity: widget.myIdentity,
                                  sendDataFn: widget.sendDataFn,
                                );
                                _startHideTimer();
                              },
                            ),
                          ),
                        ),
                        Text(
                          _formatDuration(service.totalDuration),
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaSurface(MediaSyncService service) {
    if (service.mediaType == MediaSourceType.localFile) {
      final controller = service.videoPlayerController;
      if (controller != null && controller.value.isInitialized) {
        final size = controller.value.size;
        final aspect = controller.value.aspectRatio;
        return FittedBox(
          fit: _fitMode,
          alignment: Alignment.center,
          child: SizedBox(
            width: size.width > 0 ? size.width : 1600,
            height: size.height > 0 ? size.height : 900,
            child: AspectRatio(
              aspectRatio: aspect > 0 ? aspect : 16 / 9,
              child: VideoPlayer(controller),
            ),
          ),
        );
      } else {
        return const Center(
          child: CircularProgressIndicator(color: AppTheme.primaryRose),
        );
      }
    } else if (service.mediaType == MediaSourceType.youtube) {
      final controller = service.youtubePlayerController;
      if (controller != null) {
        return FittedBox(
          fit: _fitMode,
          alignment: Alignment.center,
          child: SizedBox(
            width: service.isPortraitVideo ? 1080 : 1920,
            height: service.isPortraitVideo ? 1920 : 1080,
            child: YoutubePlayer(
              controller: controller,
              showVideoProgressIndicator: true,
              progressIndicatorColor: AppTheme.primaryRose,
              onReady: () {
                debugPrint('YouTube player is ready - initiating playback');
                controller.play();
              },
            ),
          ),
        );
      }
    }
    return const SizedBox.shrink();
  }
}
