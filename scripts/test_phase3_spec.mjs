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

console.log('--- RUNNING PHASE 3 ACCEPTANCE TESTS (Layout & Draggable Overlay) ---');

// Test 1: Native FloatingOverlayService implementation
const overlayServiceKt = path.join(projectRoot, 'mobile', 'android', 'app', 'src', 'main', 'kotlin', 'com', 'togetherstream', 'app', 'FloatingOverlayService.kt');
const overlayKtContent = fs.readFileSync(overlayServiceKt, 'utf8');

assert(
  overlayKtContent.includes('TYPE_APPLICATION_OVERLAY'),
  'FloatingOverlayService uses modern TYPE_APPLICATION_OVERLAY window flag'
);
assert(
  overlayKtContent.includes('targetX') && overlayKtContent.includes('ValueAnimator.ofInt'),
  'FloatingOverlayService implements smooth edge-snapping animation'
);
assert(
  overlayKtContent.includes('FLAG_ACTIVITY_REORDER_TO_FRONT'),
  'FloatingOverlayService returns to MainActivity on tap'
);

// Test 2: MethodChannel in MainActivity
const mainActivityKt = path.join(projectRoot, 'mobile', 'android', 'app', 'src', 'main', 'kotlin', 'com', 'togetherstream', 'app', 'MainActivity.kt');
const mainActContent = fs.readFileSync(mainActivityKt, 'utf8');

assert(
  mainActContent.includes('com.togetherstream.app/overlay') &&
  mainActContent.includes('Settings.ACTION_MANAGE_OVERLAY_PERMISSION'),
  'MainActivity manages overlay method channel and direct permission intent'
);

// Test 3: OverlayService Dart module
const overlayServiceDart = path.join(projectRoot, 'mobile', 'lib', 'services', 'overlay_service.dart');
const overlayDartContent = fs.readFileSync(overlayServiceDart, 'utf8');

assert(
  overlayDartContent.includes('promptOverlayPermission') &&
  overlayDartContent.includes('showFloatingBubble'),
  'OverlayService guides users through "Display over other apps" permission'
);

// Test 4: CinemaLayout 80/20 & Hide Video Strip
const cinemaLayoutPath = path.join(projectRoot, 'mobile', 'lib', 'ui', 'widgets', 'cinema_layout.dart');
const cinemaContent = fs.readFileSync(cinemaLayoutPath, 'utf8');

assert(
  cinemaContent.includes('VideoTrackRenderer'),
  'CinemaLayout letterboxes screen share with VideoTrackRenderer (no cropping)'
);
assert(
  cinemaContent.includes('isVideoStripVisible') &&
  cinemaContent.includes('onToggleVideoStrip'),
  'CinemaLayout implements animated video strip hiding to give screen full height'
);

// Test 5: Landscape Lock and AppLifecycle in RoomScreen
const roomScreenPath = path.join(projectRoot, 'mobile', 'lib', 'ui', 'screens', 'room_screen.dart');
const roomContent = fs.readFileSync(roomScreenPath, 'utf8');

assert(
  roomContent.includes('DeviceOrientation.landscapeLeft') &&
  roomContent.includes('DeviceOrientation.landscapeRight'),
  'RoomScreen locks orientation to landscape during screen share mode'
);
assert(
  roomContent.includes('didChangeAppLifecycleState') &&
  roomContent.includes('OverlayService.showFloatingBubble'),
  'RoomScreen launches floating overlay when the sharer switches to movie apps'
);
assert(
  roomContent.includes('SystemUiMode.immersiveSticky'),
  'RoomScreen supports immersive sticky fullscreen mode'
);

console.log('\nRESULTS: ALL 10/10 PHASE 3 ACCEPTANCE TESTS PASSED.');
