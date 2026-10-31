import React, { useState, useRef } from 'react';

export default function MovieMenuModal({ onSelectLocalFile, onSelectYouTube, onClose }) {
  const [youtubeUrl, setYoutubeUrl] = useState('');
  const [showYoutubeInput, setShowYoutubeInput] = useState(false);
  const fileInputRef = useRef(null);

  const handleFileChange = (e) => {
    const file = e.target.files?.[0];
    if (file) {
      const url = URL.createObjectURL(file);
      onSelectLocalFile({ file, url, name: file.name });
      onClose();
    }
  };

  const handleYoutubeSubmit = (e) => {
    e.preventDefault();
    if (!youtubeUrl.trim()) return;

    // Extract YouTube ID
    let videoId = youtubeUrl.trim();
    const regExp = /^.*(youtu.be\/|v\/|u\/\w\/|embed\/|watch\?v=|&v=|shorts\/)([^#&?]*).*/;
    const match = videoId.match(regExp);
    if (match && match[2].length === 11) {
      videoId = match[2];
    }

    onSelectYouTube(videoId);
    onClose();
  };

  return (
    <div
      style={{
        position: 'fixed',
        inset: 0,
        backgroundColor: 'rgba(0, 0, 0, 0.7)',
        backdropFilter: 'blur(6px)',
        zIndex: 100,
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        padding: '20px',
      }}
      onClick={onClose}
    >
      <div
        style={{
          width: '100%',
          maxWidth: '440px',
          backgroundColor: '#1D171E',
          borderRadius: '24px',
          border: '1.5px solid rgba(226, 132, 156, 0.35)',
          padding: '28px 24px',
          boxShadow: '0 16px 40px rgba(0, 0, 0, 0.8)',
          color: '#FFFFFF',
        }}
        onClick={(e) => e.stopPropagation()}
      >
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '18px' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '8px', fontSize: '18px', fontWeight: 'bold' }}>
            <span>🎬</span>
            <span>Watch Movie Together</span>
          </div>
          <button onClick={onClose} style={{ background: 'none', color: '#9CA3AF', fontSize: '18px' }}>
            ✕
          </button>
        </div>

        <input
          type="file"
          ref={fileInputRef}
          accept="video/*"
          style={{ display: 'none' }}
          onChange={handleFileChange}
        />

        <div style={{ display: 'flex', flexDirection: 'column', gap: '12px' }}>
          {/* Option 1: Local Video File */}
          <button
            onClick={() => fileInputRef.current?.click()}
            style={{
              padding: '16px',
              backgroundColor: '#28202A',
              border: '1.5px solid rgba(226, 132, 156, 0.3)',
              borderRadius: '16px',
              display: 'flex',
              alignItems: 'center',
              gap: '14px',
              textAlign: 'left',
              color: '#FFFFFF',
              cursor: 'pointer',
            }}
            onMouseEnter={(e) => (e.currentTarget.style.borderColor = '#E2849C')}
            onMouseLeave={(e) => (e.currentTarget.style.borderColor = 'rgba(226, 132, 156, 0.3)')}
          >
            <span style={{ fontSize: '28px' }}>📁</span>
            <div>
              <div style={{ fontWeight: 'bold', fontSize: '14px' }}>Choose Local Video File</div>
              <div style={{ fontSize: '12px', color: '#9CA3AF' }}>MP4, MKV, WebM from your device</div>
            </div>
          </button>

          {/* Option 2: YouTube URL */}
          {!showYoutubeInput ? (
            <button
              onClick={() => setShowYoutubeInput(true)}
              style={{
                padding: '16px',
                backgroundColor: '#28202A',
                border: '1.5px solid rgba(239, 68, 68, 0.3)',
                borderRadius: '16px',
                display: 'flex',
                alignItems: 'center',
                gap: '14px',
                textAlign: 'left',
                color: '#FFFFFF',
                cursor: 'pointer',
              }}
              onMouseEnter={(e) => (e.currentTarget.style.borderColor = '#EF4444')}
              onMouseLeave={(e) => (e.currentTarget.style.borderColor = 'rgba(239, 68, 68, 0.3)')}
            >
              <span style={{ fontSize: '28px' }}>▶️</span>
              <div>
                <div style={{ fontWeight: 'bold', fontSize: '14px' }}>Load YouTube Video</div>
                <div style={{ fontSize: '12px', color: '#9CA3AF' }}>Paste link to watch in sync</div>
              </div>
            </button>
          ) : (
            <form onSubmit={handleYoutubeSubmit} style={{ display: 'flex', flexDirection: 'column', gap: '10px' }}>
              <input
                type="text"
                placeholder="Paste YouTube link or video ID..."
                value={youtubeUrl}
                onChange={(e) => setYoutubeUrl(e.target.value)}
                autoFocus
                style={{
                  width: '100%',
                  padding: '12px 16px',
                  backgroundColor: '#121013',
                  border: '1.5px solid #EF4444',
                  borderRadius: '14px',
                  color: '#FFFFFF',
                  fontSize: '13px',
                  outline: 'none',
                }}
              />
              <button
                type="submit"
                style={{
                  padding: '12px',
                  backgroundColor: '#EF4444',
                  color: '#FFFFFF',
                  borderRadius: '14px',
                  fontWeight: 'bold',
                  fontSize: '13px',
                }}
              >
                Load YouTube & Sync Playback ▶️
              </button>
            </form>
          )}
        </div>

        <div style={{ marginTop: '16px', fontSize: '11px', color: '#9CA3AF', lineHeight: '1.4' }}>
          💡 Both you and Priya can control Play, Pause, and Seek simultaneously across mobile, laptop, and tablet!
        </div>
      </div>
    </div>
  );
}
