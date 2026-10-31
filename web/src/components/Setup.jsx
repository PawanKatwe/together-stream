import React, { useState, useEffect } from 'react';

export default function Setup({ onJoin }) {
  const [deviceType, setDeviceType] = useState('Laptop'); // 'Laptop' or 'Tablet'
  const [serverUrl, setServerUrl] = useState(() => {
    // If running in browser on Render, window.location.origin is already the server!
    const origin = typeof window !== 'undefined' ? window.location.origin : '';
    const isLocalhost = origin.includes('localhost') || origin.includes('127.0.0.1');
    const stored = localStorage.getItem('token_server_url');
    if (stored) return stored;
    if (origin && !isLocalhost) return origin;
    return 'https://together-stream-server.onrender.com';
  });
  const [passcode, setPasscode] = useState('PP@160227');
  const [showConfig, setShowConfig] = useState(false);

  // Auto-detect tablet vs laptop
  useEffect(() => {
    const ua = navigator.userAgent.toLowerCase();
    const isTouch = navigator.maxTouchPoints > 1;
    const isTablet =
      /(ipad|tablet|(android(?!.*mobile))|(windows(?!.*phone)(.*touch))|kindle|playbook|silk)/i.test(ua) ||
      (isTouch && window.innerWidth >= 600 && window.innerWidth <= 1280);

    if (isTablet) {
      setDeviceType('Tablet');
    } else {
      setDeviceType('Laptop');
    }
  }, []);

  const handleJoin = (baseName) => {
    // Warm up AudioContext on direct user gesture to satisfy iOS Safari & Firefox autoplay policies
    const AudioContextClass = window.AudioContext || window.webkitAudioContext;
    if (AudioContextClass) {
      try {
        const dummyCtx = new AudioContextClass();
        dummyCtx.resume().then(() => {
          setTimeout(() => dummyCtx.close().catch(() => {}), 1500);
        }).catch(() => {});
      } catch (e) {}
    }

    const fullIdentity = `${baseName} (${deviceType})`;
    localStorage.setItem('token_server_url', serverUrl);
    onJoin({
      identity: fullIdentity,
      serverUrl: serverUrl.replace(/\/+$/, ''),
      passcode,
      deviceType,
    });
  };

  return (
    <div
      style={{
        width: '100vw',
        height: '100vh',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        backgroundColor: '#121013',
        backgroundImage:
          'radial-gradient(circle at 50% 30%, rgba(226, 132, 156, 0.12) 0%, transparent 70%)',
        padding: '16px',
      }}
    >
      <div
        style={{
          width: '100%',
          maxWidth: '430px',
          backgroundColor: '#1D171E',
          borderRadius: '28px',
          border: '1.5px solid rgba(226, 132, 156, 0.35)',
          padding: '36px 28px',
          boxShadow: '0 20px 50px rgba(0, 0, 0, 0.8), 0 0 40px rgba(226, 132, 156, 0.15)',
          textAlign: 'center',
        }}
      >
        {/* Heart Brand Icon */}
        <div
          className="pulse"
          style={{
            width: '64px',
            height: '64px',
            borderRadius: '50%',
            backgroundColor: 'rgba(226, 132, 156, 0.18)',
            border: '2px solid rgba(226, 132, 156, 0.4)',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            margin: '0 auto 16px',
            fontSize: '30px',
          }}
        >
          ❤️
        </div>

        <h1 style={{ fontSize: '22px', fontWeight: '800', marginBottom: '6px', color: '#FFFFFF' }}>
          TogetherStream
        </h1>
        <p style={{ fontSize: '13px', color: '#9CA3AF', marginBottom: '20px' }}>
          Private Watch-Together & Video Call for Pawan & Priya
        </p>

        {/* Device Switcher Pill */}
        <div
          style={{
            display: 'inline-flex',
            backgroundColor: '#121013',
            padding: '4px',
            borderRadius: '20px',
            border: '1px solid rgba(226, 132, 156, 0.25)',
            marginBottom: '24px',
            gap: '4px',
          }}
        >
          <button
            onClick={() => setDeviceType('Laptop')}
            style={{
              padding: '6px 16px',
              borderRadius: '16px',
              fontSize: '12px',
              fontWeight: '600',
              backgroundColor: deviceType === 'Laptop' ? '#E2849C' : 'transparent',
              color: deviceType === 'Laptop' ? '#FFFFFF' : '#9CA3AF',
              transition: 'all 0.2s',
            }}
          >
            💻 Laptop / Desktop
          </button>
          <button
            onClick={() => setDeviceType('Tablet')}
            style={{
              padding: '6px 16px',
              borderRadius: '16px',
              fontSize: '12px',
              fontWeight: '600',
              backgroundColor: deviceType === 'Tablet' ? '#E2849C' : 'transparent',
              color: deviceType === 'Tablet' ? '#FFFFFF' : '#9CA3AF',
              transition: 'all 0.2s',
            }}
          >
            📱 Tablet / iPad
          </button>
        </div>

        {/* Identity Cards */}
        <div style={{ display: 'flex', flexDirection: 'column', gap: '12px', marginBottom: '22px' }}>
          {/* Pawan Card */}
          <button
            onClick={() => handleJoin('Pawan')}
            style={{
              padding: '16px',
              borderRadius: '18px',
              backgroundColor: '#28202A',
              border: '1.5px solid rgba(226, 132, 156, 0.4)',
              color: '#FFFFFF',
              display: 'flex',
              alignItems: 'center',
              gap: '14px',
              textAlign: 'left',
              boxShadow: '0 4px 14px rgba(0,0,0,0.3)',
            }}
            onMouseEnter={(e) => (e.currentTarget.style.borderColor = '#E2849C')}
            onMouseLeave={(e) => (e.currentTarget.style.borderColor = 'rgba(226, 132, 156, 0.4)')}
          >
            <div
              style={{
                width: '42px',
                height: '42px',
                borderRadius: '50%',
                backgroundColor: 'rgba(226, 132, 156, 0.25)',
                border: '1.5px solid #E2849C',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                fontWeight: 'bold',
                color: '#F7A8BE',
                fontSize: '18px',
              }}
            >
              P
            </div>
            <div style={{ flex: 1 }}>
              <div style={{ fontWeight: '700', fontSize: '15px' }}>Join as Pawan</div>
              <div style={{ fontSize: '12px', color: '#9CA3AF' }}>
                {deviceType === 'Laptop' ? 'HP Laptop / Browser' : 'Tablet / iPad'}
              </div>
            </div>
            <span style={{ color: '#E2849C', fontSize: '18px' }}>➔</span>
          </button>

          {/* Priya Card */}
          <button
            onClick={() => handleJoin('Priya')}
            style={{
              padding: '16px',
              borderRadius: '18px',
              backgroundColor: '#28202A',
              border: '1.5px solid rgba(196, 181, 253, 0.4)',
              color: '#FFFFFF',
              display: 'flex',
              alignItems: 'center',
              gap: '14px',
              textAlign: 'left',
              boxShadow: '0 4px 14px rgba(0,0,0,0.3)',
            }}
            onMouseEnter={(e) => (e.currentTarget.style.borderColor = '#C4B5FD')}
            onMouseLeave={(e) => (e.currentTarget.style.borderColor = 'rgba(196, 181, 253, 0.4)')}
          >
            <div
              style={{
                width: '42px',
                height: '42px',
                borderRadius: '50%',
                backgroundColor: 'rgba(196, 181, 253, 0.25)',
                border: '1.5px solid #C4B5FD',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                fontWeight: 'bold',
                color: '#C4B5FD',
                fontSize: '18px',
              }}
            >
              P
            </div>
            <div style={{ flex: 1 }}>
              <div style={{ fontWeight: '700', fontSize: '15px' }}>Join as Priya</div>
              <div style={{ fontSize: '12px', color: '#9CA3AF' }}>
                {deviceType === 'Laptop' ? 'Laptop / Browser' : 'Tablet / iPad'}
              </div>
            </div>
            <span style={{ color: '#C4B5FD', fontSize: '18px' }}>➔</span>
          </button>
        </div>

        {/* Server & Room Info Toggle */}
        <button
          onClick={() => setShowConfig(!showConfig)}
          style={{
            background: 'none',
            color: '#E2849C',
            fontSize: '12px',
            marginBottom: '8px',
          }}
        >
          {showConfig ? 'Hide Connection Settings ▲' : 'Connection Settings ▼'}
        </button>

        {showConfig && (
          <div
            style={{
              marginTop: '10px',
              textAlign: 'left',
              display: 'flex',
              flexDirection: 'column',
              gap: '10px',
              backgroundColor: '#121013',
              padding: '14px',
              borderRadius: '14px',
            }}
          >
            <div>
              <label style={{ fontSize: '11px', color: '#9CA3AF' }}>Token Server URL</label>
              <input
                type="text"
                value={serverUrl}
                onChange={(e) => setServerUrl(e.target.value)}
                style={{
                  width: '100%',
                  padding: '8px 12px',
                  borderRadius: '10px',
                  backgroundColor: '#1D171E',
                  border: '1px solid #374151',
                  color: '#FFFFFF',
                  fontSize: '12px',
                  marginTop: '4px',
                }}
              />
            </div>

            <div>
              <label style={{ fontSize: '11px', color: '#9CA3AF' }}>Room Passcode</label>
              <input
                type="password"
                value={passcode}
                onChange={(e) => setPasscode(e.target.value)}
                style={{
                  width: '100%',
                  padding: '8px 12px',
                  borderRadius: '10px',
                  backgroundColor: '#1D171E',
                  border: '1px solid #374151',
                  color: '#FFFFFF',
                  fontSize: '12px',
                  marginTop: '4px',
                }}
              />
            </div>
          </div>
        )}

        <div style={{ fontSize: '12px', color: '#6B7280', marginTop: '16px' }}>
          Dedicated Room: <strong style={{ color: '#E2849C' }}>PP</strong> • HD WebRTC Stereo
        </div>
      </div>
    </div>
  );
}
