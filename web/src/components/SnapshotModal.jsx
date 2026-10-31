import React from 'react';

export default function SnapshotModal({ imageSrc, dateText, onClose }) {
  if (!imageSrc) return null;

  const handleDownload = () => {
    const a = document.createElement('a');
    a.href = imageSrc;
    a.download = `TogetherStream-Keepsake-${Date.now()}.png`;
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);
  };

  return (
    <div
      style={{
        position: 'fixed',
        inset: 0,
        backgroundColor: 'rgba(0, 0, 0, 0.75)',
        backdropFilter: 'blur(8px)',
        zIndex: 110,
        display: 'flex',
        flexDirection: 'column',
        alignItems: 'center',
        justifyContent: 'center',
        padding: '20px',
        animation: 'fadeIn 0.25s ease',
      }}
      onClick={onClose}
    >
      {/* Polaroid Card */}
      <div
        style={{
          backgroundColor: '#FFFFFF',
          borderRadius: '16px',
          padding: '16px 16px 24px',
          boxShadow: '0 20px 50px rgba(0, 0, 0, 0.8), 0 0 40px rgba(226, 132, 156, 0.3)',
          maxWidth: '480px',
          width: '100%',
          display: 'flex',
          flexDirection: 'column',
          alignItems: 'center',
          animation: 'fadeIn 0.3s ease',
        }}
        onClick={(e) => e.stopPropagation()}
      >
        {/* Photo Container */}
        <div
          style={{
            width: '100%',
            aspectRatio: '16/9',
            backgroundColor: '#000000',
            borderRadius: '10px',
            overflow: 'hidden',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
          }}
        >
          <img
            src={imageSrc}
            alt="Date Keepsake"
            style={{ width: '100%', height: '100%', objectFit: 'cover' }}
          />
        </div>

        {/* Polaroid Footer */}
        <div
          style={{
            width: '100%',
            display: 'flex',
            justifyContent: 'space-between',
            alignItems: 'center',
            marginTop: '16px',
            padding: '0 6px',
          }}
        >
          <span
            style={{
              fontFamily: 'serif',
              fontSize: '18px',
              fontWeight: 'bold',
              color: '#2D1B28',
              letterSpacing: '0.3px',
            }}
          >
            Pawan & Priya ❤️
          </span>
          <span
            style={{
              fontSize: '12px',
              color: '#6B7280',
              fontStyle: 'italic',
            }}
          >
            {dateText || new Date().toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' })}
          </span>
        </div>
      </div>

      {/* Action Buttons */}
      <div
        style={{
          display: 'flex',
          gap: '12px',
          marginTop: '22px',
        }}
        onClick={(e) => e.stopPropagation()}
      >
        <button
          onClick={handleDownload}
          style={{
            backgroundColor: '#E2849C',
            color: '#FFFFFF',
            padding: '10px 22px',
            borderRadius: '24px',
            fontWeight: '600',
            fontSize: '14px',
            display: 'flex',
            alignItems: 'center',
            gap: '8px',
            boxShadow: '0 4px 16px rgba(226, 132, 156, 0.4)',
          }}
        >
          <span>📥</span> Download Photo
        </button>
        <button
          onClick={onClose}
          style={{
            backgroundColor: 'rgba(255, 255, 255, 0.15)',
            color: '#FFFFFF',
            padding: '10px 20px',
            borderRadius: '24px',
            fontWeight: '500',
            fontSize: '14px',
          }}
        >
          Close
        </button>
      </div>
    </div>
  );
}
