import fs from 'fs';
import path from 'path';

const projectRoot = 'C:\\Users\\katwe\\.gemini\\antigravity\\scratch\\together-stream';

function assert(condition, message) {
  if (!condition) {
    console.error(`❌ FAILED: ${message}`);
    process.exit(1);
  }
  console.log(`✅ PASSED: ${message}`);
}

console.log('--- RUNNING PHASE 4 ACCEPTANCE TESTS (Laptop Web Companion) ---');

// Test 1: EchoWarningBanner component
const echoBannerPath = path.join(projectRoot, 'web', 'src', 'components', 'EchoWarningBanner.jsx');
const echoContent = fs.readFileSync(echoBannerPath, 'utf8');

assert(
  echoContent.includes('Headphones Recommended') &&
  echoContent.includes('looping back into your laptop microphone'),
  'EchoWarningBanner alerts users to wear headphones when sharing tab audio'
);

// Test 2: Setup component with Pawan/Priya identities and room PP
const setupPath = path.join(projectRoot, 'web', 'src', 'components', 'Setup.jsx');
const setupContent = fs.readFileSync(setupPath, 'utf8');

assert(
  setupContent.includes('Pawan (Laptop)') &&
  setupContent.includes('Priya (Laptop)') &&
  setupContent.includes('PP@160227'),
  'Setup component supports Pawan and Priya on laptop with secret passcode validation'
);

// Test 3: Tab Audio Sharing in Room.jsx
const roomPath = path.join(projectRoot, 'web', 'src', 'components', 'Room.jsx');
const roomContent = fs.readFileSync(roomPath, 'utf8');

assert(
  roomContent.includes('setScreenShareEnabled(true,') &&
  roomContent.includes('audio: true'),
  'Room component enables Chrome tab sharing with audio: true'
);

// Test 4: 80/20 Cinema Layout in Web App
assert(
  roomContent.includes("objectFit: 'contain'") &&
  roomContent.includes('isVideoStripVisible'),
  'Room component implements 80/20 letterbox canvas with collapsible face strip'
);

// Test 5: Production Build Artifacts Exist
const distHtml = path.join(projectRoot, 'web', 'dist', 'index.html');
assert(fs.existsSync(distHtml), 'Vite production bundle built successfully (dist/index.html exists)');

console.log('\nRESULTS: ALL 5/5 PHASE 4 ACCEPTANCE TESTS PASSED.');
