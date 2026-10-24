# TogetherStream 🎬❤️

> Private watch-together video calling and screen-sharing app exclusively built for **Pawan & Priya**.

---

## 🌟 Quick Overview
- **Private Room:** `PP`
- **Passcode:** `PP@160227`
- **Users:** Pawan (Realme 9 Pro+) & Priya (Realme 9)
- **Visual Design:** Romantic Minimalist Dark Mode with Soft Rose Pink (`#E2849C`) accents.
- **Engine:** LiveKit WebRTC (sub-500ms real-time audio and video).

---

## 📁 Repository Structure
- `server/`: Lightweight Node.js token server with passcode authorization and 8-hour session minting.
- `mobile/`: Flutter Android application with camera, microphone, and watch-together canvas.
- `web/`: Chrome laptop companion app for tab sharing (Phase 4).
- `RULES.md`: Project invariants and operational guidelines.
- `scripts/`: Acceptance tests and build helpers.

---

## 🚀 Step 1: Deploy Token Server to Render (Free)
1. Go to **[render.com](https://render.com/)** and sign in.
2. Click **New +** > **Web Service**.
3. Connect this repository or choose **"Deploy from a public Git repository"** (or deploy via Docker).
   - **Root Directory:** `server`
   - **Build Command:** `npm install`
   - **Start Command:** `node index.js`
4. In the **Environment Variables** section, add:
   - `LIVEKIT_URL`: Your LiveKit WebSocket URL (e.g., `wss://together-xxxx.livekit.cloud`)
   - `LIVEKIT_API_KEY`: Your LiveKit API Key
   - `LIVEKIT_API_SECRET`: Your LiveKit API Secret
   - `APP_PASSCODE`: `PP@160227`
   - `ROOM_NAME`: `PP`
5. Click **Create Web Service**. Within 60 seconds, Render will provide a public HTTPS URL (e.g., `https://together-stream.onrender.com`).

---

## 🧪 Step 2: Test the Token Server Locally
From the project root:
```bash
# In one terminal, start the server:
cd server
npm install
npm start

# In another terminal, run automated acceptance tests:
node ../scripts/test_server.mjs
```
All 5 automated security and token tests will pass!

---

## 📱 Step 3: Installing & Testing on Your Realme Phones

### Building the APK
```bash
cd mobile
flutter build apk --release
```
The APK will be generated at:  
`mobile/build/app/outputs/flutter-apk/app-release.apk`

### Sideloading onto Realme 9 & Realme 9 Pro+
1. Transfer the `.apk` file to both phones via USB cable, Google Drive, or WhatsApp.
2. Tap the APK on your Realme phone.
3. If prompted:
   - Tap **Settings** -> Toggle **"Allow from this source"**.
   - Tap **Install**.
4. **Realme UI / ColorOS Settings (Important for background calls):**
   - Long press the TogetherStream app icon -> **App Info**.
   - Tap **Battery usage** -> Enable **"Allow background activity"** and **"Allow auto-launch"**.

### First Launch Checklist
1. Open the app on Phone 1:
   - Tap **"I am Pawan"**.
   - The app asks for Camera & Mic permissions -> Tap **"While using the app"**.
   - You will see your front camera feed and the message: *"Waiting for Priya..."*.
2. Open the app on Phone 2:
   - Tap **"I am Priya"**.
   - Grant permissions.
3. Both phones connect directly to room **PP** with crystal clear audio and video!
