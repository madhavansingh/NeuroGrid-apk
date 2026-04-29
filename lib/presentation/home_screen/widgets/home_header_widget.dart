import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../providers/location_provider.dart';
import '../../../providers/city_state_provider.dart';
import '../../../providers/user_session_provider.dart';
import '../../../routes/app_routes.dart';
import '../../../theme/app_theme.dart';

class HomeHeaderWidget extends ConsumerStatefulWidget {
  const HomeHeaderWidget({super.key});
  @override
  ConsumerState<HomeHeaderWidget> createState() => _HomeHeaderWidgetState();
}

class _HomeHeaderWidgetState extends ConsumerState<HomeHeaderWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1400))
      ..repeat(reverse: true);

    // Kick off real location fetch on first build
    Future.microtask(() =>
        ref.read(locationProvider.notifier).fetchLocation());
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good Morning';
    if (h < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    final session   = ref.watch(userSessionProvider);
    final location  = ref.watch(locationProvider);
    final cityAsync = ref.watch(cityStateProvider);

    final firstName = session?.firstName ?? 'Citizen';
    final initials  = session?.initials ?? 'U';
    final photoUrl  = session?.photoUrl;
    final areaLabel = location.loading ? 'Locating…' : location.areaLabel;

    final String trafficStatus = cityAsync.whenOrNull(
          data: (s) {
            final t = s?.traffic;
            return t != null ? t.status : 'smooth';
          },
        ) ??
        'smooth';
    final int alertCount = cityAsync.whenOrNull(
          data: (s) {
            final a = s?.alerts;
            return a != null ? a.length : 0;
          },
        ) ??
        0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // ── Top row ─────────────────────────────────────────────────────────
        Row(children: [
          // Location pill — tappable
          GestureDetector(
            onTap: () => ref.read(locationProvider.notifier).fetchLocation(),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.primaryLight,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                location.loading
                    ? const SizedBox(
                        width: 11, height: 11,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.5, color: AppTheme.primary))
                    : const Icon(Icons.location_on_rounded,
                        size: 13, color: AppTheme.primary),
                const SizedBox(width: 4),
                Text(areaLabel,
                    style: GoogleFonts.dmSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primary)),
                if (!location.loading) ...[
                  const SizedBox(width: 3),
                  const Icon(Icons.keyboard_arrow_down_rounded,
                      size: 14, color: AppTheme.primary),
                ],
              ]),
            ),
          ),

          const Spacer(),

          // Animated LIVE pill
          AnimatedBuilder(
            animation: _pulseCtrl,
            builder: (_, __) {
              final scale = 1.0 + 0.25 * math.sin(_pulseCtrl.value * math.pi);
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: const Color(0xFF10B981).withAlpha(60), width: 1),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Transform.scale(
                    scale: scale,
                    child: Container(
                      width: 7, height: 7,
                      decoration: const BoxDecoration(
                        color: Color(0xFF10B981), shape: BoxShape.circle),
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text('Live',
                      style: GoogleFonts.dmSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF059669))),
                ]),
              );
            },
          ),

          const SizedBox(width: 10),

          // Notification bell — tappable (opens alerts drawer)
          _NotificationBell(alertCount: alertCount),

          const SizedBox(width: 10),

          // Avatar — tappable → profile
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, AppRoutes.profileScreen),
            child: Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1A6BF5), Color(0xFF6B9EFF)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: photoUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.network(photoUrl, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              _InitialsAvatar(initials: initials)))
                  : _InitialsAvatar(initials: initials),
            ),
          ),
        ]),

        const SizedBox(height: 16),

        // Greeting
        Text(_greeting,
            style: GoogleFonts.dmSans(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppTheme.textMuted)),
        const SizedBox(height: 2),
        Text('$firstName 👋',
            style: GoogleFonts.dmSans(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
                letterSpacing: -0.5)),

        const SizedBox(height: 14),

        // ── City stats strip ──────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withAlpha(8),
                  blurRadius: 12,
                  offset: const Offset(0, 3)),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatChip(
                icon: Icons.directions_car_rounded,
                label: 'Traffic',
                value: trafficStatus[0].toUpperCase() +
                    trafficStatus.substring(1),
                color: trafficStatus.toLowerCase() == 'heavy'
                    ? const Color(0xFFDC2626)
                    : trafficStatus.toLowerCase() == 'moderate'
                        ? const Color(0xFFF59E0B)
                        : const Color(0xFF16A34A),
              ),
              _VertDivider(),
              _StatChip(
                icon: Icons.warning_amber_rounded,
                label: 'Alerts',
                value: alertCount == 0 ? 'None' : '$alertCount active',
                color: alertCount > 0
                    ? const Color(0xFFF59E0B)
                    : const Color(0xFF10B981),
              ),
              _VertDivider(),
              _StatChip(
                icon: Icons.access_time_rounded,
                label: 'Updated',
                value: 'Just now',
                color: const Color(0xFF6366F1),
              ),
            ],
          ),
        ),
      ]),
    );
  }
}

// ── City stats chip ───────────────────────────────────────────────────────────

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final Color color;
  const _StatChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });
  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(height: 3),
          Text(value,
              style: GoogleFonts.dmSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A))),
          Text(label,
              style: GoogleFonts.dmSans(
                  fontSize: 10,
                  color: const Color(0xFF94A3B8))),
        ],
      );
}

class _VertDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        width: 1,
        height: 36,
        color: const Color(0xFFE2E8F0),
      );
}


// ── Small sub-widgets ────────────────────────────────────────────────────────

class _InitialsAvatar extends StatelessWidget {
  final String initials;
  const _InitialsAvatar({required this.initials});
  @override
  Widget build(BuildContext context) => Center(
    child: Text(initials,
        style: GoogleFonts.dmSans(
            fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
  );
}

class _NotificationBell extends StatefulWidget {
  final int alertCount;
  const _NotificationBell({this.alertCount = 0});
  @override
  State<_NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends State<_NotificationBell> {
  static const _alerts = [
    _AlertItem('🚦 Heavy traffic on Hamidia Road', '2 min ago', Color(0xFFEF4444)),
    _AlertItem('🗑️  Waste pickup tomorrow 8 AM', '15 min ago', Color(0xFF16A34A)),
    _AlertItem('⚡ Power outage: Arera Colony', '1 hr ago', Color(0xFFD97706)),
  ];

  void _show() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 36, height: 4, decoration: BoxDecoration(
              color: const Color(0xFFCBD5E1), borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          Row(children: [
            Text('City Alerts', style: GoogleFonts.dmSans(
                fontSize: 18, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A))),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(20)),
              child: Text(
              '${widget.alertCount > 0 ? widget.alertCount : _alerts.length} new',
              style: GoogleFonts.dmSans(
                  fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.primary)),

            ),
          ]),
          const SizedBox(height: 12),
          ..._alerts.map((a) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(children: [
              Container(width: 8, height: 8,
                  decoration: BoxDecoration(color: a.color, shape: BoxShape.circle)),
              const SizedBox(width: 12),
              Expanded(child: Text(a.title, style: GoogleFonts.dmSans(
                  fontSize: 13, fontWeight: FontWeight.w500, color: const Color(0xFF0F172A)))),
              Text(a.time, style: GoogleFonts.dmSans(
                  fontSize: 11, color: const Color(0xFF94A3B8))),
            ]),
          )),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: _show,
    child: Stack(children: [
      Container(
        width: 42, height: 42,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(
              color: Colors.black.withAlpha(12), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: const Icon(Icons.notifications_outlined, size: 20, color: AppTheme.textPrimary),
      ),
      Positioned(
        top: 9, right: 9,
        child: Container(
          width: 8, height: 8,
          decoration: BoxDecoration(
            color: AppTheme.error, shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 1.5),
          ),
        ),
      ),
    ]),
  );
}

class _AlertItem {
  final String title, time;
  final Color color;
  const _AlertItem(this.title, this.time, this.color);
}
