import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';
import '../../../core/services/weather_service.dart';

class QuickInsightsWidget extends StatefulWidget {
  const QuickInsightsWidget({super.key});

  @override
  State<QuickInsightsWidget> createState() => _QuickInsightsWidgetState();
}

class _QuickInsightsWidgetState extends State<QuickInsightsWidget> {
  final WeatherService _weatherService = WeatherService();
  WeatherData? _weatherData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWeather();
  }

  Future<void> _loadWeather() async {
    final data = await _weatherService.fetchWeather();
    if (mounted) {
      setState(() {
        _weatherData = data;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final weather = _weatherData;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Insights',
          style: GoogleFonts.dmSans(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _InsightCard(
                icon: Icons.directions_car_rounded,
                label: 'Traffic',
                value: 'Heavy',
                subtitle: 'Hamidia Rd',
                iconBg: AppTheme.trafficHeavyLight,
                iconColor: AppTheme.trafficHeavy,
                valueColor: AppTheme.trafficHeavy,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _isLoading
                  ? _InsightCardSkeleton()
                  : _InsightCard(
                      icon: _weatherIcon(weather?.condition ?? 'Clear'),
                      label: 'Weather',
                      value: weather?.conditionLabel ?? 'Clear',
                      subtitle: weather?.insightSubtitle ?? '—',
                      iconBg: const Color(0xFFEFF6FF),
                      iconColor: _weatherIconColor(
                        weather?.condition ?? 'Clear',
                      ),
                      valueColor: _weatherValueColor(
                        weather?.condition ?? 'Clear',
                      ),
                    ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _InsightCard(
                icon: Icons.warning_amber_rounded,
                label: 'Alerts',
                value: (weather?.hasAlert == true) ? '1+' : '0',
                subtitle: (weather?.hasAlert == true)
                    ? 'Weather alert'
                    : 'All clear',
                iconBg: (weather?.hasAlert == true)
                    ? AppTheme.warningLight
                    : const Color(0xFFECFDF5),
                iconColor: (weather?.hasAlert == true)
                    ? AppTheme.warning
                    : const Color(0xFF10B981),
                valueColor: (weather?.hasAlert == true)
                    ? AppTheme.warning
                    : const Color(0xFF059669),
              ),
            ),
          ],
        ),
      ],
    );
  }

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
}

class _InsightCardSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.grey.withAlpha(40),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            height: 16,
            width: 50,
            decoration: BoxDecoration(
              color: Colors.grey.withAlpha(40),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 4),
          Container(
            height: 10,
            width: 40,
            decoration: BoxDecoration(
              color: Colors.grey.withAlpha(25),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }
}

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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: GoogleFonts.dmSans(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: valueColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.dmSans(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
          ),
          Text(
            subtitle,
            style: GoogleFonts.dmSans(
              fontSize: 10,
              fontWeight: FontWeight.w400,
              color: AppTheme.textMuted,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
