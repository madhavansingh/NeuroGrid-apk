import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/server_status_provider.dart';

/// Shows a dismissible banner when the Render backend is waking from sleep.
/// Drop into any screen that fetches from the backend.
///
/// Usage:
/// ```dart
/// Column(children: [
///   const ServerWakeBanner(),
///   Expanded(child: myContent),
/// ]);
/// ```
class ServerWakeBanner extends ConsumerWidget {
  const ServerWakeBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(serverStatusProvider).valueOrNull;
    if (status == null || status == ServerStatus.online) {
      return const SizedBox.shrink();
    }
    return _Banner(status: status, ref: ref);
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.status, required this.ref});
  final ServerStatus status;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final isWaking = status == ServerStatus.waking;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: double.infinity,
      color: isWaking
          ? const Color(0xFFFFF3CD) // amber
          : const Color(0xFFFFE0E0), // red
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          if (isWaking)
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(Color(0xFF92720A)),
              ),
            )
          else
            const Icon(Icons.wifi_off_rounded,
                size: 16, color: Color(0xFF8B1A1A)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              isWaking
                  ? 'Waking up server… first request may take ~30s'
                  : 'Server offline — check your connection',
              style: GoogleFonts.dmSans(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isWaking
                    ? const Color(0xFF92720A)
                    : const Color(0xFF8B1A1A),
              ),
            ),
          ),
          if (!isWaking)
            GestureDetector(
              onTap: () =>
                  ref.read(serverStatusProvider.notifier).retry(),
              child: Text(
                'Retry',
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF8B1A1A),
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Full-screen cold-start placeholder shown while the server is waking.
class ServerWakingPlaceholder extends ConsumerWidget {
  const ServerWakingPlaceholder({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusAsync = ref.watch(serverStatusProvider);
    return statusAsync.when(
      loading: () => const _WakingScreen(),
      error: (_, __) => child,
      data: (status) =>
          status == ServerStatus.waking ? const _WakingScreen() : child,
    );
  }
}

class _WakingScreen extends StatelessWidget {
  const _WakingScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0F1E),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 48,
              height: 48,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor:
                    AlwaysStoppedAnimation(Color(0xFF1A6BF5)),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Connecting to server…',
              style: GoogleFonts.dmSans(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Waking up backend — this takes ~30 seconds\non the first request.',
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(
                color: Colors.white54,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
