import React, { useState } from 'react';

export default function Setup({ onJoin }) {
  const [identity, setIdentity] = useState('Pawan (Laptop)');
  const [serverUrl, setServerUrl] = useState(
    localStorage.getItem('token_server_url') || 'http://localhost:3000'
  );
  const [passcode, setPasscode] = useState('PP@160227');
  const [showConfig, setShowConfig] = useState(false);

  const handleJoin = (selectedIdentity) => {
    localStorage.setItem('token_server_url', serverUrl);
    onJoin({
      identity: selectedIdentity || identity,
      serverUrl: serverUrl.replace(/\/+$/, ''),
      passcode
    });
  };

  return (
    <div style={{
      width: '100vw',
      height: '100vh',
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'center',
      backgroundColor: '#121013',
      backgroundImage: 'radial-gradient(circle at 50% 30%, rgba(226, 132, 156, 0.08) 0%, transparent 70%)'
    }}>
      <div style={{
        width: '420px',
        backgroundColor: '#1D171E',
        borderRadius: '24px',
        border: '1.5px solid rgba(226, 132, 156, 0.3)',
        padding: '36px 32px',
        boxShadow: '0 16px 40px rgba(0, 0, 0, 0.7)',
        textAlign: 'center'
      }}>
        {/* Heart Brand Icon */}
        <div style={{
          width: '64px',
          height: '64px',
          borderRadius: '50%',
          backgroundColor: 'rgba(226, 132, 156, 0.15)',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          margin: '0 auto 18px',
          fontSize: '30px'
        }}>
          ❤️
        </div>

        <h1 style={{ fontSize: '22px', fontWeight: '700', marginBottom: '8px' }}>
          TogetherStream Cinema
        </h1>
        <p style={{ fontSize: '13px', color: '#9CA3AF', marginBottom: '28px' }}>
          Laptop Companion • Desktop Chrome
        </p>

        {/* Identity Cards */}
        <div style={{ display: 'flex', flexDirection: 'column', gap: '12px', marginBottom: '24px' }}>
          <button
            onClick={() => handleJoin('Pawan (Laptop)')}
            style={{
              padding: '16px',
              borderRadius: '16px',
              backgroundColor: '#28202A',
              border: '1.5px solid rgba(226, 132, 156, 0.4)',
              color: '#FFFFFF',
              display: 'flex',
              alignItems: 'center',
              gap: '14px',
              textAlign: 'left'
            }}
          >
            <div style={{
              width: '40px',
              height: '40px',
              borderRadius: '50%',
              backgroundColor: 'rgba(226, 132, 156, 0.25)',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              fontWeight: 'bold',
              color: '#F7A8BE'
            }}>
              P
            </div>
            <div>
              <div style={{ fontWeight: '600', fontSize: '15px' }}>Join as Pawan</div>
              <div style={{ fontSize: '12px', color: '#9CA3AF' }}>HP Laptop / Chrome</div>
            </div>
          </button>

          <button
            onClick={() => handleJoin('Priya (Laptop)')}
            style={{
              padding: '16px',
              borderRadius: '16px',
              backgroundColor: '#28202A',
              border: '1.5px solid rgba(196, 181, 253, 0.4)',
              color: '#FFFFFF',
              display: 'flex',
              alignItems: 'center',
              gap: '14px',
              textAlign: 'left'
            }}
          >
            <div style={{
              width: '40px',
              height: '40px',
              borderRadius: '50%',
              backgroundColor: 'rgba(196, 181, 253, 0.25)',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              fontWeight: 'bold',
              color: '#C4B5FD'
            }}>
              P
            </div>
            <div>
              <div style={{ fontWeight: '600', fontSize: '15px' }}>Join as Priya</div>
              <div style={{ fontSize: '12px', color: '#9CA3AF' }}>HP Laptop / Chrome</div>
            </div>
          </button>
        </div>

        {/* Server & Room Info Toggle */}
        <button
          onClick={() => setShowConfig(!showConfig)}
          style={{
            background: 'none',
            color: '#E2849C',
            fontSize: '12px',
            marginBottom: '10px'
          }}
        >
          {showConfig ? 'Hide Settings ▲' : 'Configure Server & Passcode ▼'}
        </button>

        {showConfig && (
          <div style={{
            marginTop: '10px',
            textAlign: 'left',
            display: 'flex',
            flexDirection: 'column',
            gap: '10px'
          }}>
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
                  backgroundColor: '#121013',
                  border: '1px solid #374151',
                  color: '#FFFFFF',
                  fontSize: '12px',
                  marginTop: '4px'
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
                  backgroundColor: '#121013',
                  border: '1px solid #374151',
                  color: '#FFFFFF',
                  fontSize: '12px',
                  marginTop: '4px'
                }}
              />
            </div>
          </div>
        )}

        <div style={{ fontSize: '12px', color: '#6B7280', marginTop: '16px' }}>
          Dedicated Room: <strong>PP</strong>
        </div>
      </div>
    </div>
  );
}
