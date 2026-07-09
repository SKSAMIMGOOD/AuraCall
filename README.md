# AuraCall – Next Generation AI Calling Application

AuraCall is a premium flagship Android calling application inspired by Apple, Nothing OS, and Material You design systems. Built with Flutter, Riverpod, and Clean Architecture, it integrates Google Gemini AI to bring intelligent communication features like real-time spam detection, voice translation, automatic summaries, and semantic contacts search.

## 🌟 Key Features

1. **Incoming Call Gesture Controls**: Gesture-driven (Swipe left to Decline, Swipe right to Accept, Swipe up to Send Quick SMS, Swipe down for Calendar Reminders) with spring physics.
2. **Active Call Waveform & Notes**: Encrypted call notes, live voice waveform animations, call clock timer, speaker/mute controllers.
3. **Gemini AI Call Assistant Drawer**: Real-time voice-to-text transcriptions and live translations displayed side-by-side inside the active call.
4. **Smart T9 Dialer**: Glass numeric keys with T9 predictive contacts search based on alphabet letters mapped to digits.
5. **Contact Profiles & Analytics**: High-quality contact detail cards with shared notes, messaging handles, call history timeline, and visual chart reports of call frequency.
6. **AI Spam Shield**: Risk evaluations and trust rating indicator cards powered by LLM community reports lookup.
7. **Gemini Voicemail Player**: Simulated voicemail scrubbing player, unread badges, transcripts, and AI-generated voicemail summaries.
8. **Settings & Biometric Security**: Fingerprint/Face ID lock, AMOLED dark mode/light glass themes, dynamic accent selectors, and Gemini API Credentials.

---

## 🛠️ Tech Stack & Architecture

- **Framework**: Flutter (Latest Stable)
- **State Management**: Riverpod
- **Architecture**: Feature-Based Clean Architecture (`data`, `domain`, `presentation`)
- **Local Cache**: Hive (No-SQL database)
- **AI Engine**: Google Gemini API (`google_generative_ai`)
- **Charts Engine**: FL Chart (`fl_chart`)
- **Security Lock**: Local Authentication (`local_auth`)

---

## 📂 Project Folder Structure

```
lib/
├── main.dart                      # App entry point, registers Hive & Riverpod
├── core/
│   ├── theme/
│   │   └── app_theme.dart         # Glassmorphic themes (AMOLED Dark / Light Glass)
│   ├── widgets/
│   │   └── glass_widgets.dart     # Frosted glass, Ripple pulsating, Waveform animations
│   ├── models/
│   │   ├── contact_model.dart     # Contact Entity
│   │   ├── call_log_model.dart    # Call Log History Entity
│   │   └── voicemail_model.dart   # Voicemail metadata Entity
│   ├── services/
│   │   ├── local_db.dart          # Hive Database Service with auto-seed mock data
│   │   └── gemini_service.dart    # Gemini API Client for Spam, transcripts, translation
│   └── providers/
│       └── app_providers.dart     # Riverpod State Providers & Call Controllers
└── features/
    ├── splash/                    # Animated splash logo & Permission authorization
    ├── home/                      # Persistent glass bottom navigation bar shell
    ├── call/                      # Outgoing ring, active, and gesture incoming overlays
    ├── contacts/                  # Alphabet list scroller, detail analytics & notes
    ├── dialpad/                   # T9 dial pad keys & predictions
    ├── recents/                   # Call timeline history logs
    ├── favorites/                 # Categorized pinned grid dashboard
    ├── ai/                        # Natural Language search & AI safety ratings
    ├── voicemail/                 # Audio players, transcripts & voicemail summaries
    └── settings/                  # Accent pickers, biometrics & Gemini key configuration
```

---

## 🚀 Setup & Execution Guide

### Prerequisites
Make sure you have the following installed on your machine:
- Flutter SDK (version `>= 3.2.0`)
- Android Studio / VS Code (with Flutter extension)
- Android Emulator / Physical Device running Android API 23+

### Step-by-Step Installation

1. **Clone the repository** (or navigate to this folder):
   ```bash
   cd "c:\Users\SK MD SAMIM\OneDrive\Desktop\apna call"
   ```

2. **Get dependencies**:
   ```bash
   flutter pub get
   ```

3. **Generate Assets Directory**:
   Create a folder for local media if required:
   ```bash
   mkdir -p assets/images
   ```

4. **Run the Application**:
   Connect your simulator or device and execute:
   ```bash
   flutter run
   ```

5. **Configure Gemini API Key**:
   - Navigate to the **Settings** tab in the app.
   - Go to **Gemini API Integration**.
   - Input your Google AI Studio API Key (AIzaSy...) and tap **Update Key**.
   - You can get your key for free from [Google AI Studio](https://aistudio.google.com/).

---

## 🔒 Firebase Integration Setup

To link your Firebase database for online syncing, FCM notifications, and SMS/Google authentication:

1. **Install FlutterFire CLI** (if not done):
   ```bash
   dart pub global activate flutterfire_cli
   ```
2. **Configure Firebase**:
   Run configuration script in root project directory:
   ```bash
   flutterfire configure
   ```
3. **Register App**: Select your Google Cloud platform project. This will automatically inject `firebase_options.dart` into your `lib/` directory.
4. **Enable Services in Console**:
   - Go to Firebase Console -> Authentication -> Enable **Phone SMS** & **Google Sign-In**.
   - Go to Cloud Firestore -> Enable database and define read/write rules.
   - Configure Firebase Cloud Messaging (FCM) for call ringing notifications.

---

## 🗺️ Future Roadmap

- [ ] **Real Call Dialer Integration**: Bind android native `Telecom` API framework connection to handle actual cellular network phone calls rather than mocked sessions.
- [ ] **Vibrant Liquid Shader Effects**: Introduce custom GLSL fragment shaders to render liquid distortion wave physics during drag gestures.
- [ ] **Dual-SIM Support**: Dynamic SIM toggle card inside dialer and active calls.
- [ ] **Wear OS Companion**: Sync favorites and trigger calls directly from Android Smartwatches.
