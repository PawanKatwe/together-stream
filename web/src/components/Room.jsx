import React, { useEffect, useState, useRef, useCallback } from 'react';
import { Room as LKRoom, RoomEvent, Track } from 'livekit-client';
import VideoTile from './VideoTile';
import ControlBar from './ControlBar';
import EchoWarningBanner from './EchoWarningBanner';
import CinemaPlayer from './CinemaPlayer';
import { FloatingEmojiOverlay, ReactionPicker } from './FloatingEmojis';
import { InMovieChatOverlay, InMovieChatModal } from './InMovieChat';
import SnapshotModal from './SnapshotModal';
import MovieMenuModal from './MovieMenuModal';

export default function Room({ connectionConfig, onLeave }) {
  const [room, setRoom] = useState(null);
  const [isConnecting, setIsConnecting] = useState(true);
  const [error, setError] = useState(null);

  // Local Tracks
  const [localVideoTrack, setLocalVideoTrack] = useState(null);
  const [isMicMuted, setIsMicMuted] = useState(false);
  const [isCameraMuted, setIsCameraMuted] = useState(false);
  const [isScreenSharing, setIsScreenSharing] = useState(false);
  const [hasMultipleCameras, setHasMultipleCameras] = useState(false);
  const [activeCameraId, setActiveCameraId] = useState(null);

  // Remote Tracks & Participants
  const [remoteParticipants, setRemoteParticipants] = useState([]);
  const [screenShareTrack, setScreenShareTrack] = useState(null);
  const [screenSharerName, setScreenSharerName] = useState(null);

  // In-App Cinema & Media Sync States
  const [localMediaFile, setLocalMediaFile] = useState(null);
  const [youtubeVideoId, setYoutubeVideoId] = useState(null);
  const [isMediaPlaying, setIsMediaPlaying] = useState(false);
  const [mediaCurrentTime, setMediaCurrentTime] = useState(0);
  const [mediaDuration, setMediaDuration] = useState(0);
  const [pendingPartnerFileName, setPendingPartnerFileName] = useState(null);

  // Romantic Features: Emojis, Chat, Keepsakes
  const [floatingEmojiBursts, setFloatingEmojiBursts] = useState([]);
  const [showReactionPicker, setShowReactionPicker] = useState(false);
  const [chatMessages, setChatMessages] = useState([]);
  const [showChatModal, setShowChatModal] = useState(false);
  const [snapshotDataUrl, setSnapshotDataUrl] = useState(null);
  const [showMovieMenu, setShowMovieMenu] = useState(false);
  const [toastNotice, setToastNotice] = useState(null);

  // UI & Timer States
  const [showControls, setShowControls] = useState(true);
  const [isVideoStripVisible, setIsVideoStripVisible] = useState(true);
  const [isFullscreen, setIsFullscreen] = useState(false);
  const [callDuration, setCallDuration] = useState(0);
  const hideControlsTimer = useRef(null);
  const containerRef = useRef(null);

  const partnerName = connectionConfig.identity.includes('Pawan') ? 'Priya' : 'Pawan';

  // Broadcast data channel packet to partner
  const sendDataMessage = useCallback(
    async (obj) => {
      if (!room || !room.localParticipant) return;
      try {
        const payload = new TextEncoder().encode(JSON.stringify(obj));
        await room.localParticipant.publishData(payload, { reliable: true });
      } catch (err) {
        console.error('Failed to send data channel message:', err);
      }
    },
    [room]
  );

  const showToast = (text) => {
    setToastNotice(text);
    setTimeout(() => {
      setToastNotice((curr) => (curr === text ? null : curr));
    }, 3800);
  };

  const spawnEmojiBurst = (emoji) => {
    const newItems = [];
    for (let i = 0; i < 4; i++) {
      newItems.push({
        id: `${Date.now()}_${i}_${Math.random()}`,
        emoji,
        startX: Math.max(0.15, Math.min(0.85, 0.5 + (Math.random() - 0.5) * 0.45)),
        sway: (Math.random() - 0.5) * 60,
        scale: 0.85 + Math.random() * 0.4,
      });
    }
    setFloatingEmojiBursts((prev) => [...prev, ...newItems]);

    setTimeout(() => {
      setFloatingEmojiBursts((prev) => prev.filter((item) => !newItems.includes(item)));
    }, 2600);
  };

  const handleSendEmoji = (emoji) => {
    spawnEmojiBurst(emoji);
    sendDataMessage({
      type: 'EMOJI_REACTION',
      emoji,
      sender: connectionConfig.identity,
      timestamp: Date.now(),
    });
  };

  const handleSendChatMessage = (text) => {
    const msg = {
      id: `${Date.now()}_${Math.random()}`,
      sender: connectionConfig.identity,
      text,
      isMe: true,
      timestamp: Date.now(),
    };
    setChatMessages((prev) => [...prev, msg]);
    setTimeout(() => {
      setChatMessages((prev) => prev.filter((m) => m.id !== msg.id));
    }, 8000);

    sendDataMessage({
      type: 'CHAT_MESSAGE',
      text,
      sender: connectionConfig.identity,
      timestamp: Date.now(),
    });
  };

  const resetControlsTimer = () => {
    setShowControls(true);
    if (hideControlsTimer.current) clearTimeout(hideControlsTimer.current);
    if (isMediaPlaying || isScreenSharing) {
      hideControlsTimer.current = setTimeout(() => {
        setShowControls(false);
      }, 3500);
    }
  };

  // Call duration stopwatch
  useEffect(() => {
    if (!room) return;
    const interval = setInterval(() => {
      setCallDuration((d) => d + 1);
    }, 1000);
    return () => clearInterval(interval);
  }, [room]);

  const formatDuration = (seconds) => {
    const twoDigits = (n) => String(n).padStart(2, '0');
    const h = Math.floor(seconds / 3600);
    const m = Math.floor((seconds % 3600) / 60);
    const s = seconds % 60;
    if (h > 0) return `${h}:${twoDigits(m)}:${twoDigits(s)}`;
    return `${twoDigits(m)}:${twoDigits(s)}`;
  };

  // Check multiple cameras (Tablets / Laptops)
  useEffect(() => {
    async function checkCameras() {
      try {
        if (!navigator.mediaDevices?.enumerateDevices) return;
        const devices = await navigator.mediaDevices.enumerateDevices();
        const videoDevices = devices.filter((d) => d.kind === 'videoinput');
        setHasMultipleCameras(videoDevices.length > 1);
      } catch (e) {
        console.error('Error checking cameras:', e);
      }
    }
    checkCameras();
  }, []);

  // Main LiveKit Initialization
  useEffect(() => {
    const lkRoom = new LKRoom({
      adaptiveStream: true,
      dynacast: true,
    });

    async function initRoom() {
      try {
        setIsConnecting(true);
        // 1. Fetch Token from server
        const res = await fetch(`${connectionConfig.serverUrl}/token`, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            identity: connectionConfig.identity,
            passcode: connectionConfig.passcode,
          }),
        });

        if (!res.ok) {
          const errData = await res.json().catch(() => ({}));
          throw new Error(errData.error || `Server responded with ${res.status}`);
        }

        const data = await res.json();

        // 2. Connect to LiveKit Room
        await lkRoom.connect(data.url, data.token);

        // 3. Publish initial camera & mic
        await lkRoom.localParticipant.enableCameraAndMicrophone();

        setRoom(lkRoom);
        setIsConnecting(false);
        updateTracks(lkRoom);
      } catch (err) {
        console.error('Connection failed:', err);
        setError(err.message || 'Failed to connect to cinema room');
        setIsConnecting(false);
      }
    }

    function updateTracks(r) {
      if (!r) return;

      // Update Local Video Track
      const localPub = Array.from(r.localParticipant.videoTrackPublications.values()).find(
        (p) => p.source === Track.Source.Camera
      );
      setLocalVideoTrack(localPub ? localPub.track : null);

      // Check Local Screen Share Track
      const localScreenPub = Array.from(r.localParticipant.videoTrackPublications.values()).find(
        (p) => p.source === Track.Source.ScreenShare
      );
      if (localScreenPub && localScreenPub.track) {
        setScreenShareTrack(localScreenPub.track);
        setScreenSharerName(r.localParticipant.name || 'You');
        setIsScreenSharing(true);
      }

      // Check Remote Screen Share Tracks
      let foundRemoteScreen = false;
      const remotes = Array.from(r.remoteParticipants.values());
      setRemoteParticipants(remotes);

      for (const p of remotes) {
        const screenPub = Array.from(p.videoTrackPublications.values()).find(
          (pub) => pub.source === Track.Source.ScreenShare
        );
        if (screenPub && screenPub.track) {
          setScreenShareTrack(screenPub.track);
          setScreenSharerName(p.name || p.identity || 'Partner');
          foundRemoteScreen = true;
          break;
        }
      }

      if (!localScreenPub && !foundRemoteScreen) {
        setScreenShareTrack(null);
        setScreenSharerName(null);
        setIsScreenSharing(false);
      }
    }

    // Handle incoming data channel packets
    const handleDataReceived = (payload, participant) => {
      try {
        const str = new TextDecoder().decode(payload);
        const data = JSON.parse(str);
        const sender = data.sender || participant?.identity || partnerName;

        if (data.type === 'EMOJI_REACTION') {
          spawnEmojiBurst(data.emoji || '❤️');
        } else if (data.type === 'CHAT_MESSAGE') {
          const msg = {
            id: `${Date.now()}_${Math.random()}`,
            sender,
            text: data.text || '',
            isMe: false,
            timestamp: Date.now(),
          };
          setChatMessages((prev) => [...prev, msg]);
          setTimeout(() => {
            setChatMessages((prev) => prev.filter((m) => m.id !== msg.id));
          }, 8000);
        } else if (data.type === 'SNAPSHOT_TAKEN') {
          showToast(`📸 ${sender} captured a keepsake moment with you! ❤️`);
        } else if (data.type === 'MEDIA_SYNC') {
          handleMediaSyncPacket(data, sender);
        }
      } catch (e) {
        console.error('Error handling data channel message:', e);
      }
    };

    function handleMediaSyncPacket(data, sender) {
      const action = data.action;
      const posSec = (data.positionMs || 0) / 1000;

      switch (action) {
        case 'LOAD_LOCAL':
          setPendingPartnerFileName(data.fileName || 'Movie');
          showToast(`🎬 ${sender} loaded: ${data.fileName}. Tap 🎬 to pick your copy!`);
          break;
        case 'LOAD_YOUTUBE':
          setPendingPartnerFileName(null);
          setYoutubeVideoId(data.videoId);
          setIsMediaPlaying(true);
          showToast(`🎬 ${sender} loaded YouTube video ❤️`);
          break;
        case 'PLAY':
          setIsMediaPlaying(true);
          setMediaCurrentTime(posSec);
          showToast(`Resumed by ${sender} ▶️`);
          break;
        case 'PAUSE':
          setIsMediaPlaying(false);
          setMediaCurrentTime(posSec);
          showToast(`Paused by ${sender} ⏸️`);
          break;
        case 'SEEK':
          setMediaCurrentTime(posSec);
          showToast(`Seeked by ${sender} ⏩`);
          break;
        case 'HEARTBEAT':
          if (Math.abs(mediaCurrentTime - posSec) > 0.6) {
            setMediaCurrentTime(posSec);
          }
          break;
        case 'CLOSE':
          setLocalMediaFile(null);
          setYoutubeVideoId(null);
          setIsMediaPlaying(false);
          setPendingPartnerFileName(null);
          showToast(`Cinema closed by ${sender} 🎬`);
          break;
        default:
          break;
      }
    }

    lkRoom
      .on(RoomEvent.ParticipantConnected, () => updateTracks(lkRoom))
      .on(RoomEvent.ParticipantDisconnected, () => updateTracks(lkRoom))
      .on(RoomEvent.TrackSubscribed, () => updateTracks(lkRoom))
      .on(RoomEvent.TrackUnsubscribed, () => updateTracks(lkRoom))
      .on(RoomEvent.LocalTrackPublished, () => updateTracks(lkRoom))
      .on(RoomEvent.LocalTrackUnpublished, () => updateTracks(lkRoom))
      .on(RoomEvent.TrackMuted, () => updateTracks(lkRoom))
      .on(RoomEvent.TrackUnmuted, () => updateTracks(lkRoom))
      .on(RoomEvent.DataReceived, handleDataReceived);

    initRoom();
    resetControlsTimer();

    return () => {
      if (hideControlsTimer.current) clearTimeout(hideControlsTimer.current);
      lkRoom.disconnect();
    };
  }, [connectionConfig, partnerName]);

  // Controls Handlers
  const toggleMic = async () => {
    if (!room) return;
    const muted = !isMicMuted;
    setIsMicMuted(muted);
    await room.localParticipant.setMicrophoneEnabled(!muted);
  };

  const toggleCamera = async () => {
    if (!room) return;
    const muted = !isCameraMuted;
    setIsCameraMuted(muted);
    await room.localParticipant.setCameraEnabled(!muted);
  };

  const flipCamera = async () => {
    if (!room || !navigator.mediaDevices?.enumerateDevices) return;
    try {
      const devices = await navigator.mediaDevices.enumerateDevices();
      const videoDevices = devices.filter((d) => d.kind === 'videoinput');
      if (videoDevices.length <= 1) return;

      const nextDevice = videoDevices.find((d) => d.deviceId !== activeCameraId) || videoDevices[0];
      if (nextDevice) {
        await room.localParticipant.setCameraEnabled(false);
        await room.localParticipant.setCameraEnabled(true, {
          deviceId: nextDevice.deviceId,
        });
        setActiveCameraId(nextDevice.deviceId);
        showToast('Switched Camera 🔄');
      }
    } catch (err) {
      console.error('Failed to flip camera:', err);
    }
  };

  const toggleScreenShare = async () => {
    if (!room) return;
    try {
      if (isScreenSharing) {
        await room.localParticipant.setScreenShareEnabled(false);
        setIsScreenSharing(false);
      } else {
        await room.localParticipant.setScreenShareEnabled(true, {
          audio: true, // Captures tab audio for movie watch parties
          resolution: { width: 1920, height: 1080, frameRate: 30 },
        });
        setIsScreenSharing(true);
      }
    } catch (err) {
      console.error('Screen sharing error:', err);
    }
  };

  const toggleFullscreen = () => {
    if (!document.fullscreenElement) {
      document.documentElement.requestFullscreen().catch(() => {});
      setIsFullscreen(true);
    } else {
      document.exitFullscreen().catch(() => {});
      setIsFullscreen(false);
    }
  };

  // Cinema Media Controls
  const handleSelectLocalFile = (fileObj) => {
    setLocalMediaFile(fileObj);
    setYoutubeVideoId(null);
    setIsMediaPlaying(true);
    setPendingPartnerFileName(null);

    sendDataMessage({
      type: 'MEDIA_SYNC',
      action: 'LOAD_LOCAL',
      fileName: fileObj.name,
      sender: connectionConfig.identity,
      timestamp: Date.now(),
    });
  };

  const handleSelectYouTube = (videoId) => {
    setYoutubeVideoId(videoId);
    setLocalMediaFile(null);
    setIsMediaPlaying(true);
    setPendingPartnerFileName(null);

    sendDataMessage({
      type: 'MEDIA_SYNC',
      action: 'LOAD_YOUTUBE',
      videoId,
      sender: connectionConfig.identity,
      timestamp: Date.now(),
    });
  };

  const handlePlayPauseMedia = () => {
    const nextPlaying = !isMediaPlaying;
    setIsMediaPlaying(nextPlaying);
    sendDataMessage({
      type: 'MEDIA_SYNC',
      action: nextPlaying ? 'PLAY' : 'PAUSE',
      positionMs: Math.floor(mediaCurrentTime * 1000),
      sender: connectionConfig.identity,
      timestamp: Date.now(),
    });
  };

  const handleSeekMedia = (newTimeSec) => {
    setMediaCurrentTime(newTimeSec);
    sendDataMessage({
      type: 'MEDIA_SYNC',
      action: 'SEEK',
      positionMs: Math.floor(newTimeSec * 1000),
      sender: connectionConfig.identity,
      timestamp: Date.now(),
    });
  };

  const handleCloseMedia = () => {
    setLocalMediaFile(null);
    setYoutubeVideoId(null);
    setIsMediaPlaying(false);
    sendDataMessage({
      type: 'MEDIA_SYNC',
      action: 'CLOSE',
      sender: connectionConfig.identity,
      timestamp: Date.now(),
    });
  };

  // Snapshot Capture
  const handleTakeSnapshot = () => {
    try {
      // Find visible video element
      const videos = Array.from(document.querySelectorAll('video'));
      const activeVideo = videos.find((v) => v.videoWidth > 0 && !v.paused) || videos[0];

      if (!activeVideo) {
        showToast('No active video stream found to snapshot');
        return;
      }

      const canvas = document.createElement('canvas');
      canvas.width = activeVideo.videoWidth || 1280;
      canvas.height = activeVideo.videoHeight || 720;
      const ctx = canvas.getContext('2d');
      ctx.drawImage(activeVideo, 0, 0, canvas.width, canvas.height);

      const dataUrl = canvas.toDataURL('image/png');
      setSnapshotDataUrl(dataUrl);

      sendDataMessage({
        type: 'SNAPSHOT_TAKEN',
        sender: connectionConfig.identity,
        timestamp: Date.now(),
      });
    } catch (e) {
      console.error('Snapshot failed:', e);
      showToast('Could not capture frame');
    }
  };

  const isAnyMediaOrScreenActive = screenShareTrack !== null || localMediaFile !== null || youtubeVideoId !== null;

  if (isConnecting) {
    return (
      <div
        style={{
          width: '100vw',
          height: '100vh',
          display: 'flex',
          flexDirection: 'column',
          alignItems: 'center',
          justifyContent: 'center',
          backgroundColor: '#121013',
          gap: '16px',
        }}
      >
        <div
          className="pulse"
          style={{
            width: '60px',
            height: '60px',
            borderRadius: '50%',
            backgroundColor: 'rgba(226, 132, 156, 0.2)',
            border: '2px solid #E2849C',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            fontSize: '26px',
          }}
        >
          ❤️
        </div>
        <div style={{ fontSize: '16px', fontWeight: 'bold', color: '#F7A8BE' }}>
          Connecting to Cinema Room PP...
        </div>
        <div style={{ fontSize: '13px', color: '#9CA3AF' }}>Identity: {connectionConfig.identity}</div>
      </div>
    );
  }

  if (error) {
    return (
      <div
        style={{
          width: '100vw',
          height: '100vh',
          display: 'flex',
          flexDirection: 'column',
          alignItems: 'center',
          justifyContent: 'center',
          backgroundColor: '#121013',
          gap: '16px',
          padding: '24px',
        }}
      >
        <div style={{ fontSize: '36px' }}>⚠️</div>
        <div style={{ fontSize: '18px', fontWeight: 'bold', color: '#EF4444' }}>Connection Error</div>
        <div style={{ fontSize: '14px', color: '#D1D5DB', maxWidth: '400px', textAlign: 'center' }}>
          {error}
        </div>
        <button
          onClick={onLeave}
          style={{
            marginTop: '12px',
            padding: '10px 22px',
            backgroundColor: '#E2849C',
            color: '#FFFFFF',
            borderRadius: '14px',
            fontWeight: '600',
          }}
        >
          Return to Setup
        </button>
      </div>
    );
  }

  return (
    <div
      ref={containerRef}
      onMouseMove={resetControlsTimer}
      onClick={resetControlsTimer}
      style={{
        width: '100vw',
        height: '100vh',
        backgroundColor: '#000000',
        display: 'flex',
        flexDirection: 'column',
        position: 'relative',
        overflow: 'hidden',
      }}
    >
      {/* Echo Warning Banner for Laptop Tab Audio */}
      <EchoWarningBanner isSharingAudio={isScreenSharing} />

      {/* Floating Emoji Reactions Overlay */}
      <FloatingEmojiOverlay emojiBursts={floatingEmojiBursts} />

      {/* In-Movie Chat Overlay */}
      <InMovieChatOverlay messages={chatMessages} />

      {/* Toast Notification Banner */}
      {toastNotice && (
        <div
          className="fade-in"
          style={{
            position: 'absolute',
            top: '80px',
            left: '50%',
            transform: 'translateX(-50%)',
            backgroundColor: 'rgba(29, 23, 30, 0.95)',
            border: '1.5px solid #E2849C',
            borderRadius: '20px',
            padding: '10px 20px',
            color: '#FFFFFF',
            fontSize: '13px',
            fontWeight: '600',
            boxShadow: '0 8px 24px rgba(0, 0, 0, 0.6)',
            zIndex: 80,
            pointerEvents: 'none',
          }}
        >
          {toastNotice}
        </div>
      )}

      {/* Top Header Status Bar */}
      <div
        style={{
          position: 'absolute',
          top: showControls ? '16px' : '-65px',
          left: '20px',
          right: '20px',
          display: 'flex',
          justifyContent: 'space-between',
          alignItems: 'center',
          zIndex: 40,
          transition: 'top 0.28s ease',
          pointerEvents: showControls ? 'auto' : 'none',
        }}
      >
        {/* Left: Identity Pill */}
        <div
          style={{
            backgroundColor: 'rgba(29, 23, 30, 0.88)',
            backdropFilter: 'blur(8px)',
            padding: '6px 14px',
            borderRadius: '20px',
            border: '1px solid rgba(226, 132, 156, 0.3)',
            display: 'flex',
            alignItems: 'center',
            gap: '8px',
            fontSize: '12px',
            fontWeight: '600',
            color: '#FFFFFF',
          }}
        >
          <span>❤️</span>
          <span>
            Room PP • {connectionConfig.identity}
          </span>
        </div>

        {/* Right: Stopwatch Timer & Live Badge */}
        <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
          {/* Stopwatch Call Duration */}
          <div
            style={{
              backgroundColor: 'rgba(29, 23, 30, 0.88)',
              backdropFilter: 'blur(8px)',
              padding: '6px 12px',
              borderRadius: '16px',
              border: '1px solid rgba(226, 132, 156, 0.35)',
              color: '#FFFFFF',
              fontSize: '12px',
              fontWeight: 'bold',
              display: 'flex',
              alignItems: 'center',
              gap: '6px',
            }}
          >
            <span>⏱️</span>
            <span>{formatDuration(callDuration)}</span>
          </div>

          {/* Mode Indicator */}
          <div
            style={{
              backgroundColor: isAnyMediaOrScreenActive
                ? 'rgba(226, 132, 156, 0.2)'
                : 'rgba(16, 185, 129, 0.2)',
              border: `1px solid ${
                isAnyMediaOrScreenActive ? 'rgba(226, 132, 156, 0.5)' : 'rgba(16, 185, 129, 0.4)'
              }`,
              borderRadius: '14px',
              padding: '5px 12px',
              color: isAnyMediaOrScreenActive ? '#F7A8BE' : '#34D399',
              fontSize: '11px',
              fontWeight: 'bold',
              display: 'flex',
              alignItems: 'center',
              gap: '6px',
            }}
          >
            <span
              style={{
                width: '6px',
                height: '6px',
                borderRadius: '50%',
                backgroundColor: isAnyMediaOrScreenActive ? '#E2849C' : '#34D399',
              }}
            />
            <span>{isAnyMediaOrScreenActive ? 'Cinema' : 'Live Call'}</span>
          </div>
        </div>
      </div>

      {/* Main Video Viewport */}
      {isAnyMediaOrScreenActive ? (
        // Mode 1: Cinema Layout (Top ~80% movie/screen + Bottom ~20% video strip)
        <div style={{ flex: 1, display: 'flex', flexDirection: 'column', height: '100%' }}>
          {/* Main Cinema Player */}
          <div style={{ flex: 1, position: 'relative', overflow: 'hidden' }}>
            <CinemaPlayer
              screenShareTrack={screenShareTrack}
              sharerName={screenSharerName}
              localMediaFile={localMediaFile}
              youtubeVideoId={youtubeVideoId}
              isMediaPlaying={isMediaPlaying}
              mediaCurrentTime={mediaCurrentTime}
              mediaDuration={mediaDuration}
              onPlayPause={handlePlayPauseMedia}
              onSeek={handleSeekMedia}
              onCloseMedia={handleCloseMedia}
              onPickLocalFile={() => setShowMovieMenu(true)}
              pendingPartnerFileName={pendingPartnerFileName}
            />
          </div>

          {/* Bottom Video Strip for Both Faces */}
          <div
            style={{
              height: isVideoStripVisible ? '135px' : '0px',
              transition: 'height 0.28s ease',
              backgroundColor: '#1D171E',
              borderTop: isVideoStripVisible ? '1px solid #28202A' : 'none',
              display: 'flex',
              alignItems: 'center',
              gap: '10px',
              padding: isVideoStripVisible ? '8px 14px' : '0',
              overflow: 'hidden',
            }}
          >
            <div style={{ flex: 1, height: '100%' }}>
              <VideoTile
                title={connectionConfig.identity}
                track={localVideoTrack}
                isMuted={isMicMuted}
                isLocal={true}
              />
            </div>

            {remoteParticipants.length > 0 ? (
              remoteParticipants.map((p) => {
                const pub = Array.from(p.videoTrackPublications.values()).find(
                  (v) => v.source === Track.Source.Camera
                );
                return (
                  <div key={p.identity} style={{ flex: 1, height: '100%' }}>
                    <VideoTile
                      title={p.name || p.identity}
                      track={pub ? pub.track : null}
                      isMuted={p.isMuted}
                      isLocal={false}
                    />
                  </div>
                );
              })
            ) : (
              <div
                style={{
                  flex: 1,
                  height: '100%',
                  backgroundColor: '#121013',
                  borderRadius: '14px',
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                  color: '#9CA3AF',
                  fontSize: '12px',
                  border: '1px dashed #374151',
                }}
              >
                Waiting for mobile partner to join...
              </div>
            )}
          </div>
        </div>
      ) : (
        // Mode 2: Call-Only Layout (Responsive Side-by-Side on Desktop/Tablet Landscape, Stacked on Tablet Portrait)
        <div
          style={{
            flex: 1,
            display: 'grid',
            gridTemplateColumns: 'repeat(auto-fit, minmax(280px, 1fr))',
            gap: '12px',
            padding: '12px',
            height: '100%',
          }}
        >
          <VideoTile
            title={connectionConfig.identity}
            track={localVideoTrack}
            isMuted={isMicMuted}
            isLocal={true}
          />
          {remoteParticipants.length > 0 ? (
            <VideoTile
              title={remoteParticipants[0].name || remoteParticipants[0].identity}
              track={
                Array.from(remoteParticipants[0].videoTrackPublications.values()).find(
                  (v) => v.source === Track.Source.Camera
                )?.track
              }
              isMuted={remoteParticipants[0].isMuted}
              isLocal={false}
            />
          ) : (
            <div
              style={{
                backgroundColor: '#1D171E',
                borderRadius: '16px',
                display: 'flex',
                flexDirection: 'column',
                alignItems: 'center',
                justifyContent: 'center',
                gap: '12px',
                border: '1px solid #28202A',
              }}
            >
              <div style={{ fontSize: '32px' }}>❤️</div>
              <div style={{ fontSize: '15px', color: '#F7A8BE', fontWeight: '600' }}>
                Waiting for partner to join...
              </div>
              <div style={{ fontSize: '12px', color: '#9CA3AF' }}>Room: PP</div>
            </div>
          )}
        </div>
      )}

      {/* Emoji Reaction Picker Bar */}
      {showReactionPicker && (
        <div
          style={{
            position: 'absolute',
            bottom: '80px',
            left: '50%',
            transform: 'translateX(-50%)',
            zIndex: 70,
          }}
        >
          <ReactionPicker
            onSelectEmoji={(emoji) => {
              handleSendEmoji(emoji);
              setShowReactionPicker(false);
            }}
            onClose={() => setShowReactionPicker(false)}
          />
        </div>
      )}

      {/* In-Movie Chat Modal */}
      {showChatModal && (
        <InMovieChatModal
          partnerName={partnerName}
          onSendMessage={handleSendChatMessage}
          onClose={() => setShowChatModal(false)}
        />
      )}

      {/* Movie Menu Modal */}
      {showMovieMenu && (
        <MovieMenuModal
          onSelectLocalFile={handleSelectLocalFile}
          onSelectYouTube={handleSelectYouTube}
          onClose={() => setShowMovieMenu(false)}
        />
      )}

      {/* Polaroid Snapshot Modal */}
      {snapshotDataUrl && (
        <SnapshotModal
          imageSrc={snapshotDataUrl}
          onClose={() => setSnapshotDataUrl(null)}
        />
      )}

      {/* Auto-Hiding Bottom Control Bar */}
      <div
        style={{
          position: 'absolute',
          bottom: showControls ? '20px' : '-75px',
          left: '50%',
          transform: 'translateX(-50%)',
          zIndex: 40,
          transition: 'bottom 0.28s ease',
          pointerEvents: showControls ? 'auto' : 'none',
        }}
      >
        <ControlBar
          isMicMuted={isMicMuted}
          isCameraMuted={isCameraMuted}
          isScreenSharing={isScreenSharing}
          isAnyMediaOrScreenActive={isAnyMediaOrScreenActive}
          isVideoStripVisible={isVideoStripVisible}
          isFullscreen={isFullscreen}
          hasMultipleCameras={hasMultipleCameras}
          onToggleMic={toggleMic}
          onToggleCamera={toggleCamera}
          onFlipCamera={flipCamera}
          onToggleScreenShare={toggleScreenShare}
          onOpenMovieMenu={() => setShowMovieMenu(true)}
          onToggleReactions={() => setShowReactionPicker((p) => !p)}
          onOpenChat={() => setShowChatModal(true)}
          onTakeSnapshot={handleTakeSnapshot}
          onToggleVideoStrip={() => setIsVideoStripVisible(!isVideoStripVisible)}
          onToggleFullscreen={toggleFullscreen}
          onLeaveCall={onLeave}
        />
      </div>
    </div>
  );
}
