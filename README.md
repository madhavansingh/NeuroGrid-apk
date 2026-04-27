<div align="center">

# 🌆 NeuroGrid — Smart City Mobile App

**AI-powered citizen engagement platform for smarter urban living**

[![Flutter](https://img.shields.io/badge/Flutter-3.22+-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.4+-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

</div>

---

## 📱 Overview

NeuroGrid is a production-grade Flutter application that connects citizens to their city's pulse. It surfaces real-time traffic, waste schedules, civic issues, parking availability, weather, and AI-driven city summaries — all in one premium mobile experience.

### Key Features

| Feature | Description |
|---|---|
| 🚦 **Live Traffic** | Real-time congestion status from TomTom API |
| 🗑️ **Waste Pickup** | Schedule tracking and zone-based updates |
| 🚨 **Civic Issues** | Submit and track reports with photo uploads |
| 🅿️ **Parking Zones** | Live zone availability |
| 🤖 **AI City Summary** | GPT/Gemini-powered city briefings |
| 🌦️ **Weather** | OpenWeatherMap integration |
| 🗺️ **Map** | Google Maps with city overlays |
| 👤 **Profile** | Google OAuth authentication |

---

## ⚙️ Requirements

| Tool | Minimum Version |
|---|---|
| Flutter | **3.22.0** |
| Dart | **3.4.0** |
| Android SDK | **API 23** (Android 6.0+) |
| Java | **17** (for Gradle) |
| Android Studio | **Hedgehog** or newer (optional) |
| VS Code | Latest (with Flutter extension, optional) |

Check your versions:
```bash
flutter --version
dart --version
```

---

## 🚀 Quick Start

### 1. Clone the repository

```bash
git clone https://github.com/your-username/neurogrid-mobile.git
cd neurogrid-mobile
```

### 2. Set up environment variables

Copy the example config and fill in your API keys:

```bash
cp env.json.example env.json
```

Open `env.json` and replace every `your-*` placeholder with real values:

```json
{
  "SUPABASE_URL": "https://your-project-ref.supabase.co",
  "SUPABASE_ANON_KEY": "your-supabase-anon-key",
  "OPENWEATHER_API_KEY": "get-from-openweathermap.org",
  "GOOGLE_MAPS_API_KEY": "get-from-console.cloud.google.com",
  "TOMTOM_API_KEY": "get-from-developer.tomtom.com",
  "API_BASE_URL": "http://192.168.x.x:8000"
}
```

> **Note:** `env.json` is gitignored and will never be committed.

### 3. Add your Google Maps API key (Android)

Open `android/app/src/main/AndroidManifest.xml` and replace the placeholder:

```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="YOUR_GOOGLE_MAPS_API_KEY_HERE"/>
```

### 4. Install dependencies

```bash
flutter pub get
```

### 5. Connect a device or start an emulator

**Physical device:**
```bash
# Enable USB Debugging on your Android device, then:
flutter devices   # confirm device is listed
```

**Android Emulator:**
- Open Android Studio → Device Manager → Start an emulator  
- Or use the command line: `flutter emulators --launch <emulator_id>`

### 6. Run the app

```bash
flutter run
```

The app reads `env.json` at startup to load API keys via `flutter_config`.

---

## 🔑 API Keys — Where to Get Them

| Key | Source | Free Tier |
|---|---|---|
| `OPENWEATHER_API_KEY` | [openweathermap.org/api](https://openweathermap.org/api) | ✅ Yes |
| `GOOGLE_MAPS_API_KEY` | [console.cloud.google.com](https://console.cloud.google.com) | ✅ $200/mo credit |
| `TOMTOM_API_KEY` | [developer.tomtom.com](https://developer.tomtom.com) | ✅ 2,500 req/day |
| `SUPABASE_URL` + `SUPABASE_ANON_KEY` | [supabase.com](https://supabase.com) | ✅ Generous free tier |
| `GEMINI_API_KEY` | [aistudio.google.com](https://aistudio.google.com) | ✅ Yes |
| `API_BASE_URL` | Your FastAPI backend IP | — |

---

## 🏗️ Build Instructions

### Debug APK (for testing)

```bash
flutter build apk --debug
# Output: build/app/outputs/flutter-apk/app-debug.apk
```

### Release APK (optimised, for sharing)

```bash
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

### Split APKs by ABI (smaller download size)

```bash
flutter build apk --split-per-abi --release
# Outputs arm64-v8a, armeabi-v7a, x86_64 variants
```

### Install directly to connected device

```bash
flutter install
```

---

## 📂 Project Structure

```
lib/
├── core/
│   └── services/           # TomTom, Weather, Maps services
├── presentation/
│   ├── home_screen/        # Home + Quick Insights
│   ├── onboarding_screen/  # 5-step onboarding flow
│   ├── civic_issues_screen/
│   ├── parking_zones_screen/
│   ├── waste_pickup_screen/
│   ├── report_issue_screen/
│   └── profile_screen/
├── providers/              # Riverpod state providers
├── services/               # API client, Supabase, WebSocket
├── theme/                  # AppTheme, colors, typography
└── main.dart
```

---

## 🔧 Troubleshooting

**`env.json not found` error at startup**
```bash
cp env.json.example env.json
# Fill in your API keys
```

**Google Maps shows grey/blank tiles**  
→ Add a valid `GOOGLE_MAPS_API_KEY` to `AndroidManifest.xml` and `env.json`.

**`flutter pub get` fails**  
```bash
flutter clean && flutter pub get
```

**App shows "Backend offline" banner**  
→ Ensure the FastAPI backend is running and `API_BASE_URL` in `env.json` points to the correct local IP (use `ipconfig` / `ifconfig` to find your machine's IP).

**Build fails with Gradle errors**  
```bash
cd android && ./gradlew clean
cd .. && flutter run
```

---

## 🌐 Backend

This mobile app connects to a **FastAPI + WebSocket backend**. See the companion repository:

> [NeuroGrid Backend →](https://github.com/your-username/neurogrid)

The backend serves:
- `/api/v1/city/state` — real-time city dashboard
- `/api/v1/city/summary` — AI-generated city briefing  
- `/api/v1/issues` — civic issue CRUD
- `/api/v1/ws` — WebSocket for live event streaming

---

## 📄 License

MIT © 2025 Madhavan Singh

---

<div align="center">
Built with ❤️ using Flutter, FastAPI & AI
</div>
