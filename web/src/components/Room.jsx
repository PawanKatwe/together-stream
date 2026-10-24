import React, { useEffect, useState, useRef } from 'react';
import { Room as LKRoom, RoomEvent, Track } from 'livekit-client';
import VideoTile from './VideoTile';
import ControlBar from './ControlBar';
import EchoWarningBanner from './EchoWarningBanner';

export default function Room({ connectionConfig, onLeave }) {
  const [room, setRoom] = useState(null);
  const [isConnecting, setIsConnecting] = useState(true);
  const [error, setError] = useState(null);

  // Tracks State
  const [localVideoTrack, setLocalVideoTrack] = useState(null);
  const [isMicMuted, setIsMicMuted] = useState(false);
  const [isCameraMuted, setIsCameraMuted] = useState(false);
  const [isScreenSharing, setIsScreenSharing] = useState(false);

  // Remote Tracks & Participants
  const [remoteParticipants, setRemoteParticipants] = useState([]);
  const [screenShareTrack, setScreenShareTrack] = useState(null);
  const [screenSharerName, setScreenSharerName] = useState(null);

  // UI States
  const [showControls, setShowControls] = useState(true);
  const [isVideoStripVisible, setIsVideoStripVisible] = useState(true);
  const [isFullscreen, setIsFullscreen] = useState(false);
  const hideControlsTimer = useRef(null);
  const screenVideoRef = useRef(null);

  const resetControlsTimer = () => {
    setShowControls(true);
    if (hideControlsTimer.current) clearTimeout(hideControlsTimer.current);
    hideControlsTimer.current = setTimeout(() => {
      setShowControls(false);
    }, 3000);
  };

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
          setScreenSharerName(p.name || 'Partner');
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

    // LiveKit Listeners
    lkRoom
      .on(RoomEvent.ParticipantConnected, () => updateTracks(lkRoom))
      .on(RoomEvent.ParticipantDisconnected, () => updateTracks(lkRoom))
      .on(RoomEvent.TrackSubscribed, () => updateTracks(lkRoom))
      .on(RoomEvent.TrackUnsubscribed, () => updateTracks(lkRoom))
      .on(RoomEvent.LocalTrackPublished, () => updateTracks(lkRoom))
      .on(RoomEvent.LocalTrackUnpublished, () => updateTracks(lkRoom))
      .on(RoomEvent.TrackMuted, () => updateTracks(lkRoom))
      .on(RoomEvent.TrackUnmuted, () => updateTracks(lkRoom));

    initRoom();
    resetControlsTimer();

    return () => {
      if (hideControlsTimer.current) clearTimeout(hideControlsTimer.current);
      lkRoom.disconnect();
    };
  }, [connectionConfig]);

  // Attach Screen Share Video Track to DOM element
  useEffect(() => {
    const videoEl = screenVideoRef.current;
    if (screenShareTrack && videoEl) {
      screenShareTrack.attach(videoEl);
    }
    return () => {
      if (screenShareTrack && videoEl) {
        screenShareTrack.detach(videoEl);
      }
    };
  }, [screenShareTrack]);

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

  const toggleScreenShare = async () => {
    if (!room) return;
    try {
      if (isScreenSharing) {
        await room.localParticipant.setScreenShareEnabled(false);
        setIsScreenSharing(false);
      } else {
        // Desktop Chrome: prompts for Chrome Tab / Window with audio checkbox checked
        await room.localParticipant.setScreenShareEnabled(true, {
          audio: true, // Captures pristine tab audio from the movie
          resolution: { width: 1920, height: 1080, frameRate: 30 }
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

  if (isConnecting) {
    return (
      <div style={{
        width: '100vw',
        height: '100vh',
        display: 'flex',
        flexDirection: 'column',
        alignItems: 'center',
        justifyContent: 'center',
        backgroundColor: '#121013',
        gap: '16px'
      }}>
        <div className="pulse" style={{
          width: '56px',
          height: '56px',
          borderRadius: '50%',
          backgroundColor: 'rgba(226, 132, 156, 0.2)',
          border: '2px solid #E2849C',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          fontSize: '24px'
        }}>
          ❤️
        </div>
        <div style={{ fontSize: '16px', fontWeight: '600', color: '#F7A8BE' }}>
          Connecting to Cinema Room PP...
        </div>
        <div style={{ fontSize: '13px', color: '#9CA3AF' }}>
          Identity: {connectionConfig.identity}
        </div>
      </div>
    );
  }

  if (error) {
    return (
      <div style={{
        width: '100vw',
        height: '100vh',
        display: 'flex',
        flexDirection: 'column',
        alignItems: 'center',
        justifyContent: 'center',
        backgroundColor: '#121013',
        gap: '16px',
        padding: '24px'
      }}>
        <div style={{ fontSize: '32px' }}>⚠️</div>
        <div style={{ fontSize: '18px', fontWeight: 'bold', color: '#EF4444' }}>
          Connection Error
        </div>
        <div style={{ fontSize: '14px', color: '#D1D5DB', maxWidth: '400px', textAlign: 'center' }}>
          {error}
        </div>
        <button
          onClick={onLeave}
          style={{
            marginTop: '12px',
            padding: '10px 20px',
            backgroundColor: '#E2849C',
            color: '#FFFFFF',
            borderRadius: '12px',
            fontWeight: '600'
          }}
        >
          Return to Setup
        </button>
      </div>
    );
  }

  const isAnyScreenShareActive = screenShareTrack !== null;

  return (
    <div
      onMouseMove={resetControlsTimer}
      style={{
        width: '100vw',
        height: '100vh',
        backgroundColor: '#000000',
        display: 'flex',
        flexDirection: 'column',
        position: 'relative',
        overflow: 'hidden'
      }}
    >
      {/* Echo Warning Banner */}
      <EchoWarningBanner isSharingAudio={isScreenSharing} />

      {/* Top Header Bar */}
      <div style={{
        position: 'absolute',
        top: showControls ? '16px' : '-60px',
        left: '20px',
        right: '20px',
        display: 'flex',
        justifyContent: 'space-between',
        alignItems: 'center',
        zIndex: 40,
        transition: 'top 0.3s ease',
        pointerEvents: showControls ? 'auto' : 'none'
      }}>
        <div style={{
          backgroundColor: 'rgba(29, 23, 30, 0.85)',
          backdropFilter: 'blur(8px)',
          padding: '6px 14px',
          borderRadius: '20px',
          border: '1px solid rgba(226, 132, 156, 0.3)',
          display: 'flex',
          alignItems: 'center',
          gap: '8px',
          fontSize: '12px',
          fontWeight: '600'
        }}>
          <span>❤️</span>
          <span>Room PP • {connectionConfig.identity}</span>
        </div>

        <div style={{
          backgroundColor: 'rgba(16, 185, 129, 0.2)',
          border: '1px solid rgba(16, 185, 129, 0.4)',
          borderRadius: '14px',
          padding: '4px 10px',
          color: '#34D399',
          fontSize: '11px',
          fontWeight: 'bold',
          display: 'flex',
          alignItems: 'center',
          gap: '6px'
        }}>
          <span style={{ width: '6px', height: '6px', borderRadius: '50%', backgroundColor: '#34D399' }} />
          <span>{isAnyScreenShareActive ? 'Cinema Mode (80/20)' : 'Call Mode'}</span>
        </div>
      </div>

      {/* Main Content Area */}
      {isAnyScreenShareActive ? (
        // 80/20 Cinema Layout
        <div style={{ flex: 1, display: 'flex', flexDirection: 'column', height: '100%' }}>
          {/* Top ~80% (or 100%): Screen Share Canvas */}
          <div style={{
            flex: 1,
            position: 'relative',
            backgroundColor: '#000000',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            overflow: 'hidden'
          }}>
            <video
              ref={screenVideoRef}
              style={{
                width: '100%',
                height: '100%',
                objectFit: 'contain'
              }}
              autoPlay
              playsInline
            />

            {/* Sharer Badge */}
            <div style={{
              position: 'absolute',
              top: '16px',
              left: '20px',
              backgroundColor: 'rgba(0, 0, 0, 0.7)',
              padding: '4px 12px',
              borderRadius: '16px',
              border: '1px solid rgba(226, 132, 156, 0.35)',
              color: '#FFFFFF',
              fontSize: '12px',
              fontWeight: '600',
              display: 'flex',
              alignItems: 'center',
              gap: '6px'
            }}>
              <span>🎬</span>
              <span>{screenSharerName}'s Screen & Sound</span>
            </div>

            {/* Restore Faces Button */}
            {!isVideoStripVisible && (
              <button
                onClick={() => setIsVideoStripVisible(true)}
                style={{
                  position: 'absolute',
                  bottom: '20px',
                  right: '20px',
                  backgroundColor: 'rgba(29, 23, 30, 0.85)',
                  border: '1px solid rgba(226, 132, 156, 0.4)',
                  padding: '6px 14px',
                  borderRadius: '20px',
                  color: '#FFFFFF',
                  fontSize: '12px',
                  display: 'flex',
                  alignItems: 'center',
                  gap: '6px'
                }}
              >
                <span>👁️</span> Show Faces
              </button>
            )}
          </div>

          {/* Bottom ~20%: Horizontal Video Strip */}
          <div style={{
            height: isVideoStripVisible ? '135px' : '0px',
            transition: 'height 0.28s ease',
            backgroundColor: '#1D171E',
            borderTop: isVideoStripVisible ? '1px solid #28202A' : 'none',
            display: 'flex',
            alignItems: 'center',
            gap: '10px',
            padding: isVideoStripVisible ? '8px 14px' : '0',
            overflow: 'hidden'
          }}>
            {/* Local Video Tile */}
            <div style={{ flex: 1, height: '100%' }}>
              <VideoTile
                title={connectionConfig.identity}
                track={localVideoTrack}
                isMuted={isMicMuted}
                isLocal={true}
              />
            </div>

            {/* Remote Participants Video Tiles */}
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
              <div style={{
                flex: 1,
                height: '100%',
                backgroundColor: '#121013',
                borderRadius: '14px',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                color: '#9CA3AF',
                fontSize: '12px',
                border: '1px dashed #374151'
              }}>
                Waiting for mobile partner to join...
              </div>
            )}
          </div>
        </div>
      ) : (
        // Call-Only Mode (Equal Split)
        <div style={{
          flex: 1,
          display: 'grid',
          gridTemplateColumns: '1fr 1fr',
          gap: '12px',
          padding: '12px',
          height: '100%'
        }}>
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
            <div style={{
              backgroundColor: '#1D171E',
              borderRadius: '16px',
              display: 'flex',
              flexDirection: 'column',
              alignItems: 'center',
              justifyContent: 'center',
              gap: '12px',
              border: '1px solid #28202A'
            }}>
              <div style={{ fontSize: '28px' }}>❤️</div>
              <div style={{ fontSize: '15px', color: '#F7A8BE', fontWeight: '600' }}>
                Waiting for partner...
              </div>
              <div style={{ fontSize: '12px', color: '#9CA3AF' }}>Room: PP</div>
            </div>
          )}
        </div>
      )}

      {/* Auto-Hiding Bottom Control Bar */}
      <div style={{
        position: 'absolute',
        bottom: showControls ? '20px' : '-70px',
        left: '50%',
        transform: 'translateX(-50%)',
        zIndex: 40,
        transition: 'bottom 0.3s ease',
        pointerEvents: showControls ? 'auto' : 'none'
      }}>
        <ControlBar
          isMicMuted={isMicMuted}
          isCameraMuted={isCameraMuted}
          isScreenSharing={isScreenSharing}
          isAnyScreenShareActive={isAnyScreenShareActive}
          isVideoStripVisible={isVideoStripVisible}
          isFullscreen={isFullscreen}
          onToggleMic={toggleMic}
          onToggleCamera={toggleCamera}
          onToggleScreenShare={toggleScreenShare}
          onToggleVideoStrip={() => setIsVideoStripVisible(!isVideoStripVisible)}
          onToggleFullscreen={toggleFullscreen}
          onLeaveCall={onLeave}
        />
      </div>
    </div>
  );
}
