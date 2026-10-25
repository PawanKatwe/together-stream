import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import '../../core/config.dart';
import '../../core/theme.dart';
import '../../services/livekit_service.dart';
import '../../services/media_sync_service.dart';
import '../../services/overlay_service.dart';
import '../../services/token_service.dart';
import '../widgets/cinema_layout.dart';
import '../widgets/control_bar.dart';
import '../widgets/drm_notice_dialog.dart';
import '../widgets/floating_emoji_overlay.dart';
import '../widgets/in_app_cinema_player.dart';
import '../widgets/in_movie_chat_overlay.dart';
import '../widgets/quality_selector_sheet.dart';
import '../widgets/snapshot_modal.dart';
import '../widgets/video_tile.dart';
import '../widgets/youtube_input_dialog.dart';
import 'setup_screen.dart';

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

class _RoomScreenState extends State<RoomScreen> with WidgetsBindingObserver {
  final LiveKitService _liveKitService = LiveKitService();
  final MediaSyncService _mediaSyncService = MediaSyncService();

  Timer? _hideControlsTimer;
  Timer? _callDurationTimer;
  Duration _callDuration = Duration.zero;
  bool _showControls = true;
  bool _isFetchingToken = true;
  String? _statusMessage;

  // Cinema & Layout States
  bool _isVideoStripVisible = true;
  bool _isFullscreen = false;
  bool _wasCinemaActive = false;

  // Romantic Couple Features
  final GlobalKey _screenshotKey = GlobalKey();
  final List<FloatingEmojiData> _floatingEmojis = [];
  final List<InMovieChatMessage> _chatMessages = [];
  bool _showReactionPicker = false;
  bool _isShutterFlashing = false;

  String get partnerName => AppConfig.getPartnerName(widget.myIdentity);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _liveKitService.addListener(_onLiveKitStateChanged);
    _mediaSyncService.addListener(_onMediaSyncStateChanged);

    // Hook LiveKit reliable data channel to MediaSyncService & Couple Features
    _liveKitService.onDataReceived = (message, sender) {
      _handleIncomingData(message, sender);
    };

    _connectToRoom();
    _startHideControlsTimer();

    // Call / movie date duration timer
    _callDurationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted && _liveKitService.isConnected) {
        setState(() {
          _callDuration += const Duration(seconds: 1);
        });
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (_liveKitService.isScreenSharing) {
      if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
        OverlayService.showFloatingBubble(partnerName);
      } else if (state == AppLifecycleState.resumed) {
        OverlayService.hideFloatingBubble();
      }
    }
  }

  void _onMediaSyncStateChanged() {
    _checkOrientationAndLayout();
    if (mounted) setState(() {});
  }

  void _onLiveKitStateChanged() {
    _checkOrientationAndLayout();
    if (mounted) setState(() {});
  }

  String _formatCallDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    final seconds = d.inSeconds.remainder(60);
    if (hours > 0) {
      return '$hours:${twoDigits(minutes)}:${twoDigits(seconds)}';
    }
    return '${twoDigits(minutes)}:${twoDigits(seconds)}';
  }

  void _toggleOrientation() {
    final orientation = MediaQuery.of(context).orientation;
    if (orientation == Orientation.landscape) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
      ]);
    } else {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    }
  }

  void _handleIncomingData(String message, String? sender) {
    try {
      final data = jsonDecode(message);
      if (data is! Map<String, dynamic>) return;

      final type = data['type'] as String?;
      if (type == 'EMOJI_REACTION') {
        final emoji = data['emoji'] as String? ?? '❤️';
        _spawnEmojiBurst(emoji, isLocal: false);
      } else if (type == 'CHAT_MESSAGE') {
        final text = data['text'] as String? ?? '';
        final from = data['sender'] as String? ?? sender ?? partnerName;
        _addChatMessage(from, text, isMe: false);
      } else if (type == 'SNAPSHOT_TAKEN') {
        final from = data['sender'] as String? ?? sender ?? partnerName;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('📸 $from captured a keepsake moment with you! ❤️'),
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        // Forward media sync messages to MediaSyncService
        _mediaSyncService.handleIncomingSyncMessage(
          message,
          widget.myIdentity,
          sendDataFn: _liveKitService.sendDataMessage,
        );
      }
    } catch (e) {
      debugPrint('Error handling incoming data: $e');
    }
  }

  void _sendEmojiReaction(String emoji) {
    _spawnEmojiBurst(emoji, isLocal: true);
    _liveKitService.sendDataMessage(jsonEncode({
      'type': 'EMOJI_REACTION',
      'emoji': emoji,
      'sender': widget.myIdentity,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    }));
  }

  void _spawnEmojiBurst(String emoji, {bool isLocal = true}) {
    HapticFeedback.lightImpact();
    final random = Random();
    final newItems = <FloatingEmojiData>[];

    for (int i = 0; i < 4; i++) {
      newItems.add(
        FloatingEmojiData(
          id: '${DateTime.now().microsecondsSinceEpoch}_$i',
          emoji: emoji,
          startX: (0.45 + (random.nextDouble() - 0.5) * 0.45).clamp(0.1, 0.85),
          sway: (random.nextDouble() - 0.5) * 60,
          scale: 0.85 + random.nextDouble() * 0.45,
          createdAt: DateTime.now(),
        ),
      );
    }

    if (!mounted) return;
    setState(() {
      _floatingEmojis.addAll(newItems);
    });

    Timer(const Duration(milliseconds: 2600), () {
      if (mounted) {
        setState(() {
          _floatingEmojis.removeWhere((item) => newItems.contains(item));
        });
      }
    });
  }

  void _openChatSheet() {
    InMovieChatSheet.show(
      context,
      partnerName: partnerName,
      onSendMessage: _sendChatMessage,
    );
  }

  void _sendChatMessage(String text) {
    _addChatMessage(widget.myIdentity, text, isMe: true);
    _liveKitService.sendDataMessage(jsonEncode({
      'type': 'CHAT_MESSAGE',
      'text': text,
      'sender': widget.myIdentity,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    }));
  }

  void _addChatMessage(String sender, String text, {required bool isMe}) {
    if (!isMe) HapticFeedback.selectionClick();
    final msg = InMovieChatMessage(
      id: '${DateTime.now().microsecondsSinceEpoch}',
      sender: sender,
      text: text,
      isMe: isMe,
      timestamp: DateTime.now(),
    );

    if (!mounted) return;
    setState(() {
      _chatMessages.add(msg);
    });

    Timer(const Duration(seconds: 8), () {
      if (mounted) {
        setState(() {
          _chatMessages.remove(msg);
        });
      }
    });
  }

  Future<void> _takeSnapshot() async {
    try {
      HapticFeedback.mediumImpact();
      // Shutter flash animation
      setState(() => _isShutterFlashing = true);
      Future.delayed(const Duration(milliseconds: 160), () {
        if (mounted) setState(() => _isShutterFlashing = false);
      });

      final boundary = _screenshotKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;

      final image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final bytes = byteData.buffer.asUint8List();
      final now = DateTime.now();
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      final dateStr = '${months[(now.month - 1).clamp(0, 11)]} ${now.day}, ${now.year}';

      await _liveKitService.sendDataMessage(jsonEncode({
        'type': 'SNAPSHOT_TAKEN',
        'sender': widget.myIdentity,
        'timestamp': now.millisecondsSinceEpoch,
      }));

      if (mounted) {
        SnapshotModal.show(context, imageBytes: bytes, dateText: dateStr);
      }
    } catch (e) {
      debugPrint('Snapshot capture error: $e');
    }
  }

  void _checkOrientationAndLayout() {
    final isCinemaActive = _mediaSyncService.hasMedia || _liveKitService.isAnyScreenShareActive;

    // Handle orientation in cinema mode
    if (isCinemaActive && !_wasCinemaActive) {
      _wasCinemaActive = true;
      if (_mediaSyncService.isPortraitVideo) {
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
        ]);
      } else {
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
      }
    } else if (!isCinemaActive && _wasCinemaActive) {
      _wasCinemaActive = false;
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    }
  }

  void _startHideControlsTimer() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(seconds: 4), () {
      if (mounted && _showControls && (_mediaSyncService.isPlaying || _liveKitService.isScreenSharing)) {
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

  void _handleScreenShareToggle() async {
    if (_liveKitService.isScreenSharing) {
      await _liveKitService.stopScreenShare();
      await OverlayService.hideFloatingBubble();
    } else {
      await OverlayService.promptOverlayPermission(context);

      if (!mounted) return;
      DrmNoticeDialog.showIfEnabled(context, () async {
        final bool started = await _liveKitService.startScreenShare();
        if (started) {
          final partner = widget.myIdentity == AppConfig.userPawan
              ? AppConfig.userPriya
              : AppConfig.userPawan;
          await OverlayService.showFloatingBubble(partner);
        }
      });
    }
  }

  void _toggleVideoStrip() {
    setState(() {
      _isVideoStripVisible = !_isVideoStripVisible;
      _startHideControlsTimer();
    });
  }

  void _toggleFullscreen() {
    setState(() {
      _isFullscreen = !_isFullscreen;
      if (_isFullscreen) {
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      } else {
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      }
      _startHideControlsTimer();
    });
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
    _callDurationTimer?.cancel();
    await OverlayService.hideFloatingBubble();
    await _mediaSyncService.closeMedia(
      myIdentity: widget.myIdentity,
      sendDataFn: _liveKitService.sendDataMessage,
      broadcast: false,
    );
    await _liveKitService.disconnect();

    // Restore orientation
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const SetupScreen()),
        (route) => false,
      );
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _hideControlsTimer?.cancel();
    _callDurationTimer?.cancel();
    OverlayService.hideFloatingBubble();
    _mediaSyncService.removeListener(_onMediaSyncStateChanged);
    _mediaSyncService.dispose();
    _liveKitService.removeListener(_onLiveKitStateChanged);
    _liveKitService.dispose();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final orientation = MediaQuery.of(context).orientation;
    final isLandscape = orientation == Orientation.landscape;
    final isScreenShareActive = _liveKitService.isAnyScreenShareActive;
    final isCinemaActive = _mediaSyncService.hasMedia || isScreenShareActive;

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _toggleControls,
        child: Stack(
          children: [
            // Video / In-App Cinema Layout (Wrapped in RepaintBoundary for snapshot keepsake)
            RepaintBoundary(
              key: _screenshotKey,
              child: SafeArea(
                top: !_isFullscreen,
                bottom: !_isFullscreen,
                child: isCinemaActive
                    ? CinemaLayout(
                        mediaWidget: _mediaSyncService.hasMedia
                            ? InAppCinemaPlayer(
                                mediaService: _mediaSyncService,
                                myIdentity: widget.myIdentity,
                                sendDataFn: _liveKitService.sendDataMessage,
                                onToggleOrientation: _toggleOrientation,
                              )
                            : null,
                        screenShareTrack: _liveKitService.activeScreenShareTrack,
                        sharerName: _mediaSyncService.hasMedia
                            ? (_mediaSyncService.currentTitle ?? 'In-App Cinema')
                            : (_liveKitService.activeSharerName ?? 'Someone'),
                        myVideoTrack: _liveKitService.localVideoTrack,
                        partnerVideoTrack: _liveKitService.remoteVideoTrack,
                        myName: widget.myIdentity,
                        partnerName: partnerName,
                        isMyMicMuted: _liveKitService.isMicMuted,
                        isPartnerMicMuted: _liveKitService.remoteParticipant?.audioTrackPublications.firstOrNull?.muted ?? false,
                        isMyCameraMuted: _liveKitService.isCameraMuted,
                        isVideoStripVisible: _isVideoStripVisible,
                        onToggleVideoStrip: _toggleVideoStrip,
                      )
                    : _buildCallOnlyLayout(isLandscape),
              ),
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
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Call duration timer
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: AppTheme.surface.withOpacity(0.85),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppTheme.primaryRose.withOpacity(0.35)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text('⏱️', style: TextStyle(fontSize: 12)),
                                const SizedBox(width: 5),
                                Text(
                                  _formatCallDuration(_callDuration),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Dedicated Screen Rotate Button (Cleanly spaced, NO overlap)
                          InkWell(
                            onTap: _toggleOrientation,
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppTheme.surface.withOpacity(0.85),
                                shape: BoxShape.circle,
                                border: Border.all(color: AppTheme.primaryRose.withOpacity(0.4)),
                              ),
                              child: const Icon(
                                Icons.screen_rotation_rounded,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Live Call / Cinema Status
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: AppTheme.success.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppTheme.success.withOpacity(0.5)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const CircleAvatar(radius: 3, backgroundColor: AppTheme.success),
                                const SizedBox(width: 6),
                                Text(
                                  isCinemaActive ? 'Cinema' : 'Live Call',
                                  style: const TextStyle(fontSize: 11, color: AppTheme.success, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),

            // Partner Movie Invitation Banner (Visible when partner loaded a movie)
            if (_mediaSyncService.pendingPartnerFileName != null && !_mediaSyncService.hasMedia)
              Positioned(
                top: 76,
                left: 20,
                right: 20,
                child: InkWell(
                  onTap: () {
                    _mediaSyncService.pickLocalFile(
                      myIdentity: widget.myIdentity,
                      sendDataFn: _liveKitService.sendDataMessage,
                    );
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppTheme.surface.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.primaryRose, width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryRose.withOpacity(0.25),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Text('🎬', style: TextStyle(fontSize: 20)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '$partnerName loaded: ${_mediaSyncService.pendingPartnerFileName}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              const Text(
                                'Tap here to select your copy & sync playback ❤️',
                                style: TextStyle(color: AppTheme.primaryRoseLight, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios_rounded, color: AppTheme.primaryRose, size: 14),
                      ],
                    ),
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

            // Romantic In-Movie Chat Overlay (Translucent auto-fading bubbles)
            Positioned(
              bottom: 95,
              left: 16,
              child: InMovieChatOverlay(messages: _chatMessages),
            ),

            // Romantic Floating Emoji Reactions (Floating hearts & kisses)
            FloatingEmojiOverlay(emojis: _floatingEmojis),

            // Romantic Reaction Picker Capsule
            if (_showReactionPicker)
              Positioned(
                bottom: 84,
                left: 0,
                right: 0,
                child: Center(
                  child: ReactionPickerBar(
                    onSelectEmoji: (emoji) {
                      _sendEmojiReaction(emoji);
                      setState(() => _showReactionPicker = false);
                    },
                    onClose: () => setState(() => _showReactionPicker = false),
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
                    isAnyMediaOrScreenActive: isCinemaActive,
                    isVideoStripVisible: _isVideoStripVisible,
                    isFullscreen: _isFullscreen,
                    currentPreset: _liveKitService.currentQuality,
                    onToggleMic: _liveKitService.toggleMicrophone,
                    onToggleCamera: _liveKitService.toggleCamera,
                    onSwitchCamera: _liveKitService.switchCamera,
                    onPickLocalMovie: () {
                      _mediaSyncService.pickLocalFile(
                        myIdentity: widget.myIdentity,
                        sendDataFn: _liveKitService.sendDataMessage,
                      );
                    },
                    onOpenYouTube: () {
                      YoutubeInputDialog.show(
                        context,
                        (url) => _mediaSyncService.loadYouTubeUrl(
                          url,
                          myIdentity: widget.myIdentity,
                          sendDataFn: _liveKitService.sendDataMessage,
                        ),
                      );
                    },
                    onToggleScreenShare: _handleScreenShareToggle,
                    onToggleVideoStrip: _toggleVideoStrip,
                    onToggleFullscreen: _toggleFullscreen,
                    onOpenQualitySheet: _openQualitySheet,
                    onToggleReactions: () {
                      setState(() => _showReactionPicker = !_showReactionPicker);
                    },
                    onOpenChat: _openChatSheet,
                    onTakeSnapshot: _takeSnapshot,
                    onLeaveCall: _leaveCall,
                  ),
                ),
              ),
            ),

            // Keepsake Camera Shutter Flash Effect
            if (_isShutterFlashing)
              Positioned.fill(
                child: IgnorePointer(
                  child: Container(color: Colors.white.withOpacity(0.9)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Layout 1: Call-Only Mode (Equal Split when no movie is playing)
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
            isMuted: remoteParticipant.audioTrackPublications.firstOrNull?.muted ?? false,
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
