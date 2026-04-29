// State models for the Retell voice call lifecycle.

/// High-level call state machine.
enum CallStatus {
  /// No call active — mic FAB visible only.
  idle,

  /// Backend called, WebRTC connecting — spinner visible.
  connecting,

  /// WebRTC peer connection established — waveform visible.
  inCall,

  /// Call tear-down in progress — fade-out animation.
  ending,
}

/// Fine-grained speaking state inside an active call.
enum SpeakStatus {
  idle,

  /// Agent is not talking — mic is open.
  listening,

  /// Agent is currently talking.
  speaking,
}

/// Immutable snapshot exposed to the UI.
class VoiceState {
  final CallStatus callStatus;
  final SpeakStatus speakStatus;
  final Duration callDuration;
  final String? error;

  const VoiceState({
    this.callStatus = CallStatus.idle,
    this.speakStatus = SpeakStatus.idle,
    this.callDuration = Duration.zero,
    this.error,
  });

  VoiceState copyWith({
    CallStatus? callStatus,
    SpeakStatus? speakStatus,
    Duration? callDuration,
    String? error,
    bool clearError = false,
  }) {
    return VoiceState(
      callStatus: callStatus ?? this.callStatus,
      speakStatus: speakStatus ?? this.speakStatus,
      callDuration: callDuration ?? this.callDuration,
      error: clearError ? null : (error ?? this.error),
    );
  }

  bool get isActive =>
      callStatus == CallStatus.connecting ||
      callStatus == CallStatus.inCall ||
      callStatus == CallStatus.ending;
}
