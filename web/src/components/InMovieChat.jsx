import React, { useState } from 'react';

const QUICK_PHRASES = [
  'I love you ❤️',
  'Look at that! 😂',
  'So romantic 🥺',
  'Wait, what happened? 🍿',
  'Hold my hand 💕',
  'BRB, 1 sec! 🥤',
];

export function InMovieChatOverlay({ messages }) {
  if (!messages || messages.length === 0) return null;

  // Show up to the last 3 visible messages
  const visible = messages.slice(-3);

  return (
    <div
      style={{
        position: 'absolute',
        bottom: '90px',
        left: '20px',
        zIndex: 50,
        pointerEvents: 'none',
        display: 'flex',
        flexDirection: 'column',
        gap: '8px',
        maxWidth: '340px',
      }}
    >
      {visible.map((msg) => (
        <div
          key={msg.id}
          className="fade-in"
          style={{
            backgroundColor: 'rgba(0, 0, 0, 0.78)',
            backdropFilter: 'blur(8px)',
            borderRadius: '16px',
            border: `1.2px solid ${
              msg.isMe ? 'rgba(226, 132, 156, 0.6)' : 'rgba(196, 181, 253, 0.6)'
            }`,
            padding: '8px 14px',
            color: '#FFFFFF',
            fontSize: '13px',
            boxShadow: '0 4px 12px rgba(0,0,0,0.4)',
            lineHeight: '1.4',
          }}
        >
          <strong
            style={{
              color: msg.isMe ? '#E2849C' : '#C4B5FD',
              marginRight: '6px',
            }}
          >
            {msg.sender}:
          </strong>
          <span>{msg.text}</span>
        </div>
      ))}
    </div>
  );
}

export function InMovieChatModal({ partnerName, onSendMessage, onClose }) {
  const [text, setText] = useState('');

  const handleSubmit = (e) => {
    e?.preventDefault();
    if (!text.trim()) return;
    onSendMessage(text.trim());
    setText('');
    onClose();
  };

  const handlePhraseClick = (phrase) => {
    onSendMessage(phrase);
    onClose();
  };

  return (
    <div
      style={{
        position: 'fixed',
        inset: 0,
        backgroundColor: 'rgba(0, 0, 0, 0.6)',
        backdropFilter: 'blur(4px)',
        zIndex: 100,
        display: 'flex',
        alignItems: 'flex-end',
        justifyContent: 'center',
        paddingBottom: '24px',
      }}
      onClick={onClose}
    >
      <div
        style={{
          width: '92%',
          maxWidth: '500px',
          backgroundColor: 'rgba(29, 23, 30, 0.96)',
          backdropFilter: 'blur(16px)',
          borderRadius: '24px',
          border: '1.5px solid rgba(226, 132, 156, 0.4)',
          padding: '20px 22px',
          boxShadow: '0 16px 40px rgba(0, 0, 0, 0.8)',
          color: '#FFFFFF',
        }}
        onClick={(e) => e.stopPropagation()}
      >
        {/* Header */}
        <div
          style={{
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'space-between',
            marginBottom: '14px',
          }}
        >
          <div style={{ display: 'flex', alignItems: 'center', gap: '8px', fontWeight: 'bold', fontSize: '15px' }}>
            <span>❤️</span>
            <span>Whisper to {partnerName}</span>
          </div>
          <button
            onClick={onClose}
            style={{
              background: 'none',
              color: '#9CA3AF',
              fontSize: '18px',
              padding: '4px',
            }}
          >
            ✕
          </button>
        </div>

        {/* Quick Phrases */}
        <div
          style={{
            display: 'flex',
            gap: '8px',
            overflowX: 'auto',
            paddingBottom: '12px',
            marginBottom: '14px',
            scrollbarWidth: 'none',
          }}
        >
          {QUICK_PHRASES.map((phrase) => (
            <button
              key={phrase}
              onClick={() => handlePhraseClick(phrase)}
              style={{
                backgroundColor: '#28202A',
                border: '1px solid rgba(226, 132, 156, 0.3)',
                color: '#FFFFFF',
                borderRadius: '16px',
                padding: '6px 12px',
                fontSize: '12px',
                whiteSpace: 'nowrap',
                flexShrink: 0,
              }}
              onMouseEnter={(e) => (e.currentTarget.style.borderColor = '#E2849C')}
              onMouseLeave={(e) => (e.currentTarget.style.borderColor = 'rgba(226, 132, 156, 0.3)')}
            >
              {phrase}
            </button>
          ))}
        </div>

        {/* Text Input */}
        <form onSubmit={handleSubmit} style={{ display: 'flex', gap: '10px' }}>
          <input
            type="text"
            value={text}
            onChange={(e) => setText(e.target.value)}
            placeholder="Type a loving message..."
            autoFocus
            style={{
              flex: 1,
              backgroundColor: '#181219',
              border: '1px solid rgba(226, 132, 156, 0.25)',
              borderRadius: '20px',
              padding: '12px 18px',
              color: '#FFFFFF',
              fontSize: '14px',
              outline: 'none',
            }}
          />
          <button
            type="submit"
            style={{
              backgroundColor: '#E2849C',
              color: '#FFFFFF',
              borderRadius: '20px',
              padding: '0 20px',
              fontWeight: 'bold',
              fontSize: '14px',
              display: 'flex',
              alignItems: 'center',
              gap: '6px',
            }}
          >
            Send 💌
          </button>
        </form>
      </div>
    </div>
  );
}
