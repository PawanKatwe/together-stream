import React, { useEffect, useState, useRef } from 'react';
import { RoomEvent } from 'livekit-client';

function SingleAudioElement({ track }) {
  const audioRef = useRef(null);

  useEffect(() => {
    const el = audioRef.current;
    if (!el || !track) return;

    track.attach(el);

    // Explicitly trigger play to request browser audio playback
    const playPromise = el.play();
    if (playPromise !== undefined) {
      playPromise.catch((err) => {
        // Expected when browser policy requires an initial user interaction
        console.warn('Browser autoplay paused audio track, waiting for gesture:', err?.message || err);
      });
    }

    return () => {
      try {
        track.detach(el);
      } catch (e) {
        // ignore on unmount
      }
    };
  }, [track]);

  return (
    <audio
      ref={audioRef}
      autoPlay
      playsInline
      style={{
        position: 'absolute',
        left: '-9999px',
        top: '-9999px',
        width: '1px',
        height: '1px',
        opacity: 0.01,
        pointerEvents: 'none',
        overflow: 'hidden',
      }}
    />
  );
}

export default function RemoteAudioRenderer({ room }) {
  const [subscribedAudioTracks, setSubscribedAudioTracks] = useState([]);

  useEffect(() => {
    if (!room) return;

    function refreshAudioTracks() {
      const list = [];
      for (const p of room.remoteParticipants.values()) {
        for (const pub of p.audioTrackPublications.values()) {
          if (pub.track && pub.isSubscribed) {
            list.push({
              key: pub.trackSid || `${p.identity}_${pub.source}_${list.length}`,
              track: pub.track,
            });
          }
        }
      }
      setSubscribedAudioTracks(list);
    }

    refreshAudioTracks();

    room
      .on(RoomEvent.TrackSubscribed, refreshAudioTracks)
      .on(RoomEvent.TrackUnsubscribed, refreshAudioTracks)
      .on(RoomEvent.ParticipantConnected, refreshAudioTracks)
      .on(RoomEvent.ParticipantDisconnected, refreshAudioTracks);

    return () => {
      room
        .off(RoomEvent.TrackSubscribed, refreshAudioTracks)
        .off(RoomEvent.TrackUnsubscribed, refreshAudioTracks)
        .off(RoomEvent.ParticipantConnected, refreshAudioTracks)
        .off(RoomEvent.ParticipantDisconnected, refreshAudioTracks);
    };
  }, [room]);

  // Keep in the render tree off-screen (never use display:none which suspends WebKit on iPad Safari)
  return (
    <div
      style={{
        position: 'absolute',
        left: '-9999px',
        top: '-9999px',
        width: '1px',
        height: '1px',
        overflow: 'hidden',
        pointerEvents: 'none',
      }}
    >
      {subscribedAudioTracks.map(({ key, track }) => (
        <SingleAudioElement key={key} track={track} />
      ))}
    </div>
  );
}
