import React, { useEffect, useRef } from 'react';

export default function VideoTile({ title, track, isMuted, isSpeaking, isLocal }) {
  const videoRef = useRef(null);

  useEffect(() => {
    const videoEl = videoRef.current;
    if (track && videoEl) {
      track.attach(videoEl);
    }
    return () => {
      if (track && videoEl) {
        track.detach(videoEl);
      }
    };
  }, [track]);

  const initial = title ? title.charAt(0).toUpperCase() : '?';

  return (
    <div
      style={{
        position: 'relative',
        width: '100%',
        height: '100%',
        backgroundColor: '#1D171E',
        borderRadius: '16px',
        overflow: 'hidden',
        border: `2px solid ${isSpeaking ? '#E2849C' : '#28202A'}`,
        boxShadow: isSpeaking ? '0 0 16px rgba(226, 132, 156, 0.4)' : 'none',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        transition: 'border-color 0.2s, box-shadow 0.2s',
      }}
    >
      {track ? (
        <video
          ref={videoRef}
          style={{
            width: '100%',
            height: '100%',
            objectFit: 'cover',
            transform: isLocal ? 'scaleX(-1)' : 'none',
          }}
          autoPlay
          playsInline
          muted={true} // Camera feeds are strictly video. Audio is rendered independently via RemoteAudioRenderer
        />
      ) : (
        <div
          style={{
            display: 'flex',
            flexDirection: 'column',
            alignItems: 'center',
            gap: '8px',
          }}
        >
          <div
            style={{
              width: '54px',
              height: '54px',
              borderRadius: '50%',
              backgroundColor: 'rgba(226, 132, 156, 0.2)',
              border: '2px solid #E2849C',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              fontSize: '22px',
              fontWeight: 'bold',
              color: '#F7A8BE',
            }}
          >
            {initial}
          </div>
          <span style={{ fontSize: '11px', color: '#9CA3AF' }}>Camera Off</span>
        </div>
      )}

      {/* Title & Status Badge */}
      <div
        style={{
          position: 'absolute',
          bottom: '8px',
          left: '8px',
          backgroundColor: 'rgba(0, 0, 0, 0.72)',
          backdropFilter: 'blur(6px)',
          borderRadius: '16px',
          padding: '4px 10px',
          display: 'flex',
          alignItems: 'center',
          gap: '6px',
          fontSize: '11px',
          fontWeight: '600',
          color: '#FFFFFF',
          border: '1px solid rgba(255, 255, 255, 0.1)',
        }}
      >
        <span>{title}</span>
        {isMuted && (
          <span style={{ color: '#EF4444', fontSize: '11px' }} title="Muted">
            🔇
          </span>
        )}
      </div>
    </div>
  );
}
