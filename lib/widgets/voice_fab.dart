import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/services/voice/voice_models.dart';
import '../providers/voice_provider.dart';
import '../presentation/voice_assistant/voice_modal.dart';

/// Floating mic button placed above the bottom nav bar on Home and Map screens.
///
/// States:
///   idle        → gradient mic button, labeled "Voice AI"
///   connecting  → pulsing ring + label "Connecting…"
///   in-call     → glowing red "End" button
///   ending      → faded transition
///
/// On tap when idle: requests call → opens [VoiceModal].
/// On tap when in-call: ends call immediately.
class VoiceFab extends ConsumerWidget {
  const VoiceFab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final voice = ref.watch(voiceProvider);

    // While modal is open and active, the FAB is not shown.
    // (Modal handles in-call and end-call UI)
    // FAB is always shown as a quick shortcut to launch/end the call.
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildButton(context, ref, voice),
          const SizedBox(height: 4),
          _buildLabel(voice),
        ],
      ),
    );
  }

  Widget _buildButton(BuildContext context, WidgetRef ref, VoiceState voice) {
    return switch (voice.callStatus) {
      CallStatus.idle => _IdleButton(
          onTap: () => _startCall(context, ref),
        ),
      CallStatus.connecting => const _ConnectingButton(),
      CallStatus.inCall => _InCallButton(
          onTap: () => ref.read(voiceProvider.notifier).endCall(),
        ),
      CallStatus.ending => const _EndingButton(),
    };
  }

  Widget _buildLabel(VoiceState voice) {
    final label = switch (voice.callStatus) {
      CallStatus.idle => 'Voice AI',
      CallStatus.connecting => 'Connecting…',
      CallStatus.inCall => 'Live',
      CallStatus.ending => 'Ending…',
    };
    return Text(
      label,
      style: GoogleFonts.dmSans(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: voice.callStatus == CallStatus.inCall
            ? const Color(0xFFDC2626)
            : const Color(0xFF1A6BF5),
      ),
    );
  }

  Future<void> _startCall(BuildContext context, WidgetRef ref) async {
    // Check permission before opening modal
    final granted =
        await ref.read(voiceProvider.notifier).requestMicPermission();
    if (!granted) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Microphone access is required for the voice assistant.',
            style: GoogleFonts.dmSans(fontSize: 13),
          ),
          action: SnackBarAction(
            label: 'Settings',
            onPressed: () {
              // permission_handler — opens app settings
            },
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    // Start call (non-blocking) then show modal
    unawaited(ref.read(voiceProvider.notifier).startCall());
    if (!context.mounted) return;
    await VoiceModal.show(context);
  }
}

// ── Sub-widgets ──────────────────────────────────────────────────────────────

class _IdleButton extends StatelessWidget {
  final VoidCallback onTap;
  const _IdleButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A6BF5), Color(0xFF4A8FFF)],
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1A6BF5).withAlpha(100),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Icon(
          Icons.mic_rounded,
          size: 26,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _ConnectingButton extends StatefulWidget {
  const _ConnectingButton();

  @override
  State<_ConnectingButton> createState() => _ConnectingButtonState();
}

class _ConnectingButtonState extends State<_ConnectingButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _scale = Tween<double>(begin: 0.90, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: const Color(0xFF1A6BF5).withAlpha(180),
            width: 2.5,
          ),
          color: const Color(0xFFEBF1FF),
        ),
        child: const Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: Color(0xFF1A6BF5),
            ),
          ),
        ),
      ),
    );
  }
}

class _InCallButton extends StatelessWidget {
  final VoidCallback onTap;
  const _InCallButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: const Color(0xFFDC2626),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFDC2626).withAlpha(100),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Icon(
          Icons.call_end_rounded,
          size: 26,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _EndingButton extends StatelessWidget {
  const _EndingButton();

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.4,
      child: Container(
        width: 56,
        height: 56,
        decoration: const BoxDecoration(
          color: Color(0xFF94A3B8),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.mic_off_rounded,
          size: 26,
          color: Colors.white,
        ),
      ),
    );
  }
}

/// Fire-and-forget pattern — explicitly ignore the future.
void unawaited(Future<void> future) {
  // Intentionally not awaited — call starts in background while modal opens.
  // ignore: unawaited_futures
  future;
}
