import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_background/flutter_background.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:permission_handler/permission_handler.dart';

enum ScreenQualityPreset {
  p480('480p (Low Data)', 854, 480, 24, 800000, VideoParametersPresets.h540_169),
  p720('720p (Recommended)', 1280, 720, 30, 2500000, VideoParametersPresets.h720_169),
  p1080('1080p (Crisp HD)', 1920, 1080, 30, 4500000, VideoParametersPresets.h1080_169);

  final String label;
  final int width;
  final int height;
  final int frameRate;
  final int bitrate;
  final VideoParameters videoParameters;

  const ScreenQualityPreset(
    this.label,
    this.width,
    this.height,
    this.frameRate,
    this.bitrate,
    this.videoParameters,
  );
}

class LiveKitService extends ChangeNotifier {
  Room? _room;
  EventsListener<RoomEvent>? _listener;

  bool _isConnecting = false;
  bool _isConnected = false;
  String? _errorMessage;

  bool _isMicMuted = false;
  bool _isCameraMuted = false;
  bool _isScreenSharing = false;
  ScreenQualityPreset _currentQuality = ScreenQualityPreset.p720;
  CameraPosition _cameraPosition = CameraPosition.front;

  Room? get room => _room;
  bool get isConnecting => _isConnecting;
  bool get isConnected => _isConnected;
  String? get errorMessage => _errorMessage;
  bool get isMicMuted => _isMicMuted;
  bool get isCameraMuted => _isCameraMuted;
  bool get isScreenSharing => _isScreenSharing;
  ScreenQualityPreset get currentQuality => _currentQuality;
  CameraPosition get cameraPosition => _cameraPosition;

  LocalParticipant? get localParticipant => _room?.localParticipant;
  RemoteParticipant? get remoteParticipant => _room?.remoteParticipants.values.firstOrNull;

  // Local Camera Video Track
  VideoTrack? get localVideoTrack {
    final pubs = localParticipant?.videoTrackPublications;
    if (pubs == null || pubs.isEmpty) return null;
    for (final pub in pubs) {
      if (pub.source == TrackSource.camera && pub.track != null) {
        return pub.track as VideoTrack;
      }
    }
    return null;
  }

  // Local Screen Share Track
  VideoTrack? get localScreenShareTrack {
    final pubs = localParticipant?.videoTrackPublications;
    if (pubs == null) return null;
    for (final pub in pubs) {
      if (pub.source == TrackSource.screenShareVideo && pub.track != null) {
        return pub.track as VideoTrack;
      }
    }
    return null;
  }

  // Remote Camera Video Track
  VideoTrack? get remoteVideoTrack {
    final participant = remoteParticipant;
    if (participant == null) return null;
    for (final pub in participant.videoTrackPublications) {
      if (pub.source == TrackSource.camera && pub.track != null) {
        return pub.track as VideoTrack;
      }
    }
    return null;
  }

  // Remote Screen Share Video Track
  VideoTrack? get remoteScreenShareTrack {
    final participant = remoteParticipant;
    if (participant == null) return null;
    for (final pub in participant.videoTrackPublications) {
      if (pub.source == TrackSource.screenShareVideo && pub.track != null) {
        return pub.track as VideoTrack;
      }
    }
    return null;
  }

  // Any screen share active (either I am sharing or partner is sharing)
  bool get isAnyScreenShareActive => _isScreenSharing || remoteScreenShareTrack != null;

  // Active Screen Share Track to display
  VideoTrack? get activeScreenShareTrack {
    return remoteScreenShareTrack ?? localScreenShareTrack;
  }

  // Who is currently sharing
  String? get activeSharerName {
    if (_isScreenSharing) return localParticipant?.name ?? 'You';
    if (remoteScreenShareTrack != null) return remoteParticipant?.name ?? 'Partner';
    return null;
  }

  // Request permissions explicitly
  Future<bool> requestPermissions() async {
    final cameraStatus = await Permission.camera.request();
    final micStatus = await Permission.microphone.request();

    // Android 13+ requires notification permission for foreground services
    if (await Permission.notification.isRestricted || await Permission.notification.isDenied) {
      await Permission.notification.request();
    }

    if (!cameraStatus.isGranted || !micStatus.isGranted) {
      _errorMessage = 'Camera and Microphone permissions are required to start the video call.';
      notifyListeners();
      return false;
    }
    return true;
  }

  // Connect to the room
  Future<void> connect({
    required String url,
    required String token,
  }) async {
    _isConnecting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final hasPermissions = await requestPermissions();
      if (!hasPermissions) {
        _isConnecting = false;
        notifyListeners();
        return;
      }

      final roomOptions = RoomOptions(
        adaptiveStream: true,
        dynacast: true,
        defaultCameraCaptureOptions: const CameraCaptureOptions(
          maxFrameRate: 30,
          params: VideoParametersPresets.h720_169,
        ),
      );

      _room = Room(roomOptions: roomOptions);
      _listener = _room!.createListener();

      _setupListeners();

      await _room!.connect(url, token);

      // Enable local camera and mic
      await _room!.localParticipant?.setCameraEnabled(true);
      await _room!.localParticipant?.setMicrophoneEnabled(true);

      _isConnected = true;
      _isConnecting = false;
      notifyListeners();
    } catch (e) {
      _isConnecting = false;
      _isConnected = false;
      _errorMessage = 'Connection failed: ${e.toString()}';
      notifyListeners();
      await disconnect();
    }
  }

  void _setupListeners() {
    _listener
      ?..on<RoomConnectedEvent>((_) {
        _isConnected = true;
        notifyListeners();
      })
      ..on<RoomDisconnectedEvent>((_) {
        _isConnected = false;
        _isScreenSharing = false;
        notifyListeners();
      })
      ..on<ParticipantConnectedEvent>((_) {
        notifyListeners();
      })
      ..on<ParticipantDisconnectedEvent>((_) {
        notifyListeners();
      })
      ..on<TrackSubscribedEvent>((_) {
        notifyListeners();
      })
      ..on<TrackUnsubscribedEvent>((_) {
        notifyListeners();
      })
      ..on<TrackMutedEvent>((_) {
        notifyListeners();
      })
      ..on<TrackUnmutedEvent>((_) {
        notifyListeners();
      })
      ..on<LocalTrackPublishedEvent>((_) {
        notifyListeners();
      })
      ..on<LocalTrackUnpublishedEvent>((_) {
        notifyListeners();
      });
  }

  // Toggle Microphone
  Future<void> toggleMicrophone() async {
    if (_room?.localParticipant == null) return;
    try {
      _isMicMuted = !_isMicMuted;
      await _room!.localParticipant!.setMicrophoneEnabled(!_isMicMuted);
      notifyListeners();
    } catch (e) {
      debugPrint('Error toggling mic: $e');
    }
  }

  // Toggle Camera
  Future<void> toggleCamera() async {
    if (_room?.localParticipant == null) return;
    try {
      _isCameraMuted = !_isCameraMuted;
      await _room!.localParticipant!.setCameraEnabled(!_isCameraMuted);
      notifyListeners();
    } catch (e) {
      debugPrint('Error toggling camera: $e');
    }
  }

  // Switch Front / Back Camera
  Future<void> switchCamera() async {
    final track = localVideoTrack;
    if (track is! LocalVideoTrack) return;

    try {
      _cameraPosition = (_cameraPosition == CameraPosition.front)
          ? CameraPosition.back
          : CameraPosition.front;

      await track.restartTrack(
        CameraCaptureOptions(
          cameraPosition: _cameraPosition,
          maxFrameRate: 30,
          params: VideoParametersPresets.h720_169,
        ),
      );
      notifyListeners();
    } catch (e) {
      debugPrint('Error switching camera: $e');
    }
  }

  // Start Screen Share with System Audio (AudioPlaybackCapture)
  Future<bool> startScreenShare({ScreenQualityPreset? preset}) async {
    final participant = _room?.localParticipant;
    if (participant == null) return false;

    if (preset != null) {
      _currentQuality = preset;
    }

    try {
      if (Platform.isAndroid) {
        // 1. Ensure notification permission is requested
        await Permission.notification.request();

        // 2. Request Android MediaProjection capture permission FIRST
        // This prompts the system dialog "Start recording or casting with TogetherStream?"
        final bool hasCapturePermission = await Helper.requestCapturePermission();
        if (!hasCapturePermission) {
          debugPrint('User cancelled Android screen capture permission');
          return false;
        }

        // 3. Initialize and enable Android 14 compliant Foreground Service with mediaProjection
        const androidConfig = FlutterBackgroundAndroidConfig(
          notificationTitle: 'TogetherStream Cinema',
          notificationText: 'Sharing screen and movie audio with your partner...',
          notificationImportance: AndroidNotificationImportance.normal,
          notificationIcon: AndroidResource(name: 'ic_launcher', defType: 'drawable'),
        );

        final bool hasBgPermissions = await FlutterBackground.initialize(androidConfig: androidConfig);
        if (hasBgPermissions && !FlutterBackground.isBackgroundExecutionEnabled) {
          await FlutterBackground.enableBackgroundExecution();
        }
      }

      final captureOptions = ScreenShareCaptureOptions(
        captureScreenAudio: true, // Enables system audio capture for movie sound
        params: _currentQuality.videoParameters,
      );

      await participant.setScreenShareEnabled(
        true,
        captureScreenAudio: true,
        screenShareCaptureOptions: captureOptions,
      );

      _isScreenSharing = true;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error starting screen share: $e');
      if (Platform.isAndroid && FlutterBackground.isBackgroundExecutionEnabled) {
        await FlutterBackground.disableBackgroundExecution();
      }
      _isScreenSharing = false;
      notifyListeners();
      return false;
    }
  }

  // Stop Screen Share
  Future<void> stopScreenShare() async {
    final participant = _room?.localParticipant;
    if (participant == null) return;

    try {
      await participant.setScreenShareEnabled(false);
    } catch (e) {
      debugPrint('Error stopping screen share: $e');
    } finally {
      if (Platform.isAndroid && FlutterBackground.isBackgroundExecutionEnabled) {
        await FlutterBackground.disableBackgroundExecution();
      }
      _isScreenSharing = false;
      notifyListeners();
    }
  }

  // Toggle Screen Share
  Future<void> toggleScreenShare() async {
    if (_isScreenSharing) {
      await stopScreenShare();
    } else {
      await startScreenShare();
    }
  }

  // Change Screen Quality Preset
  Future<void> setQualityPreset(ScreenQualityPreset newPreset) async {
    _currentQuality = newPreset;
    notifyListeners();
    if (_isScreenSharing) {
      // Restart screen share with new quality parameters
      await startScreenShare(preset: newPreset);
    }
  }

  // Leave room and clean up resources
  Future<void> disconnect() async {
    try {
      if (_isScreenSharing) {
        await stopScreenShare();
      }
      _listener?.dispose();
      await _room?.disconnect();
      await _room?.dispose();
    } catch (e) {
      debugPrint('Error during disconnect: $e');
    } finally {
      _room = null;
      _listener = null;
      _isConnected = false;
      _isConnecting = false;
      _isMicMuted = false;
      _isCameraMuted = false;
      _isScreenSharing = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    disconnect();
    super.dispose();
  }
}
