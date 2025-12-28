# liu_stoma 🚀

A small Flutter app to help dentists manage patients, appointments, and payments. It's primarily in Romanian and was built for a practical, low-friction workflow (no Stripe—cash/manual payments supported).

---

## Table of contents 📋

- **Prerequisites**
- **Setup**
- **Run (dev)**
- **Build (release)**
- **Backend functions (Firebase)**
- **Tests & linting**
- **Troubleshooting**

---

## Prerequisites ✅

- Flutter (stable channel). This project requires a Dart SDK compatible with `^3.8.1` (see `pubspec.yaml`).
- Android Studio / Xcode (for platform tooling and emulators/simulators).
- Android SDK & platform-tools (set via Android Studio).
- CocoaPods (for iOS/macOS): `sudo gem install cocoapods` (or use Homebrew).
- Node.js (v20 recommended) and npm (used by `functions/`).
- Firebase CLI (optional, for emulators & deploys): `npm install -g firebase-tools`.

> Note: `android/app/google-services.json` is present in the repository—verify it's the correct config for your Firebase project. For iOS, ensure your `GoogleService-Info.plist` is configured if you plan to run on iOS.

---

## Setup 🛠️

1. Clone the repo and open it:

```bash
git clone <repo-url>
cd liu_stoma
```

2. Install Dart/Flutter dependencies:

```bash
flutter pub get
```

3. Platform-specific setup:

- iOS (macOS only):
  ```bash
  cd ios
  pod install
  cd ..
  ```

- Android: ensure `ANDROID_HOME`/`local.properties` is configured by Android Studio or set `sdk.dir` in `android/local.properties`.

4. (Optional) Install functions dependencies for local function emulation:

```bash
cd functions
npm install
cd ..
```

---

## Run (development) ▶️

- Run on the default connected device/emulator:

```bash
flutter run
```

- Run on a specific device (emulator or connected device):

```bash
flutter devices
flutter run -d <device-id>
```

- Run for web (Chrome):

```bash
flutter run -d chrome
```

- If you want to use Firebase local emulators for functions/pubsub:

```bash
cd functions
npm run serve
# this runs TypeScript build then starts the firebase emulators for functions and pubsub
```

> Tip: You can also run `npm run shell` to build and get an interactive functions shell.

---

## Build (release) 📦

- Android (APK):

```bash
flutter build apk --release
```

- Android App Bundle (for Play Store):

```bash
flutter build appbundle
```

- iOS (archive):

```bash
flutter build ipa
# or open Xcode and archive from Runner workspace for App Store distribution
```

- macOS:

```bash
flutter build macos
```

- Web:

```bash
flutter build web
```

---

## Backend functions (Firebase) ⚙️

In `functions/` you'll find TypeScript-based Cloud Functions. Useful npm scripts (see `package.json`):

- `npm run build` — compile TypeScript
- `npm run serve` — build + firebase emulators (functions & pubsub)
- `npm run shell` — build + functions shell
- `npm run deploy` — deploy functions to Firebase

If your functions require secrets (Twilio, environment settings, etc.), create a `.env` in `functions/` or set them in your Firebase project and locally as needed. Use `dotenv` or Firebase environment configs as appropriate.

---

## Tests & linting ✅

- Run unit/widget tests:

```bash
flutter test
```

- Run static analysis:

```bash
flutter analyze
```

---

## Troubleshooting & tips ⚠️

- If iOS build fails, run `pod install` in `ios/` and ensure you opened the workspace in Xcode.
- If Android emulator doesn't start, verify Android SDK and images are installed via Android Studio → AVD Manager.
- Missing Firebase config errors: check presence of `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) and that they match your Firebase project.
- If functions fail on startup, ensure Node version matches `functions/package.json` (`engines.node` = 20) and run `npm run build` to compile first.

---

## Contributing & contact ✨

- Small PRs and issues are welcome. If you file a bug report, include reproduction steps and relevant logs.


<img width="1624" height="977" alt="ss1" src="https://github.com/user-attachments/assets/a660c794-1fab-4da1-8313-3e5245e7f2e1" />

<img width="1512" height="949" alt="welcome-page" src="https://github.com/user-attachments/assets/c1f1ac57-eeee-4a75-a085-f21746452254" />
