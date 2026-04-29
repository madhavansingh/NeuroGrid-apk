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
| 🤖 **AI Assistant** | Real Gemini / GPT-4o powered city chatbot (multi-turn) |
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

```bash
cp env.json.example env.json
```

Open `env.json` and fill in the values. The full reference for every key is in the **[🔑 API Keys section](#-api-keys--where-to-get-them)** below.

```json
{
  "SUPABASE_URL":       "https://your-project-ref.supabase.co",
  "SUPABASE_ANON_KEY":  "eyJ...",
  "GEMINI_API_KEY":     "AIza...",
  "OPENAI_API_KEY":     "sk-...",
  "OPENWEATHER_API_KEY":"abc123...",
  "GOOGLE_MAPS_API_KEY":"AIza...",
  "TOMTOM_API_KEY":     "abc123...",
  "API_BASE_URL":       "http://192.168.1.x:8000"
}
```

> **`env.json` is gitignored** — it will never be committed to version control.

### 3. Add your Google Maps key to AndroidManifest

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

### 5. Run the app

```bash
flutter run
```

> The app reads `env.json` at startup via `flutter_config`. No keys = no services.

---

## 🔑 API Keys — Where to Get Them

### 🗄️ Supabase (Auth + Database)

| Key | How to get it |
|---|---|
| `SUPABASE_URL` | Go to [supabase.com](https://supabase.com) → your project → **Settings → API** → copy **Project URL** |
| `SUPABASE_ANON_KEY` | Same page → copy **anon / public** key |

Free tier: ✅ Unlimited auth, 500 MB DB, 2 GB storage.

---

### 🤖 AI Chatbot Keys (pick at least ONE)

The NeuroGrid AI assistant (`lib/presentation/ai_assistant_screen`) uses real AI — **no mock data**.
It automatically routes your request using this priority:

```
AWS_LAMBDA_CHAT_COMPLETION_URL set?  →  Use Lambda proxy (multi-model)
  else GEMINI_API_KEY set?           →  Call Gemini 2.0 Flash directly ✅ easiest
    else OPENAI_API_KEY set?         →  Call GPT-4o Mini directly
      else                           →  Error shown in chat UI
```

**Recommended for most developers: just set `GEMINI_API_KEY` — it has a free tier.**

#### Gemini (Google AI Studio) — **Recommended**

| Key | `GEMINI_API_KEY` |
|---|---|
| Get it at | [aistudio.google.com/app/apikey](https://aistudio.google.com/app/apikey) |
| Format | `AIzaSy...` (starts with `AIza`) |
| Free tier | ✅ **Free** — 1,500 req/day, 1M tokens/min on Gemini Flash |
| Model used | `gemini-2.0-flash` (fast, cheap, highly accurate) |

Steps:
1. Go to [Google AI Studio](https://aistudio.google.com/app/apikey)
2. Sign in with any Google account
3. Click **Create API Key**
4. Copy and paste into `env.json` as `GEMINI_API_KEY`

#### OpenAI — GPT-4o Mini

| Key | `OPENAI_API_KEY` |
|---|---|
| Get it at | [platform.openai.com/api-keys](https://platform.openai.com/api-keys) |
| Format | `sk-...` (starts with `sk-`) |
| Free tier | ❌ Requires credit card ($5 minimum top-up) |
| Model used | `gpt-4o-mini` (fast, smart, cost-effective) |

Steps:
1. Go to [OpenAI Platform](https://platform.openai.com/api-keys)
2. Create account → **API Keys → + Create new secret key**
3. Add billing at [platform.openai.com/account/billing](https://platform.openai.com/account/billing)
4. Copy and paste into `env.json` as `OPENAI_API_KEY`

#### Anthropic (Claude) — Optional

| Key | `ANTHROPIC_API_KEY` |
|---|---|
| Get it at | [console.anthropic.com/settings/keys](https://console.anthropic.com/settings/keys) |
| Format | `sk-ant-...` |
| Free tier | ❌ Requires credit card |

#### AWS Lambda Proxy — Advanced / Production

| Key | `AWS_LAMBDA_CHAT_COMPLETION_URL` |
|---|---|
| What it is | A Lambda Function URL that proxies requests to any AI provider (OpenAI, Gemini, Anthropic, Perplexity) |
| Get it | Deploy the Lambda in `/backend/lambda` → copy the **Function URL** |
| Format | `https://abc123.lambda-url.us-east-1.on.aws/` |
| Free tier | ✅ AWS free tier: 1M requests/month |

> Leave this **empty** if you don't have a Lambda — the app falls back to direct Gemini/OpenAI automatically.

---

### 🌤️ Weather

| Key | `OPENWEATHER_API_KEY` |
|---|---|
| Get it at | [home.openweathermap.org/api_keys](https://home.openweathermap.org/api_keys) |
| Format | 32-character hex string |
| Free tier | ✅ **Free** — 1,000 calls/day, current weather + 5-day forecast |

Steps:
1. Sign up at [openweathermap.org](https://openweathermap.org)
2. Go to **My Profile → API keys**
3. Copy the default key (or create a new one)

---

### 🗺️ Maps

| Key | `GOOGLE_MAPS_API_KEY` |
|---|---|
| Get it at | [console.cloud.google.com](https://console.cloud.google.com) → APIs & Services → Credentials |
| Format | `AIzaSy...` |
| Free tier | ✅ $200/month credit (~28,000 map loads free) |

Steps:
1. Go to [Google Cloud Console](https://console.cloud.google.com)
2. Create a project → **APIs & Services → Library**
3. Enable: **Maps SDK for Android**, **Maps SDK for iOS**, **Geocoding API**
4. Go to **Credentials → + Create Credentials → API Key**
5. Restrict the key to your app's package name for security

| Key | `TOMTOM_API_KEY` |
|---|---|
| Get it at | [developer.tomtom.com/user/me/apps](https://developer.tomtom.com/user/me/apps) |
| Format | 32-character hex string |
| Free tier | ✅ 2,500 req/day |

Steps:
1. Sign up at [developer.tomtom.com](https://developer.tomtom.com)
2. Go to **Dashboard → Apps → + New App**
3. Enable **Traffic** product → copy the API Key

---

### 🔐 Google OAuth (Login)

| Key | `GOOGLE_WEB_CLIENT_ID` |
|---|---|
| Get it at | [console.cloud.google.com](https://console.cloud.google.com) → APIs & Services → Credentials → OAuth 2.0 Client IDs |
| Format | `123456789-abc...apps.googleusercontent.com` |

Steps:
1. In Cloud Console → **Credentials → + Create Credentials → OAuth client ID**
2. Choose **Web application**
3. Copy the **Client ID** (not secret)

---

### 🌐 FastAPI Backend

| Key | `API_BASE_URL` |
|---|---|
| What it is | The local IP address of the machine running the Python FastAPI backend |
| Format | `http://192.168.x.x:8000` |

Find your machine's IP:
```bash
# macOS / Linux:
ifconfig | grep "inet " | grep -v 127.0.0.1

# Windows:
ipconfig | findstr "IPv4"
```

> Your phone and computer must be on the **same Wi-Fi network**.

---

## 🏗️ Build Instructions

### Debug APK
```bash
flutter build apk --debug
# → build/app/outputs/flutter-apk/app-debug.apk
```

### Release APK
```bash
flutter build apk --release
# → build/app/outputs/flutter-apk/app-release.apk
```

### Split APKs (smaller download sizes)
```bash
flutter build apk --split-per-abi --release
```

---

## 📂 Project Structure

```
lib/
├── core/
│   └── services/
│       ├── aiIntegrations/
│       │   ├── chat_completion_service.dart  ← routes to Lambda or direct AI
│       │   └── direct_ai_service.dart        ← Gemini + OpenAI direct clients
│       ├── weather_service.dart
│       └── api_service.dart
├── presentation/
│   ├── ai_assistant_screen/   ← live AI chatbot (real multi-turn)
│   ├── home_screen/
│   ├── traffic_screen/
│   ├── 3d_map_screen/
│   ├── civic_issues_screen/
│   ├── parking_zones_screen/
│   └── profile_screen/
├── providers/
│   └── chat_notifier.dart    ← Riverpod state for chat
├── theme/
└── main.dart
```

---

## 🔧 Troubleshooting

**`env.json not found` at startup**
```bash
cp env.json.example env.json
# Fill in your API keys
```

**AI chatbot returns an error message**
- Make sure at least one of `GEMINI_API_KEY` or `OPENAI_API_KEY` is set in `env.json`
- Rebuild the app after editing env.json: `flutter run` (hot-reload doesn't pick up env changes)

**AI responses not accurate / off-topic**
- Gemini Flash and GPT-4o Mini are both excellent. If accuracy is critical, switch to `gemini-2.0-pro` or `gpt-4o` by editing the `_config` in `ai_assistant_screen.dart`

**Google Maps shows grey tiles**
→ Add a valid `GOOGLE_MAPS_API_KEY` to both `env.json` and `AndroidManifest.xml`

**`flutter pub get` fails**
```bash
flutter clean && flutter pub get
```

**App shows "Backend offline" banner**
→ Make sure FastAPI is running and `API_BASE_URL` uses your machine's LAN IP (not `localhost`)

**Gradle build fails**
```bash
cd android && ./gradlew clean && cd .. && flutter run
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

MIT © 2026 NeuroGrid Team
