# 💬 Flutter Chat UI (WhatsApp style)

<img src="docs/screens.svg?v=1" alt="App screens" width="100%">

<sub>Preview: design illustration of the screens, in the light theme. Run the app to see the real thing.</sub>

A free Flutter template for a WhatsApp-style messenger: chats and calls tabs, **voice and video call screens**, **photos**, **voice messages** you record and play, **location sharing** and read receipts (✓ ✓✓ and blue ✓✓). Material 3, light and dark themes. It is the Flutter version of [Chatly for React](https://github.com/lenivalestevao/react-chat-ui).

## Features

- **Chats tab**: avatars, preview ("📷 Photo", "🎤 0:14", "📍 Location"), time, unread badges, live search
- **Calls tab**: call history (incoming, outgoing, missed) with a "Call again" button
- **Voice call and video call screens**: ringing, connected timer, mute, speaker, camera on/off, end call. Every call is added to the chat and to the Calls tab
- **Photos**: pick from the gallery or take one with the camera, tap to open full screen with pinch to zoom
- **Voice messages**: tap the mic to record, send or discard, play with a waveform and progress
- **Location**: share your current position as a map card with coordinates
- **Read receipts**: one grey tick, two grey ticks, two blue ticks
- **Typing indicator** and a simulated reply for every kind of message
- **Adaptive**: two panes on tablets, desktop and web; list, then thread on phones
- Light and dark themes generated from one seed color

> **Calls are a UI simulation.** The screens, the timer and the call log work, but no audio or video travels between devices. See "Real calls" below.

## Run it

```bash
flutter create . --platforms=android,ios,web
flutter pub get
flutter run
```

`flutter create .` only adds the platform folders and keeps this repo's `lib/` and `pubspec.yaml`. Needs Flutter 3.32 or newer. Run the tests with `flutter test`.

## Platform setup (needed for photos, voice and location)

**Android**: add to `android/app/src/main/AndroidManifest.xml`, inside `<manifest>`:

```xml
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
```

**iOS**: add to `ios/Runner/Info.plist`:

```xml
<key>NSMicrophoneUsageDescription</key><string>Record voice messages</string>
<key>NSCameraUsageDescription</key><string>Take photos to send</string>
<key>NSPhotoLibraryUsageDescription</key><string>Choose photos to send</string>
<key>NSLocationWhenInUseUsageDescription</key><string>Share your location in a chat</string>
```

Without these, the app still runs; the attach and mic buttons just show a short message when permission is missing.

## Packages

| Package | Used for |
|---|---|
| `image_picker` | Gallery and camera |
| `record` | Recording voice messages |
| `audioplayers` | Playing voice messages |
| `geolocator` | Current location |
| `path_provider` | Temporary folder for recordings |

All device access sits behind one small interface, `MediaService`. The app uses `DeviceMediaService`; the tests use a fake, so they run without a phone.

## Structure

| Path | Purpose |
|---|---|
| `lib/main.dart` | App entry, theme and store |
| `lib/core/` | Theme, formatting, `ChatScope`, avatar, badge and typing dots |
| `lib/data/models.dart` | `Message` (text, image, audio, location, call), `Conversation`, `CallInfo` |
| `lib/data/chat_store.dart` | State: search, send, ticks, voice playback, call log, theme |
| `lib/data/seed.dart` | Demo conversations and canned replies |
| `lib/services/` | `MediaService` interface and the real `DeviceMediaService` |
| `lib/features/` | Home shell, chats and calls tabs, chat pane, bubbles, composer, call screen, image viewer |
| `test/` | Logic and UI tests with a fake `MediaService` |

## Make it yours

1. Change `brand` in `lib/core/theme.dart` and the name in `lib/main.dart`.
2. Edit the demo data in `lib/data/seed.dart`, or start empty with `ChatStore(media: ..., demo: false)`.
3. Connect a backend: replace the `Timer`s in `ChatStore._post` with your API or WebSocket, and call `_append` when a message arrives. Upload photos and audio files, and store the URL in the message.
4. Show a real map in `_LocationBody` (for example with `flutter_map`).
5. Save chats between launches with `shared_preferences` or a local database.

## Real calls

To carry real audio and video, put a call SDK inside `CallScreen` (`lib/features/call_screen.dart`): `flutter_webrtc` with your own signaling server, or a hosted service such as LiveKit or Agora. Keep `store.logCall(...)` when the call ends so the history keeps working.

## License

MIT. Free for personal and commercial use.
