import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/services/voice/voice_models.dart';

/// Animated audio waveform bar visualisation.
///
/// Behaviour mirrors the web Retell UI:
///   speaking  → tall, fast bars (high amplitude)
///   listening → short, slow bars (low amplitude)
///   idle      → subtle breathing pulse
class VoiceWaveformWidget extends StatefulWidget {
  final SpeakStatus speakStatus;
  final Color barColor;

  const VoiceWaveformWidget({
    super.key,
    required this.speakStatus,
    this.barColor = Colors.white,
  });

  @override
  State<VoiceWaveformWidget> createState() => _VoiceWaveformWidgetState();
}

class _VoiceWaveformWidgetState extends State<VoiceWaveformWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  // Per-bar phase offsets for a natural, non-uniform wave
  static const _phases = [0.0, 0.8, 1.6, 2.4, 3.2, 4.0, 4.8];
  static const _barCount = 7;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final t = _ctrl.value * 2 * math.pi;
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: List.generate(_barCount, (i) {
            final raw = math.sin(t + _phases[i]);
            final height = _barHeight(raw, i);
            return AnimatedContainer(
              duration: const Duration(milliseconds: 80),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: 5,
              height: height,
              decoration: BoxDecoration(
                color: widget.barColor.withAlpha(_barAlpha()),
                borderRadius: BorderRadius.circular(3),
              ),
            );
          }),
        );
      },
    );
  }

  double _barHeight(double sineVal, int index) {
    // Map sine (-1..1) → (0..1)
    final normalised = (sineVal + 1) / 2;

    switch (widget.speakStatus) {
      case SpeakStatus.speaking:
        // Tall + fast — amplitudes vary per bar for organic feel
        final amp = [48.0, 64.0, 80.0, 96.0, 80.0, 64.0, 48.0][index];
        return 12 + normalised * amp;

      case SpeakStatus.listening:
        // Short + slow
        return 8 + normalised * 20;

      case SpeakStatus.idle:
        // Subtle breathing — very low amplitude
        return 6 + normalised * 10;
    }
  }

  int _barAlpha() {
    return switch (widget.speakStatus) {
      SpeakStatus.speaking => 255,
      SpeakStatus.listening => 200,
      SpeakStatus.idle => 140,
    };
  }
}
