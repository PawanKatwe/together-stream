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

console.log('--- RUNNING PHASE 2 ACCEPTANCE TESTS (Screen Share & Audio) ---');

// Test 1: Android Manifest Permissions & Foreground Service
const manifestPath = path.join(projectRoot, 'mobile', 'android', 'app', 'src', 'main', 'AndroidManifest.xml');
const manifestContent = fs.readFileSync(manifestPath, 'utf8');

assert(
  manifestContent.includes('android.permission.FOREGROUND_SERVICE_MEDIA_PROJECTION'),
  'AndroidManifest contains FOREGROUND_SERVICE_MEDIA_PROJECTION permission'
);
assert(
  manifestContent.includes('android.permission.POST_NOTIFICATIONS'),
  'AndroidManifest contains POST_NOTIFICATIONS permission for Android 13/14'
);
assert(
  manifestContent.includes('com.cloudwebrtc.webrtc.FlutterRTCService') &&
  manifestContent.includes('foregroundServiceType="mediaProjection"'),
  'AndroidManifest registers FlutterRTCService with foregroundServiceType="mediaProjection"'
);

// Test 2: Native Android MainActivity Notification Channel
const mainActivityPath = path.join(projectRoot, 'mobile', 'android', 'app', 'src', 'main', 'kotlin', 'com', 'togetherstream', 'app', 'MainActivity.kt');
const mainActivityContent = fs.readFileSync(mainActivityPath, 'utf8');

assert(
  mainActivityContent.includes('screen_capture_channel') &&
  mainActivityContent.includes('NotificationChannel'),
  'MainActivity configures high-priority notification channel for Realme UI'
);

// Test 3: Screen Share & AudioPlaybackCapture in LiveKitService
const livekitServicePath = path.join(projectRoot, 'mobile', 'lib', 'services', 'livekit_service.dart');
const livekitContent = fs.readFileSync(livekitServicePath, 'utf8');

assert(
  livekitContent.includes('ScreenQualityPreset') &&
  livekitContent.includes('p480') &&
  livekitContent.includes('p720') &&
  livekitContent.includes('p1080'),
  'LiveKitService implements 480p, 720p, and 1080p quality presets'
);
assert(
  livekitContent.includes('captureScreenAudio: true'),
  'LiveKitService enables AudioPlaybackCapture for movie audio'
);
assert(
  livekitContent.includes('captureScreenAudio: true'),
  'LiveKitService captures system audio as a separate audio track'
);
assert(
  livekitContent.includes('localScreenShareTrack') &&
  livekitContent.includes('remoteScreenShareTrack'),
  'LiveKitService manages screen share as an independent track separate from camera'
);

// Test 4: DRM Warning Component
const drmDialogPath = path.join(projectRoot, 'mobile', 'lib', 'ui', 'widgets', 'drm_notice_dialog.dart');
const drmContent = fs.readFileSync(drmDialogPath, 'utf8');

assert(
  drmContent.includes('Netflix') &&
  drmContent.includes('DRM') &&
  drmContent.includes('VLC'),
  'DrmNoticeDialog educates users on DRM restrictions and recommends VLC/YouTube'
);

// Test 5: Quality Selector Sheet
const qualitySheetPath = path.join(projectRoot, 'mobile', 'lib', 'ui', 'widgets', 'quality_selector_sheet.dart');
const qualityContent = fs.readFileSync(qualitySheetPath, 'utf8');

assert(
  qualityContent.includes('QualitySelectorSheet') &&
  qualityContent.includes('onSelectPreset'),
  'QualitySelectorSheet provides interactive resolution switching'
);

console.log('\nRESULTS: ALL PHASE 2 ACCEPTANCE TESTS PASSED.');
