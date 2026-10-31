import React from 'react';

export default function ControlBar({
  isMicMuted,
  isCameraMuted,
  isScreenSharing,
  isAnyMediaOrScreenActive,
  isVideoStripVisible,
  isFullscreen,
  hasMultipleCameras,
  onToggleMic,
  onToggleCamera,
  onFlipCamera,
  onToggleScreenShare,
  onOpenMovieMenu,
  onToggleReactions,
  onOpenChat,
  onTakeSnapshot,
  onToggleVideoStrip,
  onToggleFullscreen,
  onLeaveCall,
}) {
  const btnStyle = (active, color = '#E2849C') => ({
    width: '42px',
    height: '42px',
    borderRadius: '50%',
    backgroundColor: active ? `${color}25` : 'rgba(255, 255, 255, 0.08)',
    border: `1.5px solid ${active ? color : 'rgba(255, 255, 255, 0.15)'}`,
    color: active ? color : '#9CA3AF',
    display: 'flex',
    alignItems: 'center',
    justifyContent: 'center',
    fontSize: '17px',
    transition: 'all 0.18s ease',
    flexShrink: 0,
  });

  return (
    <div
      style={{
        backgroundColor: 'rgba(29, 23, 30, 0.94)',
        backdropFilter: 'blur(16px)',
        padding: '8px 16px',
        borderRadius: '36px',
        border: '1.5px solid rgba(226, 132, 156, 0.28)',
        boxShadow: '0 8px 32px rgba(0, 0, 0, 0.75)',
        display: 'flex',
        alignItems: 'center',
        gap: '8px',
        maxWidth: '96vw',
        overflowX: 'auto',
        scrollbarWidth: 'none',
      }}
    >
      {/* 1. Microphone Toggle */}
      <button
        style={btnStyle(!isMicMuted, '#E2849C')}
        onClick={onToggleMic}
        title={isMicMuted ? 'Unmute Microphone' : 'Mute Microphone'}
      >
        {isMicMuted ? '🔇' : '🎙️'}
      </button>

      {/* 2. Camera Toggle */}
      <button
        style={btnStyle(!isCameraMuted, '#E2849C')}
        onClick={onToggleCamera}
        title={isCameraMuted ? 'Turn On Camera' : 'Turn Off Camera'}
      >
        {isCameraMuted ? '📷' : '📹'}
      </button>

      {/* 3. Flip Camera (Tablets / Laptops with 2+ cameras) */}
      {hasMultipleCameras && (
        <button
          style={btnStyle(false, '#C4B5FD')}
          onClick={onFlipCamera}
          title="Flip / Switch Camera"
        >
          🔄
        </button>
      )}

      {/* 4. Screen Sharing (Laptops / Desktops / Supported Tablets) */}
      <button
        style={btnStyle(isScreenSharing, '#F7A8BE')}
        onClick={onToggleScreenShare}
        title={isScreenSharing ? 'Stop Screen Share' : 'Share Screen / Browser Tab with Audio'}
      >
        {isScreenSharing ? '⏹️' : '🖥️'}
      </button>

      {/* 5. Cinema Movie Menu (Local Movie / YouTube) */}
      <button
        style={btnStyle(isAnyMediaOrScreenActive, '#E2849C')}
        onClick={onOpenMovieMenu}
        title="Watch Movie Together (Local File or YouTube)"
      >
        🎬
      </button>

      {/* 6. Floating Emoji Reactions */}
      <button
        style={btnStyle(false, '#E2849C')}
        onClick={onToggleReactions}
        title="Send Floating Emoji Reaction ❤️"
      >
        ❤️
      </button>

      {/* 7. In-Movie Chat */}
      <button
        style={btnStyle(false, '#C4B5FD')}
        onClick={onOpenChat}
        title="In-Movie Chat & Whispers 💬"
      >
        💬
      </button>

      {/* 8. Snapshot Keepsake Button */}
      <button
        style={btnStyle(false, '#FCD34D')}
        onClick={onTakeSnapshot}
        title="Take Polaroid Snapshot Keepsake 📸"
      >
        📸
      </button>

      {/* 9. Hide / Show Video Strip */}
      {isAnyMediaOrScreenActive && (
        <button
          style={btnStyle(isVideoStripVisible, '#C4B5FD')}
          onClick={onToggleVideoStrip}
          title={isVideoStripVisible ? 'Hide Faces (Full Movie Height)' : 'Show Faces'}
        >
          {isVideoStripVisible ? '👁️' : '🕶️'}
        </button>
      )}

      {/* 10. Fullscreen Toggle */}
      <button
        style={btnStyle(isFullscreen, '#34D399')}
        onClick={onToggleFullscreen}
        title={isFullscreen ? 'Exit Fullscreen' : 'Cinema Fullscreen'}
      >
        {isFullscreen ? '↙️' : '⛶'}
      </button>

      {/* 11. End Call */}
      <button
        onClick={onLeaveCall}
        title="End Call / Leave Cinema"
        style={{
          width: '42px',
          height: '42px',
          borderRadius: '50%',
          backgroundColor: '#EF4444',
          color: '#FFFFFF',
          fontSize: '18px',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          boxShadow: '0 2px 10px rgba(239, 68, 68, 0.4)',
          marginLeft: '4px',
          flexShrink: 0,
        }}
      >
        📞
      </button>
    </div>
  );
}
