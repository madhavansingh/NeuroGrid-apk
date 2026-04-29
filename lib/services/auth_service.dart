import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/config/app_config.dart';

// ─────────────────────────────────────────────────────────────────────────────
// UserSession
// ─────────────────────────────────────────────────────────────────────────────

class UserSession {
  final String displayName;
  final String email;
  final String? photoUrl;
  final String userId;

  const UserSession({
    required this.displayName,
    required this.email,
    this.photoUrl,
    required this.userId,
  });

  bool get isGuest => userId == 'guest-local';

  String get firstName => displayName.split(' ').first;
  String get initials {
    final parts = displayName.trim().split(' ');
    if (parts.length >= 2) return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    return displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U';
  }

  Map<String, dynamic> toJson() => {
    'displayName': displayName,
    'email': email,
    'photoUrl': photoUrl,
    'userId': userId,
  };

  factory UserSession.fromJson(Map<String, dynamic> j) => UserSession(
    displayName: j['displayName'] as String? ?? 'User',
    email: j['email'] as String? ?? '',
    photoUrl: j['photoUrl'] as String?,
    userId: j['userId'] as String? ?? '',
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// AuthService  (no Firebase — pure google_sign_in)
// ─────────────────────────────────────────────────────────────────────────────

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  // Resolved at startup from assets/env.json
  static String _webClientId = '';

  // Lazily created so the correct clientId is used after init() completes.
  GoogleSignIn? _gsi;

  GoogleSignIn get _google {
    if (_gsi == null) {
      _gsi = GoogleSignIn(
        // ── Android: must use serverClientId (Web Client ID) ──────────────
        // clientId is iOS-only and is silently IGNORED on Android.
        // Without serverClientId the Android plugin has no OAuth target and
        // returns null from every signIn() call.
        serverClientId: _webClientId.isNotEmpty ? _webClientId : null,
        scopes: ['email', 'profile'],
      );
    }
    return _gsi!;
  }

  // ── Startup init ──────────────────────────────────────────────────────────

  /// Synchronous init using AppConfig (already loaded in main).
  static void initFromConfig() {
    // serverClientId MUST be the Web type OAuth client, not the Android client.
    _webClientId = AppConfig.googleWebClientId.isNotEmpty
        ? AppConfig.googleWebClientId
        : AppConfig.googleClientId; // fallback if only one key exists
    if (_webClientId.isEmpty) {
      debugPrint('[AuthService] WARNING: No Google client ID found in env.json');
    } else {
      debugPrint('[AuthService] serverClientId ready (${_webClientId.substring(0, 20)}…)');
    }
  }

  /// Legacy async init — kept for compatibility. Prefer initFromConfig().
  static Future<void> init() async {
    initFromConfig();
  }

  // ── Session persistence ───────────────────────────────────────────────────

  static const _kSession = 'user_session';

  Future<UserSession?> restoreSession() async {
    try {
      final p = await SharedPreferences.getInstance();
      final raw = p.getString(_kSession);
      if (raw == null) return null;
      return UserSession.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> _saveSession(UserSession s) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kSession, jsonEncode(s.toJson()));
  }

  Future<void> _clearSession() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_kSession);
  }

  // ── Public API ────────────────────────────────────────────────────────────

  /// Guest mode — always succeeds, no network needed.
  UserSession signInAsGuest() {
    const session = UserSession(
      displayName: 'City Explorer',
      email: 'guest@neurogrid.app',
      photoUrl: null,
      userId: 'guest-local',
    );
    _saveSession(session);
    return session;
  }

  /// Full Google OAuth sign-in.
  /// Returns a [UserSession] on success, or throws a descriptive [Exception].
  Future<UserSession> signIn() async {
    if (_webClientId.isEmpty) {
      throw Exception(
        'GOOGLE_CLIENT_ID is empty. '
        'Check assets/env.json and ensure AuthService.init() was called in main().',
      );
    }

    final account = await _google.signIn();

    if (account == null) {
      // User explicitly dismissed the picker — not an error.
      throw Exception('sign_in_cancelled');
    }

    final session = UserSession(
      displayName: account.displayName ?? 'NeuroGrid User',
      email: account.email,
      photoUrl: account.photoUrl,
      userId: account.id,
    );
    await _saveSession(session);
    debugPrint('[AuthService] Signed in as ${session.email}');
    return session;
  }

  Future<void> signOut() async {
    await _google.signOut();
    await _clearSession();
    _gsi = null; // force re-init on next use
  }

  /// Silent restore — tries Google's cached token, falls back to SharedPreferences.
  Future<UserSession?> signInSilently() async {
    try {
      final account = await _google.signInSilently();
      if (account == null) return restoreSession();
      final session = UserSession(
        displayName: account.displayName ?? 'NeuroGrid User',
        email: account.email,
        photoUrl: account.photoUrl,
        userId: account.id,
      );
      await _saveSession(session);
      return session;
    } catch (_) {
      return restoreSession();
    }
  }
}
