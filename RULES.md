# RULES.md - TogetherStream Project Operational Rules & Conventions

## 1. Project Identity & Context
- **Product:** TogetherStream (Private Couple Cinema & Video Calling App)
- **Users:** Exactly two private users — **Pawan** and **Priya**.
- **Fixed Room Name:** `PP`
- **Shared Passcode:** `PP@160227`
- **Devices:** 
  - Realme 9 Pro Plus (Realme UI / Android)
  - Realme 9 (Realme UI / Android)
  - Laptop: Chrome desktop browser (Web Companion)
- **Deployment & Distribution:** Sideloaded Android APK (no Google Play Store) + Render free tier for Node.js token server.
- **Visual Design:** Romantic Minimalist Dark Theme with Soft Rose/Blush Pink accents (`#E2849C`).

---

## 2. Tech Stack Invariants
- **Android App:** Flutter (Dart), minimum Android 10 (API 29), target latest stable Android SDK.
- **Real-Time Video/Audio Engine:** LiveKit Cloud via the official `livekit_client` Flutter package and `livekit-client` JS SDK for web.
- **Token Server:** Node.js + Express with `livekit-server-sdk`. Single endpoint `POST /token` returning a short-lived room token (8 hours) protected by passcode check.
- **Web App:** React + Vite + `livekit-client` for desktop Chrome.

---

## 3. Working & Development Rules
1. **Phase-by-Phase Discipline:**
   - Build strictly ONE phase at a time.
   - At the end of each phase: run the app/service, run acceptance tests, fix all issues, provide proof (logs, test checklist), and wait for user approval ("next phase") before starting the next phase.
2. **Never Break Working Code:**
   - Small, clean, atomic commits with clear messages.
   - Never leave the repository in a broken state.
   - Do not re-architect or refactor working modules without explicit justification and user approval.
3. **No Unrequested Features:**
   - Keep strictly to the specified phase deliverables.
4. **Accessible Communication:**
   - Explain all concepts clearly and simply (user has a data/finance background in SQL/Power BI/Python).
   - Provide exact, foolproof steps to build, sideload, and test the APK on physical Realme phones.
5. **Real-World Android Awareness:**
   - Acknowledge Realme UI / ColorOS battery management restrictions (e.g. "Allow background activity", "Autostart", "Display over other apps").
   - Explicitly guide the user when Android system restrictions (e.g. DRM protection on Netflix/Prime/Hotstar) prevent screen capture; never attempt illegal DRM bypass.
6. **Anti-Looping Rule:**
   - If the same error occurs 3 times in a row, stop immediately, summarize the root cause, and propose two alternative paths forward.

---

## 4. Phase Roadmap
- **Phase 1 – Foundation:** Token server with passcode auth, Flutter app with identity setup (Pawan / Priya), 2-party video/mic call, toggles (cam/mic/flip), auto-reconnect. (COMPLETED)
- **Phase 2 & 3 – In-App Dedicated Media Cinema:** 
  - Top ~80% dedicated In-App Media Player replacing OS screen sharing.
  - Hybrid Media Engine: Local video files (MP4, MKV) via device storage picker + YouTube streaming URL playback.
  - Sub-100ms playback synchronization (Play, Pause, Seek/Scrub) via LiveKit Reliable Data Channel.
  - Bottom ~20% reaction face strip with live camera feeds & mute indicators for Pawan & Priya.
  - Auto-hiding controls (3 seconds).
- **Phase 4 – Laptop Web Companion:** React + Vite web companion for laptop with matching media sync and camera calling. (COMPLETED)
- **Phase 5 – Couple Features:** Synchronized floating emoji reactions (❤️, 😂, 💋), movie chat with 10s auto-fade, next-visit countdown with celebration sparkles, double-camera Polaroid snapshot to gallery, "Thinking of you" heartbeat vibration, "BRB" banner.
