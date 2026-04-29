/// NeuroGrid — Centralized API configuration.
///
/// All backend URLs and path constants live here.
/// NEVER hardcode URLs anywhere else in the codebase.
class ApiConfig {
  ApiConfig._();

  // ── Production backend (Render) ────────────────────────────────────────────
  static const String productionBaseUrl =
      'https://neurogrid-web-pm4y.onrender.com';

  static const String productionWsUrl =
      'wss://neurogrid-web-pm4y.onrender.com/api/v1/ws';

  // ── REST endpoint paths ────────────────────────────────────────────────────
  static const String issuesPath        = '/api/v1/issues';
  static const String cityStatePath     = '/api/v1/city/state';
  static const String citySummaryPath   = '/api/v1/city/summary';
  static const String trafficPath       = '/api/v1/traffic';
  static const String trafficLivePath   = '/api/v1/traffic/live';
  static const String aiQueriesPath     = '/api/v1/ai/queries';
  static const String voiceCallPath     = '/api/v1/voice/create-web-call';
  static const String wsPath            = '/api/v1/ws';

  // ── Timeouts (generous for Render free-tier cold starts) ──────────────────
  /// First connection — Render can take 30-50 s to wake from sleep.
  static const Duration connectTimeout  = Duration(seconds: 45);
  static const Duration receiveTimeout  = Duration(seconds: 60);
  static const Duration sendTimeout     = Duration(seconds: 30);

  // ── Retry policy ──────────────────────────────────────────────────────────
  static const int    maxRetries        = 3;
  static const Duration retryBaseDelay  = Duration(seconds: 3);

  // ── WebSocket reconnect ───────────────────────────────────────────────────
  static const Duration wsReconnectBase = Duration(seconds: 5);
  static const Duration wsReconnectMax  = Duration(seconds: 60);
}
