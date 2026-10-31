import React, { useRef, useEffect, useState } from 'react';

export default function CinemaPlayer({
  screenShareTrack,
  sharerName,
  localMediaFile,
  youtubeVideoId,
  isMediaPlaying,
  mediaCurrentTime,
  mediaDuration,
  onPlayPause,
  onSeek,
  onCloseMedia,
  onPickLocalFile,
  onOpenYoutubeModal,
  pendingPartnerFileName,
}) {
  const videoRef = useRef(null);
  const screenRef = useRef(null);
  const [fitMode, setFitMode] = useState('contain'); // contain or cover
  const [showControls, setShowControls] = useState(true);
  const hideTimerRef = useRef(null);

  // Attach Screen Share WebRTC Track
  useEffect(() => {
    const el = screenRef.current;
    if (screenShareTrack && el) {
      screenShareTrack.attach(el);
    }
    return () => {
      if (screenShareTrack && el) {
        screenShareTrack.detach(el);
      }
    };
  }, [screenShareTrack]);

  // Sync Local Video Player state
  useEffect(() => {
    const vid = videoRef.current;
    if (!vid) return;

    if (isMediaPlaying && vid.paused) {
      vid.play().catch(() => {});
    } else if (!isMediaPlaying && !vid.paused) {
      vid.pause();
    }
  }, [isMediaPlaying]);

  useEffect(() => {
    const vid = videoRef.current;
    if (!vid) return;

    if (Math.abs(vid.currentTime - mediaCurrentTime) > 0.6) {
      vid.currentTime = mediaCurrentTime;
    }
  }, [mediaCurrentTime]);

  const handleCanvasClick = () => {
    setShowControls((prev) => !prev);
    if (hideTimerRef.current) clearTimeout(hideTimerRef.current);
    if (isMediaPlaying) {
      hideTimerRef.current = setTimeout(() => setShowControls(false), 3500);
    }
  };

  const formatTime = (seconds) => {
    if (!seconds || isNaN(seconds)) return '0:00';
    const m = Math.floor(seconds / 60);
    const s = Math.floor(seconds % 60);
    return `${m}:${s < 10 ? '0' : ''}${s}`;
  };

  const hasLocalVideo = !!localMediaFile;
  const hasYoutube = !!youtubeVideoId;
  const hasMedia = hasLocalVideo || hasYoutube;
  const isScreenSharingActive = !!screenShareTrack;

  return (
    <div
      onClick={handleCanvasClick}
      style={{
        width: '100%',
        height: '100%',
        position: 'relative',
        backgroundColor: '#000000',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        overflow: 'hidden',
      }}
    >
      {/* 1. In-App Local Video Player */}
      {hasLocalVideo && (
        <video
          ref={videoRef}
          src={localMediaFile.url}
          style={{
            width: '100%',
            height: '100%',
            objectFit: fitMode,
          }}
          playsInline
        />
      )}

      {/* 2. In-App YouTube Embed */}
      {hasYoutube && (
        <div style={{ width: '100%', height: '100%', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
          <iframe
            title="YouTube Cinema"
            src={`https://www.youtube.com/embed/${youtubeVideoId}?autoplay=1&enablejsapi=1&controls=0&modestbranding=1&playsinline=1`}
            style={{
              width: '100%',
              height: '100%',
              border: 'none',
              maxWidth: fitMode === 'contain' ? '1280px' : '100%',
              aspectRatio: '16/9',
            }}
            allow="autoplay; encrypted-media; fullscreen"
          />
        </div>
      )}

      {/* 3. Screen Share Stream */}
      {isScreenSharingActive && !hasMedia && (
        <video
          ref={screenRef}
          style={{
            width: '100%',
            height: '100%',
            objectFit: 'contain',
          }}
          autoPlay
          playsInline
        />
      )}

      {/* Partner Movie Invitation Banner */}
      {pendingPartnerFileName && !hasMedia && (
        <div
          onClick={(e) => {
            e.stopPropagation();
            onPickLocalFile();
          }}
          style={{
            position: 'absolute',
            top: '76px',
            left: '50%',
            transform: 'translateX(-50%)',
            backgroundColor: 'rgba(29, 23, 30, 0.95)',
            border: '1.5px solid #E2849C',
            borderRadius: '16px',
            padding: '12px 20px',
            color: '#FFFFFF',
            display: 'flex',
            alignItems: 'center',
            gap: '12px',
            cursor: 'pointer',
            boxShadow: '0 8px 24px rgba(226, 132, 156, 0.3)',
            zIndex: 45,
          }}
        >
          <span style={{ fontSize: '22px' }}>🎬</span>
          <div>
            <div style={{ fontSize: '13px', fontWeight: 'bold' }}>
              Partner loaded: {pendingPartnerFileName}
            </div>
            <div style={{ fontSize: '11px', color: '#F7A8BE' }}>
              Click here to choose your local copy & sync playback ❤️
            </div>
          </div>
        </div>
      )}

      {/* Top Media Bar */}
      <div
        style={{
          position: 'absolute',
          top: showControls ? '68px' : '-60px',
          left: '20px',
          right: '20px',
          display: 'flex',
          justifyContent: 'space-between',
          alignItems: 'center',
          transition: 'top 0.25s ease',
          zIndex: 40,
          pointerEvents: showControls ? 'auto' : 'none',
        }}
        onClick={(e) => e.stopPropagation()}
      >
        <div
          style={{
            backgroundColor: 'rgba(0, 0, 0, 0.75)',
            backdropFilter: 'blur(8px)',
            padding: '6px 14px',
            borderRadius: '16px',
            border: '1px solid rgba(226, 132, 156, 0.3)',
            color: '#FFFFFF',
            fontSize: '12px',
            fontWeight: '600',
            display: 'flex',
            alignItems: 'center',
            gap: '8px',
          }}
        >
          <span>🎬</span>
          <span>
            {hasMedia
              ? localMediaFile?.name || 'YouTube Cinema'
              : `${sharerName || 'Partner'}'s Screen & Audio`}
          </span>
        </div>

        <div style={{ display: 'flex', gap: '8px' }}>
          {/* Fit Mode Button */}
          <button
            onClick={() => setFitMode((m) => (m === 'contain' ? 'cover' : 'contain'))}
            title={fitMode === 'contain' ? 'Fit to Screen (No Stretch)' : 'Fill Screen'}
            style={{
              backgroundColor: 'rgba(0, 0, 0, 0.75)',
              border: '1px solid rgba(226, 132, 156, 0.4)',
              color: '#FFFFFF',
              borderRadius: '50%',
              width: '32px',
              height: '32px',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              fontSize: '14px',
            }}
          >
            {fitMode === 'contain' ? '⊡' : '⛶'}
          </button>

          {/* Close Cinema Button */}
          {hasMedia && (
            <button
              onClick={onCloseMedia}
              title="Close Cinema"
              style={{
                backgroundColor: 'rgba(239, 68, 68, 0.8)',
                color: '#FFFFFF',
                borderRadius: '50%',
                width: '32px',
                height: '32px',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                fontSize: '14px',
              }}
            >
              ✕
            </button>
          )}
        </div>
      </div>

      {/* Media Playback Scrubber for Local Video */}
      {hasLocalVideo && (
        <div
          style={{
            position: 'absolute',
            bottom: showControls ? '16px' : '-70px',
            left: '24px',
            right: '24px',
            backgroundColor: 'rgba(0, 0, 0, 0.8)',
            backdropFilter: 'blur(8px)',
            borderRadius: '20px',
            padding: '8px 16px',
            border: '1px solid rgba(255, 255, 255, 0.15)',
            display: 'flex',
            alignItems: 'center',
            gap: '12px',
            transition: 'bottom 0.25s ease',
            zIndex: 40,
            pointerEvents: showControls ? 'auto' : 'none',
          }}
          onClick={(e) => e.stopPropagation()}
        >
          <button
            onClick={onPlayPause}
            style={{
              background: 'none',
              color: '#FFFFFF',
              fontSize: '18px',
              padding: '4px',
            }}
          >
            {isMediaPlaying ? '⏸' : '▶'}
          </button>

          <span style={{ fontSize: '11px', color: '#9CA3AF', minWidth: '40px' }}>
            {formatTime(mediaCurrentTime)}
          </span>

          <input
            type="range"
            min={0}
            max={mediaDuration || 100}
            value={mediaCurrentTime}
            onChange={(e) => onSeek(parseFloat(e.target.value))}
            style={{
              flex: 1,
              accentColor: '#E2849C',
              cursor: 'pointer',
            }}
          />

          <span style={{ fontSize: '11px', color: '#9CA3AF', minWidth: '40px' }}>
            {formatTime(mediaDuration)}
          </span>
        </div>
      )}
    </div>
  );
}
