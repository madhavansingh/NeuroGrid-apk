import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';
import '../../../core/services/weather_service.dart';
import '../../../providers/city_state_provider.dart';
import '../../../providers/weather_provider.dart';

/// Quick Insights row on the home screen.
/// - Traffic card: live from [cityStateProvider] → /api/v1/city/state
/// - Weather card: unchanged, still uses [WeatherService]
/// - Alerts card: badge count from city state alert list + weather alert
class QuickInsightsWidget extends ConsumerStatefulWidget {
  const QuickInsightsWidget({super.key});

  @override
  ConsumerState<QuickInsightsWidget> createState() =>
      _QuickInsightsWidgetState();
}

class _QuickInsightsWidgetState extends ConsumerState<QuickInsightsWidget> {

  // ── Traffic helpers ────────────────────────────────────────────────────────

  String _trafficValue(String status) {
    switch (status.toLowerCase()) {
      case 'heavy':
        return 'Heavy';
      case 'moderate':
        return 'Moderate';
      default:
        return 'Smooth';
    }
  }

  Color _trafficIconBg(String status) {
    switch (status.toLowerCase()) {
      case 'heavy':
        return AppTheme.trafficHeavyLight;
      case 'moderate':
        return AppTheme.warningLight;
      default:
        return const Color(0xFFECFDF5);
    }
  }

  Color _trafficIconColor(String status) {
    switch (status.toLowerCase()) {
      case 'heavy':
        return AppTheme.trafficHeavy;
      case 'moderate':
        return AppTheme.warning;
      default:
        return const Color(0xFF10B981);
    }
  }

  // ── Weather helpers (unchanged) ────────────────────────────────────────────

  IconData _weatherIcon(String condition) {
    switch (condition.toLowerCase()) {
      case 'thunderstorm':
        return Icons.thunderstorm_rounded;
      case 'drizzle':
        return Icons.grain_rounded;
      case 'rain':
        return Icons.umbrella_rounded;
      case 'snow':
        return Icons.ac_unit_rounded;
      case 'clear':
        return Icons.wb_sunny_rounded;
      case 'clouds':
        return Icons.cloud_queue_rounded;
      case 'mist':
      case 'fog':
      case 'haze':
        return Icons.help_outline;
      default:
        return Icons.cloud_queue_rounded;
    }
  }

  Color _weatherIconColor(String condition) {
    switch (condition.toLowerCase()) {
      case 'thunderstorm':
        return const Color(0xFF7C3AED);
      case 'rain':
      case 'drizzle':
        return const Color(0xFF3B82F6);
      case 'snow':
        return const Color(0xFF60A5FA);
      case 'clear':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF3B82F6);
    }
  }

  Color _weatherValueColor(String condition) {
    switch (condition.toLowerCase()) {
      case 'thunderstorm':
        return const Color(0xFF6D28D9);
      case 'rain':
      case 'drizzle':
        return const Color(0xFF2563EB);
      case 'snow':
        return const Color(0xFF3B82F6);
      case 'clear':
        return const Color(0xFFD97706);
      default:
        return const Color(0xFF2563EB);
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cityAsync = ref.watch(cityStateProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Text(
            'Quick Insights',
            style: GoogleFonts.dmSans(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFFECFDF5),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: const Color(0xFF10B981).withAlpha(60), width: 1),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Container(
                width: 6, height: 6,
                decoration: const BoxDecoration(
                    color: Color(0xFF10B981), shape: BoxShape.circle),
              ),
              const SizedBox(width: 5),
              Text('Live',
                  style: GoogleFonts.dmSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF059669))),
            ]),
          ),
        ]),
        const SizedBox(height: 14),
        Row(
          children: [
            // ── Traffic card — live from backend ──────────────────────────
            Expanded(
              child: cityAsync.when(
                loading: () => _InsightCardSkeleton(),
                error: (_, __) => _InsightCard(
                  icon: Icons.directions_car_rounded,
                  label: 'Traffic',
                  value: '—',
                  subtitle: 'Unavailable',
                  iconBg: AppTheme.trafficHeavyLight,
                  iconColor: AppTheme.trafficHeavy,
                  valueColor: AppTheme.trafficHeavy,
                ),
                data: (cityState) {
                  final traffic = cityState?.traffic;
                  final status = traffic?.status ?? 'smooth';
                  return _InsightCard(
                    icon: Icons.directions_car_rounded,
                    label: 'Traffic',
                    value: _trafficValue(status),
                    subtitle: traffic?.hotspot.isNotEmpty == true
                        ? traffic!.hotspot
                        : 'City-wide',
                    iconBg: _trafficIconBg(status),
                    iconColor: _trafficIconColor(status),
                    valueColor: _trafficIconColor(status),
                  );
                },
              ),
            ),
            const SizedBox(width: 10),

            // ── Weather card — live from weatherProvider ───────────────────
            Expanded(
              child: ref.watch(weatherProvider).when(
                loading: () => _InsightCardSkeleton(),
                error: (_, __) => _InsightCard(
                  icon: Icons.wb_sunny_rounded,
                  label: 'Weather',
                  value: 'N/A',
                  subtitle: '—',
                  iconBg: const Color(0xFFEFF6FF),
                  iconColor: const Color(0xFF0369A1),
                  valueColor: const Color(0xFF0369A1),
                ),
                data: (w) => _InsightCard(
                  icon: _weatherIcon(w.condition),
                  label: 'Weather',
                  value: w.conditionLabel,
                  subtitle: w.insightSubtitle,
                  iconBg: const Color(0xFFEFF6FF),
                  iconColor: _weatherIconColor(w.condition),
                  valueColor: _weatherValueColor(w.condition),
                ),
              ),
            ),
            const SizedBox(width: 10),

            // ── Alerts card — combines city + weather alerts ───────────────
            Expanded(
              child: cityAsync.when(
                loading: () => _InsightCardSkeleton(),
                error: (_, __) => _buildAlertsCard(
                  count: 0,
                  weatherAlert: ref.watch(weatherProvider).valueOrNull?.hasAlert ?? false,
                ),
                data: (cityState) => _buildAlertsCard(
                  count: cityState?.alerts.length ?? 0,
                  weatherAlert: ref.watch(weatherProvider).valueOrNull?.hasAlert ?? false,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAlertsCard({required int count, required bool weatherAlert}) {
    final totalAlerts = count + (weatherAlert ? 1 : 0);
    final hasAlerts = totalAlerts > 0;
    return _InsightCard(
      icon: Icons.warning_amber_rounded,
      label: 'Alerts',
      value: hasAlerts ? '$totalAlerts' : '0',
      subtitle: hasAlerts
          ? weatherAlert
              ? 'Weather + City'
              : 'City alerts'
          : 'All clear',
      iconBg: hasAlerts ? AppTheme.warningLight : const Color(0xFFECFDF5),
      iconColor: hasAlerts ? AppTheme.warning : const Color(0xFF10B981),
      valueColor: hasAlerts ? AppTheme.warning : const Color(0xFF059669),
    );
  }
}

// ── Skeleton ───────────────────────────────────────────────────────────────────

class _InsightCardSkeleton extends StatefulWidget {
  @override
  State<_InsightCardSkeleton> createState() => _InsightCardSkeletonState();
}

class _InsightCardSkeletonState extends State<_InsightCardSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this, duration: const Duration(seconds: 1))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) {
        final opacity = 0.4 + 0.3 * _c.value;
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [BoxShadow(
                color: Colors.black.withAlpha(10),
                blurRadius: 12, offset: const Offset(0, 4))],
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 46, height: 46,
              decoration: BoxDecoration(
                color: Colors.grey.withAlpha((opacity * 80).toInt()),
                borderRadius: BorderRadius.circular(14)),
            ),
            const SizedBox(height: 12),
            Container(
              height: 18, width: 52,
              decoration: BoxDecoration(
                color: Colors.grey.withAlpha((opacity * 80).toInt()),
                borderRadius: BorderRadius.circular(6)),
            ),
            const SizedBox(height: 5),
            Container(
              height: 11, width: 44,
              decoration: BoxDecoration(
                color: Colors.grey.withAlpha((opacity * 50).toInt()),
                borderRadius: BorderRadius.circular(4)),
            ),
          ]),
        );
      },
    );
  }
}

// ── Insight card ───────────────────────────────────────────────────────────────

class _InsightCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String subtitle;
  final Color iconBg;
  final Color iconColor;
  final Color valueColor;

  const _InsightCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.subtitle,
    required this.iconBg,
    required this.iconColor,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: iconColor.withAlpha(25),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thin gradient accent bar on top
            Container(
              height: 3,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [iconColor, iconColor.withAlpha(80)],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: iconBg,
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(icon, size: 21, color: iconColor),
                  ),
                  const SizedBox(height: 11),
                  Text(
                    value,
                    style: GoogleFonts.dmSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: valueColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF334155),
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.dmSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF94A3B8),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
