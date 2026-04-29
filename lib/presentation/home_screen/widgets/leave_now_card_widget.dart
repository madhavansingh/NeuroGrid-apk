import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/services/weather_service.dart';
import '../../../providers/city_state_provider.dart';
import '../../../routes/app_routes.dart';

/// Hero decision card — "Should you leave now?"
/// Pulls live traffic status from cityStateProvider and live weather from
/// WeatherService to give a real, data-driven departure recommendation.
class LeaveNowCardWidget extends ConsumerStatefulWidget {
  const LeaveNowCardWidget({super.key});
  @override
  ConsumerState<LeaveNowCardWidget> createState() => _LeaveNowCardWidgetState();
}

class _LeaveNowCardWidgetState extends ConsumerState<LeaveNowCardWidget>
    with TickerProviderStateMixin {
  late AnimationController _shimmerCtrl;
  late AnimationController _pulseCtrl;
  bool _loaded = false;

  WeatherData? _weather;

  @override
  void initState() {
    super.initState();

    _shimmerCtrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 2))
          ..repeat();

    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);

    // Load weather then reveal card
    WeatherService().fetchWeather().then((w) {
      if (mounted) {
        setState(() {
          _weather = w;
          _loaded = true;
        });
      }
    }).catchError((_) {
      if (mounted) setState(() => _loaded = true);
    });
  }

  @override
  void dispose() {
    _shimmerCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  // ── Advice computation ─────────────────────────────────────────────────────

  _Advice _computeAdvice(String trafficStatus, WeatherData? weather) {
    final isRainy = weather?.isAdverseWeather ?? false;
    final heavy   = trafficStatus.toLowerCase() == 'heavy';
    final mod     = trafficStatus.toLowerCase() == 'moderate';

    if (heavy && isRainy) {
      return _Advice(
        label:    'Avoid — heavy traffic + rain',
        icon:     Icons.dangerous_rounded,
        chipBg:   const Color(0xFFFFF1F2),
        chipFg:   const Color(0xFFDC2626),
        body:     'Heavy congestion detected across major arteries AND adverse weather '
                  'conditions. Consider delaying by 30+ minutes or using an alternate route.',
      );
    }
    if (heavy) {
      return _Advice(
        label:    'Wait 20–30 minutes',
        icon:     Icons.schedule_rounded,
        chipBg:   const Color(0xFFFFFBEB),
        chipFg:   const Color(0xFFD97706),
        body:     'Heavy traffic on key routes right now. Conditions should improve '
                  'in 20–30 min. Weather is ${weather?.conditionLabel ?? 'clear'} — '
                  'roads are otherwise passable.',
      );
    }
    if (mod && isRainy) {
      return _Advice(
        label:    'Leave with caution',
        icon:     Icons.warning_amber_rounded,
        chipBg:   const Color(0xFFFFFBEB),
        chipFg:   const Color(0xFFF59E0B),
        body:     'Moderate traffic plus ${weather?.conditionLabel ?? 'rain'} — slow '
                  'down and allow extra travel time. Check your route before heading out.',
      );
    }
    if (mod) {
      return _Advice(
        label:    'Leave soon — moderate flow',
        icon:     Icons.directions_car_rounded,
        chipBg:   const Color(0xFFEFF6FF),
        chipFg:   const Color(0xFF1A6BF5),
        body:     'Traffic is moderate. Leaving within the next 10 min should give '
                  'you good flow. Weather: ${weather?.conditionLabel ?? 'Clear'}, '
                  '${weather?.tempCelsius.round() ?? 32}°C.',
      );
    }
    return _Advice(
      label:    'Great time to leave! 🟢',
      icon:     Icons.check_circle_rounded,
      chipBg:   const Color(0xFFECFDF5),
      chipFg:   const Color(0xFF059669),
      body:     'Traffic is flowing smoothly across Bhopal. '
                'Weather: ${weather?.conditionLabel ?? 'Clear'}, '
                '${weather?.tempCelsius.round() ?? 32}°C · '
                '${weather?.humidity ?? 55}% humidity. Perfect driving conditions!',
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (!_loaded) return _buildShimmer();

    final cityAsync = ref.watch(cityStateProvider);

    return cityAsync.when(
      loading: () => _buildShimmer(),
      error: (_, __) => _buildCardContent(_computeAdvice('smooth', _weather)),
      data: (cityState) {
        final traffic = cityState?.traffic;
        final status = traffic != null ? traffic.status : 'smooth';
        return _buildCardContent(_computeAdvice(status, _weather));
      },
    );
  }

  // ── Loaded card ────────────────────────────────────────────────────────────

  Widget _buildCardContent(_Advice advice) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      child: Container(
        key: ValueKey(advice.label),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1565C0), Color(0xFF1A6BF5), Color(0xFF3A8BFF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
                color: const Color(0xFF1A6BF5).withAlpha(70),
                blurRadius: 28,
                offset: const Offset(0, 10)),
          ],
        ),
        child: Stack(children: [
          // Decorative circles
          Positioned(
            top: -30, right: -20,
            child: Container(
              width: 130, height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withAlpha(15),
              ),
            ),
          ),
          Positioned(
            bottom: -20, left: -30,
            child: Container(
              width: 100, height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withAlpha(10),
              ),
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title row with live pulse
                Row(children: [
                  AnimatedBuilder(
                    animation: _pulseCtrl,
                    builder: (_, __) => Container(
                      width: 8, height: 8,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(
                            0.5 + 0.5 * _pulseCtrl.value),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text('Should you leave now?',
                      style: GoogleFonts.dmSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.white70)),
                  const Spacer(),
                  // Weather mini-badge
                  if (_weather != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(22),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.thermostat_rounded,
                            size: 11, color: Colors.white70),
                        const SizedBox(width: 3),
                        Text('${_weather!.tempCelsius.round()}°C',
                            style: GoogleFonts.dmSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.white70)),
                      ]),
                    ),
                ]),

                const SizedBox(height: 12),

                // Decision chip
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: advice.chipBg,
                    borderRadius: BorderRadius.circular(50),
                    boxShadow: [
                      BoxShadow(
                          color: advice.chipFg.withAlpha(40),
                          blurRadius: 10,
                          offset: const Offset(0, 4))
                    ],
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(advice.icon, size: 16, color: advice.chipFg),
                    const SizedBox(width: 8),
                    Text(advice.label,
                        style: GoogleFonts.dmSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: advice.chipFg)),
                  ]),
                ),

                const SizedBox(height: 14),

                // Body text
                Text(advice.body,
                    style: GoogleFonts.dmSans(
                        fontSize: 13.5,
                        color: Colors.white.withAlpha(215),
                        height: 1.55)),

                const SizedBox(height: 18),

                // Action buttons
                Row(children: [
                  Expanded(
                    child: _CardBtn(
                      label: 'View Route',
                      icon: Icons.directions_rounded,
                      onTap: () => Navigator.pushNamed(
                          context, AppRoutes.mapScreen),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _CardBtn(
                      label: 'Open Map',
                      icon: Icons.map_rounded,
                      onTap: () => Navigator.pushNamed(
                          context, AppRoutes.mapScreen),
                      outline: true,
                    ),
                  ),
                ]),
              ],
            ),
          ),
        ]),
      ),
    );
  }

  // ── Shimmer skeleton ────────────────────────────────────────────────────────

  Widget _buildShimmer() {
    return AnimatedBuilder(
      animation: _shimmerCtrl,
      builder: (_, __) {
        final shimmerGradient = LinearGradient(
          colors: [
            const Color(0xFFE8EEFF),
            const Color(0xFFD0DAFF),
            const Color(0xFFE8EEFF),
          ],
          stops: const [0.0, 0.5, 1.0],
          begin: Alignment(-1 + _shimmerCtrl.value * 3, 0),
          end: Alignment(1 + _shimmerCtrl.value * 3, 0),
        );
        return Container(
          height: 240,
          decoration: BoxDecoration(
            gradient: shimmerGradient,
            borderRadius: BorderRadius.circular(24),
          ),
          padding: const EdgeInsets.all(22),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _ShimmerBox(width: 160, height: 14, radius: 8),
            const SizedBox(height: 16),
            _ShimmerBox(width: 130, height: 36, radius: 50),
            const SizedBox(height: 16),
            _ShimmerBox(width: double.infinity, height: 13, radius: 8),
            const SizedBox(height: 7),
            _ShimmerBox(width: 220, height: 13, radius: 8),
          ]),
        );
      },
    );
  }
}

// ── Data model ─────────────────────────────────────────────────────────────────

class _Advice {
  final String label;
  final IconData icon;
  final Color chipBg;
  final Color chipFg;
  final String body;
  const _Advice({
    required this.label,
    required this.icon,
    required this.chipBg,
    required this.chipFg,
    required this.body,
  });
}

// ── Sub-widgets ─────────────────────────────────────────────────────────────────

class _CardBtn extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool outline;
  const _CardBtn({
    required this.label,
    required this.icon,
    required this.onTap,
    this.outline = false,
  });
  @override
  State<_CardBtn> createState() => _CardBtnState();
}

class _CardBtnState extends State<_CardBtn>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 80));
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        _c.forward();
        HapticFeedback.lightImpact();
      },
      onTapUp: (_) {
        _c.reverse();
        widget.onTap();
      },
      onTapCancel: () => _c.reverse(),
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, child) =>
            Transform.scale(scale: 1 - _c.value * 0.03, child: child),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: widget.outline ? Colors.white.withAlpha(20) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: widget.outline
                ? Border.all(color: Colors.white.withAlpha(80), width: 1.5)
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(widget.icon,
                  size: 16,
                  color: widget.outline
                      ? Colors.white
                      : const Color(0xFF1A6BF5)),
              const SizedBox(width: 7),
              Text(widget.label,
                  style: GoogleFonts.dmSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: widget.outline
                          ? Colors.white
                          : const Color(0xFF1A6BF5))),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShimmerBox extends StatelessWidget {
  final double width, height, radius;
  const _ShimmerBox(
      {required this.width, required this.height, required this.radius});
  @override
  Widget build(BuildContext context) => Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(60),
        borderRadius: BorderRadius.circular(radius),
      ));
}
