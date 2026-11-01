import React from 'react';

export default function CenterStageModal({ onClose }) {
  return (
    <div
      onClick={onClose}
      style={{
        position: 'fixed',
        inset: 0,
        backgroundColor: 'rgba(0, 0, 0, 0.78)',
        backdropFilter: 'blur(8px)',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        zIndex: 90,
        padding: '16px',
      }}
    >
      <div
        onClick={(e) => e.stopPropagation()}
        className="fade-in"
        style={{
          backgroundColor: '#1D171E',
          borderRadius: '24px',
          border: '1.5px solid #E2849C',
          boxShadow: '0 16px 40px rgba(0, 0, 0, 0.8), 0 0 30px rgba(226, 132, 156, 0.2)',
          maxWidth: '460px',
          width: '100%',
          padding: '24px',
          color: '#FFFFFF',
          textAlign: 'left',
        }}
      >
        {/* Header */}
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '16px' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
            <div
              style={{
                width: '38px',
                height: '38px',
                borderRadius: '50%',
                backgroundColor: 'rgba(226, 132, 156, 0.2)',
                border: '1px solid #E2849C',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                fontSize: '18px',
              }}
            >
              📐
            </div>
            <div>
              <div style={{ fontSize: '16px', fontWeight: 'bold', color: '#F7A8BE' }}>iPad Center Stage</div>
              <div style={{ fontSize: '11px', color: '#9CA3AF' }}>Fix wide camera view for Priya</div>
            </div>
          </div>
          <button
            onClick={onClose}
            style={{
              background: 'none',
              border: 'none',
              color: '#9CA3AF',
              fontSize: '20px',
              cursor: 'pointer',
              padding: '4px 8px',
            }}
          >
            ✕
          </button>
        </div>

        {/* Why it happens */}
        <div
          style={{
            backgroundColor: 'rgba(226, 132, 156, 0.1)',
            border: '1px solid rgba(226, 132, 156, 0.25)',
            borderRadius: '14px',
            padding: '12px 14px',
            fontSize: '12px',
            lineHeight: '1.5',
            color: '#E5E7EB',
            marginBottom: '18px',
          }}
        >
          Your iPad has a 122° Ultra-Wide front lens. By default, Safari outputs the full room view. Turn on <strong>Center Stage</strong> in iPadOS to automatically crop and track your face so Priya sees a close-up portrait!
        </div>

        {/* Steps */}
        <div style={{ display: 'flex', flexDirection: 'column', gap: '14px', marginBottom: '22px' }}>
          <div style={{ display: 'flex', gap: '12px', alignItems: 'flex-start' }}>
            <div
              style={{
                width: '26px',
                height: '26px',
                borderRadius: '50%',
                backgroundColor: '#E2849C',
                color: '#FFFFFF',
                fontWeight: 'bold',
                fontSize: '13px',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                flexShrink: 0,
              }}
            >
              1
            </div>
            <div style={{ fontSize: '13px', lineHeight: '1.4' }}>
              <strong>Swipe down from top-right corner</strong> of your iPad screen to open the <strong>Control Center</strong>.
            </div>
          </div>

          <div style={{ display: 'flex', gap: '12px', alignItems: 'flex-start' }}>
            <div
              style={{
                width: '26px',
                height: '26px',
                borderRadius: '50%',
                backgroundColor: '#E2849C',
                color: '#FFFFFF',
                fontWeight: 'bold',
                fontSize: '13px',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                flexShrink: 0,
              }}
            >
              2
            </div>
            <div style={{ fontSize: '13px', lineHeight: '1.4' }}>
              Tap the <strong>Video Effects</strong> (or Safari) button at the very top.
            </div>
          </div>

          <div style={{ display: 'flex', gap: '12px', alignItems: 'flex-start' }}>
            <div
              style={{
                width: '26px',
                height: '26px',
                borderRadius: '50%',
                backgroundColor: '#E2849C',
                color: '#FFFFFF',
                fontWeight: 'bold',
                fontSize: '13px',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                flexShrink: 0,
              }}
            >
              3
            </div>
            <div style={{ fontSize: '13px', lineHeight: '1.4' }}>
              Tap <strong>Center Stage</strong> to turn it <strong>ON</strong> 🟢.
              <div style={{ fontSize: '11px', color: '#9CA3AF', marginTop: '3px' }}>
                *(Optional: You can also tap <strong>Portrait</strong> to blur your room background!)*
              </div>
            </div>
          </div>
        </div>

        {/* Action Button */}
        <button
          onClick={onClose}
          style={{
            width: '100%',
            padding: '12px',
            backgroundColor: '#E2849C',
            color: '#FFFFFF',
            borderRadius: '16px',
            fontWeight: 'bold',
            fontSize: '14px',
            cursor: 'pointer',
            border: 'none',
          }}
        >
          Got it! 👍
        </button>
      </div>
    </div>
  );
}
