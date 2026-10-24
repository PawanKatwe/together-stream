import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:permission_handler/permission_handler.dart';

class LiveKitService extends ChangeNotifier {
  Room? _room;
  EventsListener<RoomEvent>? _listener;

  bool _isConnecting = false;
  bool _isConnected = false;
  String? _errorMessage;

  bool _isMicMuted = false;
  bool _isCameraMuted = false;
  CameraPosition _cameraPosition = CameraPosition.front;

  Room? get room => _room;
  bool get isConnecting => _isConnecting;
  bool get isConnected => _isConnected;
  String? get errorMessage => _errorMessage;
  bool get isMicMuted => _isMicMuted;
  bool get isCameraMuted => _isCameraMuted;
  CameraPosition get cameraPosition => _cameraPosition;

  LocalParticipant? get localParticipant => _room?.localParticipant;
  RemoteParticipant? get remoteParticipant => _room?.remoteParticipants.values.firstOrNull;

  VideoTrack? get localVideoTrack {
    final pubs = localParticipant?.videoTrackPublications;
    if (pubs == null || pubs.isEmpty) return null;
    // Prefer camera track (not screen share)
    for (final pub in pubs) {
      if (pub.source == TrackSource.camera && pub.track != null) {
        return pub.track as VideoTrack;
      }
    }
    return pubs.first.track as VideoTrack?;
  }

  VideoTrack? get remoteVideoTrack {
    final participant = remoteParticipant;
    if (participant == null) return null;
    final pubs = participant.videoTrackPublications;
    if (pubs.isEmpty) return null;
    for (final pub in pubs) {
      if (pub.source == TrackSource.camera && pub.track != null) {
        return pub.track as VideoTrack;
      }
    }
    return pubs.first.track as VideoTrack?;
  }

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

  // Request camera and microphone permissions explicitly
  Future<bool> requestPermissions() async {
    final cameraStatus = await Permission.camera.request();
    final micStatus = await Permission.microphone.request();

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

  // Leave room and clean up resources
  Future<void> disconnect() async {
    try {
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
      notifyListeners();
    }
  }

  @override
  void dispose() {
    disconnect();
    super.dispose();
  }
}
