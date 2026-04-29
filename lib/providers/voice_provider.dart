import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/services/voice/retell_voice_service.dart';
import '../core/services/voice/voice_models.dart';

/// Global Riverpod provider for the Retell voice call state.
///
/// Screens import [voiceProvider] to read [VoiceState] and
/// [voiceProvider.notifier] to call [startCall] / [endCall].
final voiceProvider =
    StateNotifierProvider<VoiceNotifier, VoiceState>(
  (ref) => VoiceNotifier(),
);

class VoiceNotifier extends StateNotifier<VoiceState> {
  VoiceNotifier() : super(const VoiceState()) {
    // Mirror service stream into Riverpod state
    _sub = _service.stateStream.listen((s) => state = s);
  }

  final RetellVoiceService _service = RetellVoiceService();
  late final StreamSubscription<VoiceState> _sub;

  /// Tap the mic button — starts the Retell call.
  Future<void> startCall() => _service.startCall();

  /// Tap the end button — gracefully tears down the call.
  Future<void> endCall() => _service.endCall();

  /// Request microphone permission — used by VoiceFab before startCall.
  Future<bool> requestMicPermission() => _service.requestMicPermission();

  /// Clear error after user has acknowledged it.
  void clearError() {
    if (state.error != null) {
      state = state.copyWith(clearError: true);
    }
  }

  @override
  void dispose() {
    _sub.cancel();
    _service.dispose();
    super.dispose();
  }
}
