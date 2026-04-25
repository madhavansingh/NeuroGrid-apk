import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/status_badge_widget.dart';

class CityAlertsFeedWidget extends StatelessWidget {
  const CityAlertsFeedWidget({super.key});

  static final List<Map<String, dynamic>> _alertsMaps = [
    {
      'icon': 'traffic',
      'title': 'Heavy congestion near New Market',
      'description': 'Expect 20+ min delay. Alternate via Board Office Rd.',
      'time': '8 min ago',
      'level': 'heavy',
      'category': 'Traffic',
    },
    {
      'icon': 'water',
      'title': 'Water supply disruption — Zone 4',
      'description':
          'Maintenance work until 2 PM today. Store water in advance.',
      'time': '34 min ago',
      'level': 'moderate',
      'category': 'Utility',
    },
    {
      'icon': 'warning',
      'title': 'Air quality index rising',
      'description':
          'AQI at 142 in MP Nagar. Avoid outdoor exercise before 10 AM.',
      'time': '1 hr ago',
      'level': 'warning',
      'category': 'Health',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Live City Alerts',
              style: GoogleFonts.dmSans(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppTheme.primaryLight,
                borderRadius: BorderRadius.circular(100),
              ),
              child: Text(
                '${_alertsMaps.length} active',
                style: GoogleFonts.dmSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...List.generate(_alertsMaps.length, (i) {
          final alert = _alertsMaps[i];
          return Padding(
            padding: EdgeInsets.only(
              bottom: i < _alertsMaps.length - 1 ? 10 : 0,
            ),
            child: _AlertCard(data: alert),
          );
        }),
      ],
    );
  }
}

class _AlertCard extends StatelessWidget {
  final Map<String, dynamic> data;

  const _AlertCard({required this.data});

  IconData get _icon {
    switch (data['icon'] as String) {
      case 'traffic':
        return Icons.traffic_rounded;
      case 'water':
        return Icons.water_drop_outlined;
      case 'warning':
      default:
        return Icons.warning_amber_rounded;
    }
  }

  Color get _iconBg {
    switch (data['level'] as String) {
      case 'heavy':
        return AppTheme.trafficHeavyLight;
      case 'moderate':
        return AppTheme.trafficModerateLight;
      case 'warning':
      default:
        return AppTheme.warningLight;
    }
  }

  Color get _iconColor {
    switch (data['level'] as String) {
      case 'heavy':
        return AppTheme.trafficHeavy;
      case 'moderate':
        return AppTheme.trafficModerate;
      case 'warning':
      default:
        return AppTheme.warning;
    }
  }

  StatusLevel get _statusLevel {
    switch (data['level'] as String) {
      case 'heavy':
        return StatusLevel.heavy;
      case 'moderate':
        return StatusLevel.moderate;
      case 'warning':
      default:
        return StatusLevel.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _iconBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(_icon, size: 20, color: _iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        data['title'] as String,
                        style: GoogleFonts.dmSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    StatusBadgeWidget(
                      label: data['category'] as String,
                      level: _statusLevel,
                      compact: true,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  data['description'] as String,
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: AppTheme.textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  data['time'] as String,
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
