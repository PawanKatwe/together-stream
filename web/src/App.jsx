import React, { useState } from 'react';
import Setup from './components/Setup';
import Room from './components/Room';

export default function App() {
  const [connectionConfig, setConnectionConfig] = useState(null);

  const handleJoin = (config) => {
    setConnectionConfig(config);
  };

  const handleLeave = () => {
    setConnectionConfig(null);
  };

  return connectionConfig ? (
    <Room connectionConfig={connectionConfig} onLeave={handleLeave} />
  ) : (
    <Setup onJoin={handleJoin} />
  );
}
