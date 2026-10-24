import React from 'react';

export default function ControlBar({
  isMicMuted,
  isCameraMuted,
  isScreenSharing,
  isAnyScreenShareActive,
  isVideoStripVisible,
  isFullscreen,
  onToggleMic,
  onToggleCamera,
  onToggleScreenShare,
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
    fontSize: '18px',
    transition: 'all 0.2s ease',
  });

  return (
    <div style={{
      backgroundColor: 'rgba(29, 23, 30, 0.92)',
      backdropFilter: 'blur(12px)',
      padding: '8px 18px',
      borderRadius: '36px',
      border: '1px solid rgba(226, 132, 156, 0.25)',
      boxShadow: '0 8px 30px rgba(0, 0, 0, 0.6)',
      display: 'flex',
      alignItems: 'center',
      gap: '12px',
    }}>
      {/* Microphone Toggle */}
      <button
        style={btnStyle(!isMicMuted, '#E2849C')}
        onClick={onToggleMic}
        title={isMicMuted ? 'Unmute Microphone' : 'Mute Microphone'}
      >
        {isMicMuted ? '🔇' : '🎙️'}
      </button>

      {/* Camera Toggle */}
      <button
        style={btnStyle(!isCameraMuted, '#E2849C')}
        onClick={onToggleCamera}
        title={isCameraMuted ? 'Turn On Camera' : 'Turn Off Camera'}
      >
        {isCameraMuted ? '📷' : '📹'}
      </button>

      {/* Share Chrome Tab with Audio */}
      <button
        style={btnStyle(isScreenSharing, '#F7A8BE')}
        onClick={onToggleScreenShare}
        title={isScreenSharing ? 'Stop Sharing' : 'Share Chrome Tab with Audio'}
      >
        {isScreenSharing ? '⏹️' : '🖥️'}
      </button>

      {/* Hide / Show Video Strip */}
      {isAnyScreenShareActive && (
        <button
          style={btnStyle(isVideoStripVisible, '#C4B5FD')}
          onClick={onToggleVideoStrip}
          title={isVideoStripVisible ? 'Hide Faces (Full Movie Height)' : 'Show Faces'}
        >
          {isVideoStripVisible ? '👁️' : '🕶️'}
        </button>
      )}

      {/* Fullscreen Toggle */}
      <button
        style={btnStyle(isFullscreen, '#34D399')}
        onClick={onToggleFullscreen}
        title={isFullscreen ? 'Exit Fullscreen' : 'Cinema Fullscreen'}
      >
        {isFullscreen ? '↙️' : '⛶'}
      </button>

      {/* Leave Call */}
      <button
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
          marginLeft: '4px'
        }}
        onClick={onLeaveCall}
        title="Leave Cinema Room"
      >
        📞
      </button>
    </div>
  );
}
