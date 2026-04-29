import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';

/// Exposes the current [UserSession] (null = signed out / not yet loaded).
final userSessionProvider =
    StateNotifierProvider<UserSessionNotifier, UserSession?>(
  (ref) => UserSessionNotifier(),
);

class UserSessionNotifier extends StateNotifier<UserSession?> {
  UserSessionNotifier() : super(null);

  /// Attempt silent restore (called from SplashScreen).
  Future<void> restore() async {
    state = await AuthService.instance.restoreSession();
  }

  /// Full Google OAuth sign-in. Returns true on success.
  Future<bool> signIn() async {
    final session = await AuthService.instance.signIn();
    if (session != null) state = session;
    return session != null;
  }

  Future<void> signOut() async {
    await AuthService.instance.signOut();
    state = null;
  }

  void set(UserSession s) => state = s;
}
