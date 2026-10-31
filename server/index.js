import express from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import path from 'path';
import fs from 'fs';
import { fileURLToPath } from 'url';
import { AccessToken } from 'livekit-server-sdk';

dotenv.config();

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const publicPath = path.join(__dirname, 'public');

const app = express();
const port = process.env.PORT || 3000;

// Configuration from environment variables
const LIVEKIT_API_KEY = process.env.LIVEKIT_API_KEY;
const LIVEKIT_API_SECRET = process.env.LIVEKIT_API_SECRET;
const LIVEKIT_URL = process.env.LIVEKIT_URL;
const APP_PASSCODE = process.env.APP_PASSCODE || 'PP@160227';
const FIXED_ROOM_NAME = process.env.ROOM_NAME || 'PP';

app.use(cors());
app.use(express.json());

// Serve static TogetherStream Web App
app.use(express.static(publicPath));

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({
    status: 'ok',
    service: 'TogetherStream Token Server & Web App',
    room: FIXED_ROOM_NAME,
    timestamp: new Date().toISOString(),
  });
});

// App Remote Configuration endpoint (Server-Driven Config for emojis, phrases, etc.)
app.get('/config', (req, res) => {
  res.json({
    status: 'ok',
    version: '1.2.1',
    emojis: ['❤️', '😊', '😂', '🥺', '🔥', '👏'],
    quickPhrases: [
      'I love you ❤️',
      'Look at that! 😂',
      'So romantic 🥺',
      'Wait, what happened? 🍿',
      'Hold my hand 💕',
      'BRB, 1 sec! 🥤',
    ],
    roomName: FIXED_ROOM_NAME,
    timestamp: new Date().toISOString(),
  });
});

// Universal APK Download redirect endpoint
app.get('/download', async (req, res) => {
  try {
    const response = await fetch('https://api.github.com/repos/PawanKatwe/together-stream/releases/latest', {
      headers: { 'User-Agent': 'TogetherStream-Server' },
    });
    if (response.ok) {
      const data = await response.json();
      const apkAsset = data.assets?.find((a) => a.name.endsWith('.apk'));
      if (apkAsset && apkAsset.browser_download_url) {
        return res.redirect(apkAsset.browser_download_url);
      }
    }
  } catch (err) {
    console.error('Error fetching latest release:', err);
  }
  // Fallback to releases page
  res.redirect('https://github.com/PawanKatwe/together-stream/releases/latest');
});

// Primary Token Minting Endpoint
app.post('/token', async (req, res) => {
  try {
    const { identity, passcode } = req.body;

    // 1. Validate Secret Passcode
    if (!passcode || passcode !== APP_PASSCODE) {
      return res.status(401).json({
        error: 'Unauthorized: Invalid passcode',
      });
    }

    // 2. Validate Identity
    if (!identity || typeof identity !== 'string' || identity.trim().length === 0) {
      return res.status(400).json({
        error: 'Bad Request: Identity is required',
      });
    }

    const cleanIdentity = identity.trim();

    // 3. Verify Server LiveKit Credentials
    if (!LIVEKIT_API_KEY || !LIVEKIT_API_SECRET || !LIVEKIT_URL) {
      return res.status(500).json({
        error: 'Server Misconfiguration: LIVEKIT_API_KEY, LIVEKIT_API_SECRET, or LIVEKIT_URL is missing',
      });
    }

    // 4. Create Access Token with 8-Hour Lifetime
    const at = new AccessToken(LIVEKIT_API_KEY, LIVEKIT_API_SECRET, {
      identity: cleanIdentity,
      name: cleanIdentity,
      ttl: '8h', // 8 hours for movie dates
    });

    // Grant Room & Media Permissions
    at.addGrant({
      roomJoin: true,
      room: FIXED_ROOM_NAME,
      canPublish: true,
      canSubscribe: true,
      canPublishData: true,
    });

    const jwtToken = await at.toJwt();

    return res.json({
      token: jwtToken,
      url: LIVEKIT_URL,
      room: FIXED_ROOM_NAME,
      identity: cleanIdentity,
    });
  } catch (err) {
    console.error('Error generating token:', err);
    return res.status(500).json({
      error: 'Failed to mint token',
      details: err.message,
    });
  }
});

// Fallback GET route: Serve TogetherStream Web App index.html
app.get('*', (req, res) => {
  const indexPath = path.join(publicPath, 'index.html');
  if (fs.existsSync(indexPath)) {
    res.sendFile(indexPath);
  } else {
    res.json({
      message: 'TogetherStream private server running. POST /token to acquire an access token.',
    });
  }
});

app.listen(port, () => {
  console.log(`TogetherStream token server & web app listening on port ${port}`);
  console.log(`Configured Room: ${FIXED_ROOM_NAME}`);
});
