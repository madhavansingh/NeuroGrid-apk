import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/services/weather_service.dart';
import '../../../providers/weather_provider.dart';
import '../../../providers/location_provider.dart';

/// Premium full-width weather card for the home screen.
/// Reads real-time weather from [weatherProvider] (GPS-aware, no AppConfig race).
class WeatherHeroCard extends ConsumerStatefulWidget {
  const WeatherHeroCard({super.key});

  @override
  ConsumerState<WeatherHeroCard> createState() => _WeatherHeroCardState();
}

class _WeatherHeroCardState extends ConsumerState<WeatherHeroCard>
    with TickerProviderStateMixin {
  late AnimationController _cloudCtrl;
  late AnimationController _shimmerCtrl;

  @override
  void initState() {
    super.initState();

    _cloudCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat(reverse: true);

    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    // Kick off GPS fetch so weatherProvider gets real coordinates
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final loc = ref.read(locationProvider);
      if (!loc.hasLocation && !loc.loading) {
        ref.read(locationProvider.notifier).fetchLocation();
      }
    });
  }

  @override
  void dispose() {
    _cloudCtrl.dispose();
    _shimmerCtrl.dispose();
    super.dispose();
  }

  // ── Gradient by condition ──────────────────────────────────────────────────

  List<Color> _skyGradient(String condition) {
    switch (condition.toLowerCase()) {
      case 'thunderstorm':
        return [const Color(0xFF1A1A3E), const Color(0xFF3B2B6B)];
      case 'rain':
      case 'drizzle':
        return [const Color(0xFF1E3A5F), const Color(0xFF2D6A9F)];
      case 'snow':
        return [const Color(0xFF8EB8E5), const Color(0xFFCEE8F8)];
      case 'clouds':
        return [const Color(0xFF3D5A80), const Color(0xFF6B8DB8)];
      case 'mist':
      case 'fog':
      case 'haze':
        return [const Color(0xFF4A5568), const Color(0xFF718096)];
      case 'clear':
      default:
        final hour = DateTime.now().hour;
        if (hour >= 6 && hour < 12) {
          return [const Color(0xFF0F4C81), const Color(0xFFF97316)];
        } else if (hour >= 12 && hour < 17) {
          return [const Color(0xFF0369A1), const Color(0xFF38BDF8)];
        } else if (hour >= 17 && hour < 20) {
          return [const Color(0xFF9A3412), const Color(0xFFFBBF24)];
        } else {
          return [const Color(0xFF0A0E2A), const Color(0xFF1E3A6E)];
        }
    }
  }

  IconData _conditionIcon(String condition) {
    switch (condition.toLowerCase()) {
      case 'thunderstorm':
        return Icons.thunderstorm_rounded;
      case 'drizzle':
        return Icons.grain_rounded;
      case 'rain':
        return Icons.umbrella_rounded;
      case 'snow':
        return Icons.ac_unit_rounded;
      case 'clouds':
        return Icons.cloud_rounded;
      case 'mist':
      case 'fog':
      case 'haze':
        return Icons.blur_on_rounded;
      case 'clear':
      default:
        final hour = DateTime.now().hour;
        return (hour >= 6 && hour < 19)
            ? Icons.wb_sunny_rounded
            : Icons.nightlight_round;
    }
  }

  String _windDir(double speed) {
    if (speed < 2) return 'Calm';
    if (speed < 6) return 'Light';
    if (speed < 12) return 'Moderate';
    return 'Strong';
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final weatherAsync = ref.watch(weatherProvider);
    final locState = ref.watch(locationProvider);

    return weatherAsync.when(
      loading: () => _buildSkeleton(),
      error: (_, __) => _buildWeatherCard(WeatherData.fallback, locState.areaLabel),
      data: (d) => _buildWeatherCard(d, locState.areaLabel),
    );
  }

  Widget _buildWeatherCard(WeatherData d, String areaLabel) {
    final gradient = _skyGradient(d.condition);
    final icon = _conditionIcon(d.condition);

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: gradient.first.withAlpha(100),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // ── Animated cloud blobs ─────────────────────────────────────────
            AnimatedBuilder(
              animation: _cloudCtrl,
              builder: (_, __) => CustomPaint(
                painter: _CloudPainter(_cloudCtrl.value),
                child: const SizedBox.expand(),
              ),
            ),

            // ── Content ──────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top row — location label + badges
                  Row(children: [
                    const Icon(Icons.location_on_rounded,
                        size: 13, color: Colors.white70),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        areaLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.dmSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white70),
                      ),
                    ),
                    const Spacer(),
                    // LIVE badge
                    _Badge(
                      icon: Icons.sensors_rounded,
                      label: 'LIVE',
                      color: const Color(0xFF4ADE80),
                    ),
                    if (d.hasAlert) ...[
                      const SizedBox(width: 6),
                      _Badge(
                        icon: Icons.warning_amber_rounded,
                        label: 'Alert',
                        color: const Color(0xFFFBBF24),
                      ),
                    ],
                  ]),

                  const SizedBox(height: 18),

                  // Main row — big temp + icon
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Temperature column
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: '${d.tempCelsius.round()}',
                                  style: GoogleFonts.dmSans(
                                    fontSize: 68,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    height: 1.0,
                                  ),
                                ),
                                TextSpan(
                                  text: '°C',
                                  style: GoogleFonts.dmSans(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w400,
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(d.conditionLabel,
                              style: GoogleFonts.dmSans(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                  letterSpacing: 0.2)),
                          const SizedBox(height: 2),
                          Text('Feels like ${d.feelsLike.round()}°C',
                              style: GoogleFonts.dmSans(
                                  fontSize: 12,
                                  color: Colors.white60)),
                        ],
                      ),

                      const Spacer(),

                      // Weather icon — pulsing
                      _PulsingIcon(icon: icon, ctrl: _shimmerCtrl),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Divider
                  Container(height: 1, color: Colors.white.withAlpha(30)),

                  const SizedBox(height: 16),

                  // Bottom stats row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _StatPill(
                          icon: Icons.water_drop_rounded,
                          value: '${d.humidity}%',
                          label: 'Humidity'),
                      _StatPill(
                          icon: Icons.air_rounded,
                          value: '${d.windSpeed.toStringAsFixed(1)} m/s',
                          label: _windDir(d.windSpeed)),
                      _StatPill(
                          icon: Icons.thermostat_rounded,
                          value: '${d.tempCelsius.round()}°',
                          label: d.description.isNotEmpty
                              ? _capitalize(d.description)
                              : 'Temperature'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  Widget _buildSkeleton() {
    return AnimatedBuilder(
      animation: _shimmerCtrl,
      builder: (_, __) {
        final opacity = 0.3 + 0.2 * _shimmerCtrl.value;
        return Container(
          margin: const EdgeInsets.fromLTRB(20, 0, 20, 0),
          height: 200,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF3D5A80).withAlpha((opacity * 255).toInt()),
                const Color(0xFF6B8DB8).withAlpha((opacity * 200).toInt()),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    color: Colors.white54,
                    strokeWidth: 2.5,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Loading weather…',
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    color: Colors.white60,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _Badge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _Badge({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(25),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withAlpha(180), width: 1),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: GoogleFonts.dmSans(
                  fontSize: 10, fontWeight: FontWeight.w700, color: color)),
        ]),
      );
}

class _PulsingIcon extends StatelessWidget {
  final IconData icon;
  final AnimationController ctrl;
  const _PulsingIcon({required this.icon, required this.ctrl});

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: ctrl,
        builder: (_, __) {
          final scale = 1.0 + 0.06 * math.sin(ctrl.value * math.pi);
          return Transform.scale(
            scale: scale,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(20),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 44, color: Colors.white),
            ),
          );
        },
      );
}

class _StatPill extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  const _StatPill(
      {required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(22),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: Colors.white),
          ),
          const SizedBox(height: 5),
          Text(value,
              style: GoogleFonts.dmSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.white)),
          Text(label,
              style:
                  GoogleFonts.dmSans(fontSize: 10, color: Colors.white60)),
        ],
      );
}

// ── Cloud painter ─────────────────────────────────────────────────────────────

class _CloudPainter extends CustomPainter {
  final double progress;
  const _CloudPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withAlpha(14);

    final offset1 = math.sin(progress * math.pi) * 30;
    final offset2 = math.cos(progress * math.pi) * 20;

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.6 + offset1, size.height * 0.3),
        width: 160,
        height: 70,
      ),
      paint,
    );
    paint.color = Colors.white.withAlpha(10);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.2 + offset2, size.height * 0.7),
        width: 120,
        height: 55,
      ),
      paint,
    );
    paint.color = Colors.white.withAlpha(8);
    canvas.drawOval(
      Rect.fromCenter(
        center:
            Offset(size.width * 0.85 - offset1 * 0.5, size.height * 0.15),
        width: 80,
        height: 40,
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(_CloudPainter old) => old.progress != progress;
}
