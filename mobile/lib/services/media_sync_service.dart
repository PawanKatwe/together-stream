import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:video_player/video_player.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

enum MediaSourceType { none, localFile, youtube }

class MediaSyncService extends ChangeNotifier {
  MediaSourceType _mediaType = MediaSourceType.none;
  VideoPlayerController? _videoPlayerController;
  YoutubePlayerController? _youtubePlayerController;

  String? _currentTitle;
  String? _currentPathOrId;
  bool _isPlaying = false;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  String? _lastActionNotice;
  Timer? _noticeTimer;
  Timer? _heartbeatTimer;
  bool _isApplyingRemoteSync = false;
  String? _pendingPartnerFileName;

  MediaSourceType get mediaType => _mediaType;
  VideoPlayerController? get videoPlayerController => _videoPlayerController;
  YoutubePlayerController? get youtubePlayerController => _youtubePlayerController;
  String? get currentTitle => _currentTitle;
  String? get currentPathOrId => _currentPathOrId;
  bool get isPlaying => _isPlaying;
  Duration get currentPosition => _currentPosition;
  Duration get totalDuration => _totalDuration;
  String? get lastActionNotice => _lastActionNotice;
  String? get pendingPartnerFileName => _pendingPartnerFileName;
  bool get hasMedia => _mediaType != MediaSourceType.none;

  // 1. Pick and Load Local Video File (MP4, MKV, MOV, WebM)
  Future<bool> pickLocalFile({
    required String myIdentity,
    required Future<void> Function(String) sendDataFn,
  }) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.video,
        allowMultiple: false,
      );

      if (result == null || result.files.single.path == null) {
        return false;
      }

      final file = File(result.files.single.path!);
      final fileName = result.files.single.name;

      await _initLocalPlayer(file, fileName);

      // Broadcast to partner that we loaded this movie
      await sendDataFn(jsonEncode({
        'type': 'MEDIA_SYNC',
        'action': 'LOAD_LOCAL',
        'fileName': fileName,
        'sender': myIdentity,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      }));

      _pendingPartnerFileName = null;
      _showNotice('Loaded: $fileName');
      _startHeartbeat(myIdentity, sendDataFn);
      return true;
    } catch (e) {
      debugPrint('Error picking local video file: $e');
      return false;
    }
  }

  // Initialize Local Video Player
  Future<void> _initLocalPlayer(File file, String title) async {
    await _disposePlayers();

    _videoPlayerController = VideoPlayerController.file(file);
    await _videoPlayerController!.initialize();

    _mediaType = MediaSourceType.localFile;
    _currentTitle = title;
    _currentPathOrId = file.path;
    _totalDuration = _videoPlayerController!.value.duration;
    _isPlaying = false;

    _videoPlayerController!.addListener(_onLocalPlayerUpdate);
    notifyListeners();
  }

  void _onLocalPlayerUpdate() {
    if (_videoPlayerController == null) return;
    final value = _videoPlayerController!.value;
    _currentPosition = value.position;
    _totalDuration = value.duration;
    _isPlaying = value.isPlaying;
    notifyListeners();
  }

  // 2. Load YouTube URL
  Future<bool> loadYouTubeUrl(
    String url, {
    required String myIdentity,
    required Future<void> Function(String) sendDataFn,
    bool broadcast = true,
  }) async {
    try {
      final videoId = YoutubePlayer.convertUrlToId(url.trim());
      if (videoId == null) {
        _showNotice('Invalid YouTube URL');
        return false;
      }

      await _initYouTubePlayer(videoId, 'YouTube: $videoId');

      if (broadcast) {
        await sendDataFn(jsonEncode({
          'type': 'MEDIA_SYNC',
          'action': 'LOAD_YOUTUBE',
          'videoId': videoId,
          'title': 'YouTube Video',
          'sender': myIdentity,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        }));
      }

      _showNotice('Loaded YouTube video');
      _startHeartbeat(myIdentity, sendDataFn);
      return true;
    } catch (e) {
      debugPrint('Error loading YouTube URL: $e');
      return false;
    }
  }

  // Initialize YouTube Player
  Future<void> _initYouTubePlayer(String videoId, String title) async {
    await _disposePlayers();

    _youtubePlayerController = YoutubePlayerController(
      initialVideoId: videoId,
      flags: const YoutubePlayerFlags(
        autoPlay: false,
        mute: false,
        enableCaption: true,
        useHybridComposition: true,
      ),
    );

    _mediaType = MediaSourceType.youtube;
    _currentTitle = title;
    _currentPathOrId = videoId;
    _isPlaying = false;

    _youtubePlayerController!.addListener(_onYouTubePlayerUpdate);
    notifyListeners();
  }

  void _onYouTubePlayerUpdate() {
    if (_youtubePlayerController == null) return;
    final value = _youtubePlayerController!.value;
    _currentPosition = value.position;
    _totalDuration = _youtubePlayerController!.metadata.duration;
    _isPlaying = value.isPlaying;
    notifyListeners();
  }

  // 3. Play Action (Synchronized)
  Future<void> play({
    required String myIdentity,
    required Future<void> Function(String) sendDataFn,
    bool broadcast = true,
  }) async {
    if (_isApplyingRemoteSync) return;

    if (_mediaType == MediaSourceType.localFile) {
      await _videoPlayerController?.play();
    } else if (_mediaType == MediaSourceType.youtube) {
      _youtubePlayerController?.play();
    }
    _isPlaying = true;
    notifyListeners();

    if (broadcast) {
      await sendDataFn(jsonEncode({
        'type': 'MEDIA_SYNC',
        'action': 'PLAY',
        'positionMs': _currentPosition.inMilliseconds,
        'sender': myIdentity,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      }));
    }
  }

  // 4. Pause Action (Synchronized)
  Future<void> pause({
    required String myIdentity,
    required Future<void> Function(String) sendDataFn,
    bool broadcast = true,
  }) async {
    if (_isApplyingRemoteSync) return;

    if (_mediaType == MediaSourceType.localFile) {
      await _videoPlayerController?.pause();
    } else if (_mediaType == MediaSourceType.youtube) {
      _youtubePlayerController?.pause();
    }
    _isPlaying = false;
    notifyListeners();

    if (broadcast) {
      await sendDataFn(jsonEncode({
        'type': 'MEDIA_SYNC',
        'action': 'PAUSE',
        'positionMs': _currentPosition.inMilliseconds,
        'sender': myIdentity,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      }));
    }
  }

  // Toggle Play / Pause
  Future<void> togglePlayPause({
    required String myIdentity,
    required Future<void> Function(String) sendDataFn,
  }) async {
    if (_isPlaying) {
      await pause(myIdentity: myIdentity, sendDataFn: sendDataFn);
    } else {
      await play(myIdentity: myIdentity, sendDataFn: sendDataFn);
    }
  }

  // 5. Seek / Scrub Action (Synchronized)
  Future<void> seekTo(
    Duration targetPosition, {
    required String myIdentity,
    required Future<void> Function(String) sendDataFn,
    bool broadcast = true,
  }) async {
    if (_mediaType == MediaSourceType.localFile) {
      await _videoPlayerController?.seekTo(targetPosition);
    } else if (_mediaType == MediaSourceType.youtube) {
      _youtubePlayerController?.seekTo(targetPosition);
    }
    _currentPosition = targetPosition;
    notifyListeners();

    if (broadcast && !_isApplyingRemoteSync) {
      await sendDataFn(jsonEncode({
        'type': 'MEDIA_SYNC',
        'action': 'SEEK',
        'positionMs': targetPosition.inMilliseconds,
        'sender': myIdentity,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      }));
    }
  }

  // 6. Close Cinema Media
  Future<void> closeMedia({
    required String myIdentity,
    required Future<void> Function(String) sendDataFn,
    bool broadcast = true,
  }) async {
    await _disposePlayers();
    _mediaType = MediaSourceType.none;
    _currentTitle = null;
    _currentPathOrId = null;
    _isPlaying = false;
    _currentPosition = Duration.zero;
    _totalDuration = Duration.zero;
    _pendingPartnerFileName = null;
    _stopHeartbeat();
    notifyListeners();

    if (broadcast) {
      await sendDataFn(jsonEncode({
        'type': 'MEDIA_SYNC',
        'action': 'CLOSE',
        'sender': myIdentity,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      }));
    }
  }

  // 7. Receive and Process Remote Media Sync Packet from Partner
  Future<void> handleIncomingSyncMessage(
    String message,
    String myIdentity, {
    required Future<void> Function(String) sendDataFn,
  }) async {
    try {
      final data = jsonDecode(message);
      if (data is! Map<String, dynamic> || data['type'] != 'MEDIA_SYNC') return;

      final sender = data['sender'] as String? ?? 'Partner';
      if (sender == myIdentity) return; // Ignore our own echo

      final action = data['action'] as String?;
      final positionMs = data['positionMs'] as int? ?? 0;
      final targetDuration = Duration(milliseconds: positionMs);

      switch (action) {
        case 'LOAD_LOCAL':
          final fileName = data['fileName'] as String? ?? 'Movie';
          _pendingPartnerFileName = fileName;
          _showNotice('$sender loaded: $fileName. Tap 🎬 to pick your copy!');
          notifyListeners();
          break;

        case 'LOAD_YOUTUBE':
          final videoId = data['videoId'] as String?;
          if (videoId != null && videoId.isNotEmpty) {
            _pendingPartnerFileName = null;
            await _initYouTubePlayer(videoId, 'YouTube: $videoId');
            _showNotice('$sender loaded YouTube video ❤️');
          }
          break;

        case 'PLAY':
          _isApplyingRemoteSync = true;
          if (_mediaType == MediaSourceType.localFile) {
            await _videoPlayerController?.seekTo(targetDuration);
            await _videoPlayerController?.play();
          } else if (_mediaType == MediaSourceType.youtube) {
            _youtubePlayerController?.seekTo(targetDuration);
            _youtubePlayerController?.play();
          }
          _isPlaying = true;
          _currentPosition = targetDuration;
          _showNotice('Resumed by $sender ▶️');
          _isApplyingRemoteSync = false;
          notifyListeners();
          break;

        case 'PAUSE':
          _isApplyingRemoteSync = true;
          if (_mediaType == MediaSourceType.localFile) {
            await _videoPlayerController?.seekTo(targetDuration);
            await _videoPlayerController?.pause();
          } else if (_mediaType == MediaSourceType.youtube) {
            _youtubePlayerController?.seekTo(targetDuration);
            _youtubePlayerController?.pause();
          }
          _isPlaying = false;
          _currentPosition = targetDuration;
          _showNotice('Paused by $sender ⏸️');
          _isApplyingRemoteSync = false;
          notifyListeners();
          break;

        case 'SEEK':
          _isApplyingRemoteSync = true;
          if (_mediaType == MediaSourceType.localFile) {
            await _videoPlayerController?.seekTo(targetDuration);
          } else if (_mediaType == MediaSourceType.youtube) {
            _youtubePlayerController?.seekTo(targetDuration);
          }
          _currentPosition = targetDuration;
          _showNotice('Seeked by $sender ⏩');
          _isApplyingRemoteSync = false;
          notifyListeners();
          break;

        case 'HEARTBEAT':
          // Subtle drift correction (<250ms threshold)
          if (_isPlaying && hasMedia) {
            final drift = (_currentPosition.inMilliseconds - positionMs).abs();
            if (drift > 450) {
              _isApplyingRemoteSync = true;
              if (_mediaType == MediaSourceType.localFile) {
                await _videoPlayerController?.seekTo(targetDuration);
              } else if (_mediaType == MediaSourceType.youtube) {
                _youtubePlayerController?.seekTo(targetDuration);
              }
              _currentPosition = targetDuration;
              _isApplyingRemoteSync = false;
              notifyListeners();
            }
          }
          break;

        case 'CLOSE':
          await closeMedia(myIdentity: myIdentity, sendDataFn: sendDataFn, broadcast: false);
          _showNotice('$sender closed the cinema 🎬');
          break;
      }
    } catch (e) {
      debugPrint('Error handling incoming MEDIA_SYNC: $e');
    }
  }

  // Periodic heartbeat every 3 seconds to keep sub-second sync
  void _startHeartbeat(String myIdentity, Future<void> Function(String) sendDataFn) {
    _stopHeartbeat();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      if (_isPlaying && hasMedia) {
        await sendDataFn(jsonEncode({
          'type': 'MEDIA_SYNC',
          'action': 'HEARTBEAT',
          'positionMs': _currentPosition.inMilliseconds,
          'isPlaying': _isPlaying,
          'sender': myIdentity,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        }));
      }
    });
  }

  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  void _showNotice(String text) {
    _lastActionNotice = text;
    _noticeTimer?.cancel();
    _noticeTimer = Timer(const Duration(seconds: 4), () {
      _lastActionNotice = null;
      notifyListeners();
    });
    notifyListeners();
  }

  Future<void> _disposePlayers() async {
    if (_videoPlayerController != null) {
      _videoPlayerController!.removeListener(_onLocalPlayerUpdate);
      await _videoPlayerController!.dispose();
      _videoPlayerController = null;
    }
    if (_youtubePlayerController != null) {
      _youtubePlayerController!.removeListener(_onYouTubePlayerUpdate);
      _youtubePlayerController!.dispose();
      _youtubePlayerController = null;
    }
  }

  @override
  void dispose() {
    _stopHeartbeat();
    _noticeTimer?.cancel();
    _disposePlayers();
    super.dispose();
  }
}
