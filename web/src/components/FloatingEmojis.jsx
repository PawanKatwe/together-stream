import React, { useState, useEffect } from 'react';

export const AVAILABLE_EMOJIS = ['❤️', '😊', '😂', '🥺', '🔥', '👏'];

export function ReactionPicker({ onSelectEmoji, onClose }) {
  return (
    <div
      style={{
        backgroundColor: 'rgba(29, 23, 30, 0.94)',
        backdropFilter: 'blur(16px)',
        borderRadius: '32px',
        padding: '8px 16px',
        border: '1.5px solid rgba(226, 132, 156, 0.4)',
        boxShadow: '0 12px 32px rgba(0, 0, 0, 0.7)',
        display: 'flex',
        alignItems: 'center',
        gap: '10px',
        animation: 'fadeIn 0.2s ease forwards',
      }}
    >
      {AVAILABLE_EMOJIS.map((emoji) => (
        <button
          key={emoji}
          onClick={() => {
            onSelectEmoji(emoji);
          }}
          style={{
            background: 'none',
            fontSize: '26px',
            padding: '4px 6px',
            borderRadius: '16px',
            transition: 'transform 0.15s ease',
          }}
          onMouseEnter={(e) => (e.currentTarget.style.transform = 'scale(1.3)')}
          onMouseLeave={(e) => (e.currentTarget.style.transform = 'scale(1)')}
        >
          {emoji}
        </button>
      ))}
      <button
        onClick={onClose}
        style={{
          background: 'rgba(255, 255, 255, 0.1)',
          color: '#9CA3AF',
          borderRadius: '50%',
          width: '24px',
          height: '24px',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          fontSize: '12px',
          marginLeft: '4px',
        }}
      >
        ✕
      </button>
    </div>
  );
}

export function FloatingEmojiOverlay({ emojiBursts }) {
  if (!emojiBursts || emojiBursts.length === 0) return null;

  return (
    <div
      style={{
        position: 'absolute',
        top: 0,
        left: 0,
        right: 0,
        bottom: 0,
        pointerEvents: 'none',
        overflow: 'hidden',
        zIndex: 60,
      }}
    >
      {emojiBursts.map((item) => (
        <SingleFloatingEmoji key={item.id} item={item} />
      ))}
    </div>
  );
}

function SingleFloatingEmoji({ item }) {
  const [progress, setProgress] = useState(0);

  useEffect(() => {
    const startTime = performance.now();
    const duration = 2400; // 2.4 seconds

    let animId;
    const animate = (now) => {
      const elapsed = now - startTime;
      const p = Math.min(elapsed / duration, 1);
      setProgress(p);
      if (p < 1) {
        animId = requestAnimationFrame(animate);
      }
    };
    animId = requestAnimationFrame(animate);

    return () => cancelAnimationFrame(animId);
  }, []);

  const t = progress;
  // Sinusoidal horizontal sway
  const swayOffset = Math.sin(t * Math.PI * 3) * (item.sway || 40);
  const leftPercent = item.startX * 100;

  // Float from bottom 20% to top 85%
  const bottomPercent = 20 + (85 - 20) * t;

  // Opacity: fade in quickly, fade out at end
  let opacity = 1;
  if (t < 0.15) opacity = t / 0.15;
  else if (t > 0.65) opacity = (1 - t) / 0.35;
  opacity = Math.max(0, Math.min(1, opacity));

  // Pop scale
  const scale = (item.scale || 1) * (0.8 + 0.4 * Math.sin(t * Math.PI));

  return (
    <div
      style={{
        position: 'absolute',
        left: `calc(${leftPercent}% + ${swayOffset}px)`,
        bottom: `${bottomPercent}%`,
        opacity,
        transform: `scale(${scale})`,
        fontSize: '34px',
        transition: 'none',
        willChange: 'transform, opacity, bottom, left',
      }}
    >
      {item.emoji}
    </div>
  );
}
