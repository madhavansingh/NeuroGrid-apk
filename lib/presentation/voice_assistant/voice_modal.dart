import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/services/voice/voice_models.dart';
import '../../providers/voice_provider.dart';
import './widgets/voice_waveform_widget.dart';

/// Full-screen voice call overlay.
///
/// Shown as a showGeneralDialog so it overlays any route without
/// requiring its own route or rebuilding the calling screen.
///
/// Call via [VoiceModal.show].
class VoiceModal extends ConsumerStatefulWidget {
  const VoiceModal({super.key});

  static Future<void> show(BuildContext context) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 350),
      pageBuilder: (ctx, anim, _) => const VoiceModal(),
      transitionBuilder: (ctx, anim, _, child) {
        final curved = CurvedAnimation(
          parent: anim,
          curve: Curves.easeOutCubic,
        );
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        );
      },
    );
  }

  @override
  ConsumerState<VoiceModal> createState() => _VoiceModalState();
}

class _VoiceModalState extends ConsumerState<VoiceModal>
    with TickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  // Connecting dots animation
  int _dotCount = 1;
  late AnimationController _dotsCtrl;

  // Track whether the call was ever active — prevents dismissing before the
  // first connect attempt completes.
  bool _hasBeenActive = false;
  // Timestamp when modal was opened — add grace period before auto-dismiss.
  late final DateTime _openedAt;

  @override
  void initState() {
    super.initState();
    _openedAt = DateTime.now();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    _dotsCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..addStatusListener((s) {
        if (s == AnimationStatus.completed) {
          setState(() => _dotCount = _dotCount % 3 + 1);
          _dotsCtrl.reset();
          _dotsCtrl.forward();
        }
      });
    _dotsCtrl.forward();
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _dotsCtrl.dispose();
    super.dispose();
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  String _dots() => '.' * _dotCount;

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Future<void> _handleEnd(WidgetRef ref) async {
    await ref.read(voiceProvider.notifier).endCall();
    if (mounted) Navigator.of(context).pop();
  }

  // ── Auto-dismiss when call reaches idle ──────────────────────────────────
  void _maybeAutoDismiss(VoiceState voice) {
    // Track if call was ever non-idle (connecting / in-call / ending)
    if (voice.callStatus != CallStatus.idle) {
      _hasBeenActive = true;
    }

    // Only auto-dismiss if:
    //  1. We have seen the call become active at least once, AND
    //  2. A minimum 2-second grace period has elapsed (prevents instant dismiss)
    final graceElapsed =
        DateTime.now().difference(_openedAt) > const Duration(seconds: 2);

    if (voice.callStatus == CallStatus.idle &&
        _hasBeenActive &&
        graceElapsed &&
        mounted) {
      Future.microtask(() {
        if (mounted) Navigator.of(context).pop();
      });
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final voice = ref.watch(voiceProvider);
    _maybeAutoDismiss(voice);

    return Material(
      color: Colors.transparent,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: voice.callStatus == CallStatus.ending ? 0.0 : 1.0,
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF0A1628),
                Color(0xFF0D2151),
                Color(0xFF0A1628),
              ],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                _buildHeader(context),
                Expanded(child: _buildBody(voice)),
                _buildFooter(voice),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          // AI avatar
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1A6BF5), Color(0xFF4A8FFF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1A6BF5).withAlpha(100),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.smart_toy_rounded,
              size: 22,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'NeuroGrid Voice AI',
                style: GoogleFonts.dmSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              Text(
                'Bhopal City Assistant',
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: Colors.white.withAlpha(140),
                ),
              ),
            ],
          ),
          const Spacer(),
          // Dismiss button — only when not in-call
          GestureDetector(
            onTap: () => _handleEnd(ref),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(20),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.close_rounded,
                size: 18,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(VoiceState voice) {
    // Show error state if call failed before connecting
    if (voice.callStatus == CallStatus.idle && voice.error != null) {
      return _buildError(voice.error!);
    }
    return switch (voice.callStatus) {
      CallStatus.connecting => _buildConnecting(),
      CallStatus.inCall => _buildInCall(voice),
      CallStatus.ending => _buildEnding(),
      // Idle with no error: show connecting (grace period before dismiss)
      CallStatus.idle => _buildConnecting(),
    };
  }

  Widget _buildError(String error) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: const Color(0xFFDC2626).withAlpha(30),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.error_outline_rounded,
            size: 32,
            color: Color(0xFFDC2626),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Could not connect',
          style: GoogleFonts.dmSans(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            error,
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(
              fontSize: 13,
              color: Colors.white.withAlpha(150),
              height: 1.5,
            ),
          ),
        ),
        const SizedBox(height: 28),
        // Retry button
        GestureDetector(
          onTap: () {
            ref.read(voiceProvider.notifier).clearError();
            ref.read(voiceProvider.notifier).startCall();
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 13),
            decoration: BoxDecoration(
              color: const Color(0xFF1A6BF5),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1A6BF5).withAlpha(80),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Text(
              'Try Again',
              style: GoogleFonts.dmSans(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Text(
            'Close',
            style: GoogleFonts.dmSans(
              fontSize: 13,
              color: Colors.white.withAlpha(120),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConnecting() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Pulsing ring
        AnimatedBuilder(
          animation: _pulseAnim,
          builder: (_, __) => Transform.scale(
            scale: _pulseAnim.value,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF1A6BF5).withAlpha(120),
                  width: 2,
                ),
              ),
              child: Center(
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const RadialGradient(
                      colors: [Color(0xFF1A6BF5), Color(0xFF4A8FFF)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF1A6BF5).withAlpha(120),
                        blurRadius: 24,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.graphic_eq_rounded,
                    size: 32,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 32),
        Text(
          'Connecting to City AI${_dots()}',
          style: GoogleFonts.dmSans(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Setting up secure voice channel',
          style: GoogleFonts.dmSans(
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: Colors.white.withAlpha(120),
          ),
        ),
      ],
    );
  }

  Widget _buildInCall(VoiceState voice) {
    final label = switch (voice.speakStatus) {
      SpeakStatus.speaking => 'Speaking…',
      SpeakStatus.listening => 'Listening…',
      SpeakStatus.idle => 'Connected',
    };

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Waveform
        AnimatedBuilder(
          animation: _pulseAnim,
          builder: (_, child) => Transform.scale(
            scale: voice.speakStatus == SpeakStatus.speaking
                ? (0.95 + _pulseAnim.value * 0.05)
                : 1.0,
            child: child,
          ),
          child: SizedBox(
            height: 120,
            child: VoiceWaveformWidget(
              speakStatus: voice.speakStatus,
              barColor: Colors.white,
            ),
          ),
        ),

        const SizedBox(height: 28),

        // Speak status label
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: Text(
            label,
            key: ValueKey(label),
            style: GoogleFonts.dmSans(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),

        const SizedBox(height: 10),

        // Call timer
        Text(
          _formatDuration(voice.callDuration),
          style: GoogleFonts.dmSans(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.white.withAlpha(140),
            letterSpacing: 1.5,
          ),
        ),

        const SizedBox(height: 32),

        // Hint
        Text(
          'Ask anything about Bhopal traffic,\nparking, or city services',
          textAlign: TextAlign.center,
          style: GoogleFonts.dmSans(
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: Colors.white.withAlpha(100),
            height: 1.6,
          ),
        ),
      ],
    );
  }

  Widget _buildEnding() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(20),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.call_end_rounded,
            size: 32,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Call ended',
          style: GoogleFonts.dmSans(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildFooter(VoiceState voice) {
    if (voice.callStatus != CallStatus.inCall) return const SizedBox.shrink();

    return Column(
      children: [
        // End call button
        GestureDetector(
          onTap: () => _handleEnd(ref),
          child: Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFDC2626),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFDC2626).withAlpha(120),
                  blurRadius: 20,
                  spreadRadius: 2,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.call_end_rounded,
              size: 30,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Tap to end call',
          style: GoogleFonts.dmSans(
            fontSize: 12,
            color: Colors.white.withAlpha(120),
          ),
        ),
      ],
    );
  }
}
