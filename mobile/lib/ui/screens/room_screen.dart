import 'dart:async';
import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart';
import '../../core/config.dart';
import '../../core/theme.dart';
import '../../services/livekit_service.dart';
import '../../services/token_service.dart';
import '../widgets/control_bar.dart';
import '../widgets/drm_notice_dialog.dart';
import '../widgets/quality_selector_sheet.dart';
import '../widgets/video_tile.dart';

class RoomScreen extends StatefulWidget {
  final String myIdentity;
  final String? serverUrl;

  const RoomScreen({
    super.key,
    required this.myIdentity,
    this.serverUrl,
  });

  @override
  State<RoomScreen> createState() => _RoomScreenState();
}

class _RoomScreenState extends State<RoomScreen> {
  final LiveKitService _liveKitService = LiveKitService();
  Timer? _hideControlsTimer;
  bool _showControls = true;
  bool _isFetchingToken = true;
  String? _statusMessage;

  String get partnerName => AppConfig.getPartnerName(widget.myIdentity);

  @override
  void initState() {
    super.initState();
    _liveKitService.addListener(_onLiveKitStateChanged);
    _connectToRoom();
    _startHideControlsTimer();
  }

  void _onLiveKitStateChanged() {
    if (mounted) setState(() {});
  }

  void _startHideControlsTimer() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && _showControls) {
        setState(() => _showControls = false);
      }
    });
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
      if (_showControls) {
        _startHideControlsTimer();
      } else {
        _hideControlsTimer?.cancel();
      }
    });
  }

  Future<void> _connectToRoom() async {
    setState(() {
      _isFetchingToken = true;
      _statusMessage = 'Fetching room access token...';
    });

    try {
      final tokenData = await TokenService.fetchToken(
        identity: widget.myIdentity,
        customServerUrl: widget.serverUrl,
      );

      setState(() {
        _statusMessage = 'Connecting to room ${tokenData.room}...';
      });

      await _liveKitService.connect(
        url: tokenData.url,
        token: tokenData.token,
      );

      setState(() {
        _isFetchingToken = false;
        _statusMessage = null;
      });
    } catch (e) {
      setState(() {
        _isFetchingToken = false;
        _statusMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  void _handleScreenShareToggle() {
    if (_liveKitService.isScreenSharing) {
      _liveKitService.stopScreenShare();
    } else {
      DrmNoticeDialog.showIfEnabled(context, () {
        _liveKitService.startScreenShare();
      });
    }
  }

  void _openQualitySheet() {
    QualitySelectorSheet.show(
      context,
      currentPreset: _liveKitService.currentQuality,
      onSelectPreset: (preset) {
        _liveKitService.setQualityPreset(preset);
      },
    );
  }

  Future<void> _leaveCall() async {
    await _liveKitService.disconnect();
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _hideControlsTimer?.cancel();
    _liveKitService.removeListener(_onLiveKitStateChanged);
    _liveKitService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final orientation = MediaQuery.of(context).orientation;
    final isLandscape = orientation == Orientation.landscape;
    final isScreenShareActive = _liveKitService.isAnyScreenShareActive;

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _toggleControls,
        child: Stack(
          children: [
            // Video / Screen Share Layout
            SafeArea(
              child: isScreenShareActive
                  ? _buildScreenShareLayout()
                  : _buildCallOnlyLayout(isLandscape),
            ),

            // Top Status Bar (Identity & Room indicator)
            AnimatedPositioned(
              duration: const Duration(milliseconds: 250),
              top: _showControls ? 16 : -70,
              left: 16,
              right: 16,
              child: SafeArea(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.surface.withOpacity(0.85),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.primaryRose.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.favorite, size: 14, color: AppTheme.primaryRose),
                          const SizedBox(width: 6),
                          Text(
                            'Room ${AppConfig.roomName} • ${widget.myIdentity}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_liveKitService.isConnected)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.success.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.success.withOpacity(0.5)),
                        ),
                        child: Row(
                          children: [
                            const CircleAvatar(radius: 3, backgroundColor: AppTheme.success),
                            const SizedBox(width: 6),
                            Text(
                              isScreenShareActive ? 'Cinema' : 'Live',
                              style: const TextStyle(fontSize: 11, color: AppTheme.success, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Error or Loading Banner
            if (_statusMessage != null || _isFetchingToken || _liveKitService.isConnecting)
              Positioned(
                top: 80,
                left: 20,
                right: 20,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: _statusMessage != null && !_isFetchingToken
                        ? AppTheme.danger.withOpacity(0.9)
                        : AppTheme.surface.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      if (_isFetchingToken || _liveKitService.isConnecting)
                        const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryRose),
                        )
                      else
                        const Icon(Icons.error_outline, size: 20, color: Colors.white),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _statusMessage ?? 'Connecting...',
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                        ),
                      ),
                      if (_statusMessage != null && !_isFetchingToken)
                        TextButton(
                          onPressed: _connectToRoom,
                          child: const Text('Retry', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                    ],
                  ),
                ),
              ),

            // Bottom Auto-Hiding Controls
            AnimatedPositioned(
              duration: const Duration(milliseconds: 250),
              bottom: _showControls ? 20 : -90,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Center(
                  child: ControlBar(
                    isMicMuted: _liveKitService.isMicMuted,
                    isCameraMuted: _liveKitService.isCameraMuted,
                    isScreenSharing: _liveKitService.isScreenSharing,
                    currentPreset: _liveKitService.currentQuality,
                    onToggleMic: _liveKitService.toggleMicrophone,
                    onToggleCamera: _liveKitService.toggleCamera,
                    onSwitchCamera: _liveKitService.switchCamera,
                    onToggleScreenShare: _handleScreenShareToggle,
                    onOpenQualitySheet: _openQualitySheet,
                    onLeaveCall: _leaveCall,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Layout 1: Call-Only Mode (No screen share)
  Widget _buildCallOnlyLayout(bool isLandscape) {
    final localTrack = _liveKitService.localVideoTrack;
    final remoteTrack = _liveKitService.remoteVideoTrack;
    final remoteParticipant = _liveKitService.remoteParticipant;

    final myTile = VideoTile(
      title: widget.myIdentity,
      track: _liveKitService.isCameraMuted ? null : localTrack,
      isMuted: _liveKitService.isMicMuted,
      isLocal: true,
    );

    final partnerTile = remoteParticipant != null
        ? VideoTile(
            title: partnerName,
            track: remoteTrack,
            isMuted: remoteParticipant.audioTrackPublications.firstOrNull?.isMuted ?? false,
            isLocal: false,
          )
        : _buildWaitingTile();

    if (isLandscape) {
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            Expanded(child: partnerTile),
            const SizedBox(width: 8),
            Expanded(child: myTile),
          ],
        ),
      );
    } else {
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Expanded(child: partnerTile),
            const SizedBox(height: 8),
            Expanded(child: myTile),
          ],
        ),
      );
    }
  }

  // Layout 2: Screen-Share Mode (MediaProjection + System Sound active)
  Widget _buildScreenShareLayout() {
    final screenTrack = _liveKitService.activeScreenShareTrack;
    final sharer = _liveKitService.activeSharerName ?? 'Someone';

    return Container(
      color: Colors.black,
      child: Center(
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Letterboxed Screen Stream
            if (screenTrack != null)
              VideoTrackWidget(
                screenTrack,
                fit: RTCVideoViewObjectFit.RTCVideoViewObjectFitContain,
              )
            else
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(color: AppTheme.primaryRose),
                    const SizedBox(height: 16),
                    Text(
                      'Starting screen & audio stream from $sharer...',
                      style: const TextStyle(color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),

            // Sharer Badge Indicator (Top Right)
            Positioned(
              top: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.primaryRose.withOpacity(0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.movie, size: 14, color: AppTheme.primaryRoseLight),
                    const SizedBox(width: 6),
                    Text(
                      '$sharer\'s Screen & Audio',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
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

  Widget _buildWaitingTile() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.surfaceLight),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primaryRose.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.favorite, size: 36, color: AppTheme.primaryRose),
            ),
            const SizedBox(height: 16),
            Text(
              'Waiting for $partnerName...',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Room: ${AppConfig.roomName}',
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondary.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
