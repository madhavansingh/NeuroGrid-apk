import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

/// Single source of truth for all environment configuration.
///
/// Call [AppConfig.load()] once in main() before runApp().
/// After that, all keys are available synchronously via static getters.
class AppConfig {
  AppConfig._();

  static final Map<String, String> _env = {};
  static bool _loaded = false;

  static Future<void> load() async {
    try {
      final raw = await rootBundle.loadString('assets/env.json');
      final parsed = jsonDecode(raw) as Map<String, dynamic>;
      parsed.forEach((k, v) => _env[k] = v?.toString() ?? '');
      _loaded = true;
      debugPrint('[AppConfig] Loaded ${_env.length} keys from assets/env.json');
    } catch (e) {
      debugPrint('[AppConfig] ERROR: Could not load assets/env.json — $e');
    }
  }

  static String _get(String key) {
    if (!_loaded) debugPrint('[AppConfig] WARNING: Accessed $key before load()');
    return _env[key] ?? '';
  }

  // ── Keys ────────────────────────────────────────────────────────────────────
  static String get mapboxToken      => _get('MAPBOX_TOKEN');
  static String get googleClientId   => _get('GOOGLE_CLIENT_ID');   // Android OAuth client
  static String get googleWebClientId => _get('GOOGLE_WEB_CLIENT_ID'); // Web OAuth client → use as serverClientId
  static String get geminiApiKey     => _get('GEMINI_API_KEY');
  static String get openAiApiKey     => _get('OPENAI_API_KEY');
  static String get tomtomApiKey     => _get('TOMTOM_API_KEY');
  static String get openWeatherKey   => _get('OPENWEATHER_API_KEY');
  static String get apiBaseUrl       => _get('API_BASE_URL');
  static String get supabaseUrl      => _get('SUPABASE_URL');
  static String get supabaseAnonKey  => _get('SUPABASE_ANON_KEY');

  // ── Voice keys ───────────────────────────────────────────────────────────────
  static String get retellApiKey      => _get('RETELL_API_KEY');
  static String get retellAgentId     => _get('RETELL_AGENT_ID');
  static String get elevenLabsApiKey  => _get('ELEVENLABS_API_KEY');
  static String get elevenLabsVoiceId => _get('ELEVENLABS_VOICE_ID');
}
