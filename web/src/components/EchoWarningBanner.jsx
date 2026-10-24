import React, { useState } from 'react';

export default function EchoWarningBanner({ isSharingAudio }) {
  const [dismissed, setDismissed] = useState(false);

  if (!isSharingAudio || dismissed) return null;

  return (
    <div style={{
      position: 'absolute',
      top: '70px',
      left: '50%',
      transform: 'translateX(-50%)',
      zIndex: 50,
      backgroundColor: 'rgba(29, 23, 30, 0.94)',
      border: '1.5px solid #F59E0B',
      borderRadius: '16px',
      padding: '10px 18px',
      boxShadow: '0 8px 24px rgba(0, 0, 0, 0.6)',
      display: 'flex',
      alignItems: 'center',
      gap: '12px',
      maxWidth: '650px',
      width: '90%'
    }} className="fade-in">
      <span style={{ fontSize: '22px' }}>🎧</span>
      <div style={{ flex: 1, fontSize: '13px', lineHeight: '1.4', color: '#FDE68A' }}>
        <strong>Headphones Recommended:</strong> You are sharing tab audio. To prevent the movie sound from looping back into your laptop microphone, please wear headphones!
      </div>
      <button
        onClick={() => setDismissed(true)}
        style={{
          background: 'none',
          color: '#9CA3AF',
          fontSize: '18px',
          padding: '4px 8px',
          borderRadius: '8px'
        }}
        title="Dismiss notice"
      >
        ✕
      </button>
    </div>
  );
}
