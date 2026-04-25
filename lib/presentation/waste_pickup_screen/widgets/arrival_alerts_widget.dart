import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';

class ArrivalAlertsWidget extends StatelessWidget {
  const ArrivalAlertsWidget({super.key});

  static final List<Map<String, dynamic>> _alerts = [
    {
      'icon': Icons.local_shipping_rounded,
      'title': 'Garbage truck arriving soon',
      'subtitle': 'Truck is 2 stops away · ~12 min',
      'time': 'Now',
      'level': 'warning',
      'isLive': true,
    },
    {
      'icon': Icons.notifications_active_rounded,
      'title': 'Bin collection reminder',
      'subtitle': 'Place your bin outside by 7:30 AM',
      'time': '6:00 AM',
      'level': 'info',
      'isLive': false,
    },
    {
      'icon': Icons.check_circle_outline_rounded,
      'title': 'Last pickup completed',
      'subtitle': 'Collected on time · 8:05 AM',
      'time': 'Yesterday',
      'level': 'success',
      'isLive': false,
    },
    {
      'icon': Icons.recycling_rounded,
      'title': 'Recycling day next week',
      'subtitle': 'Blue bin · Wednesday 8 AM',
      'time': 'May 1',
      'level': 'info',
      'isLive': false,
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
              'Arrival Alerts',
              style: GoogleFonts.dmSans(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.primaryLight,
                borderRadius: BorderRadius.circular(100),
              ),
              child: Text(
                '4 alerts',
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
        ...List.generate(_alerts.length, (i) {
          final alert = _alerts[i];
          return Padding(
            padding: EdgeInsets.only(bottom: i < _alerts.length - 1 ? 10 : 0),
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

  Color get _iconColor {
    switch (data['level'] as String) {
      case 'warning':
        return AppTheme.warning;
      case 'success':
        return AppTheme.success;
      case 'info':
      default:
        return AppTheme.primary;
    }
  }

  Color get _iconBg {
    switch (data['level'] as String) {
      case 'warning':
        return AppTheme.warningLight;
      case 'success':
        return AppTheme.successLight;
      case 'info':
      default:
        return AppTheme.primaryLight;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLive = data['isLive'] as bool;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isLive ? AppTheme.warningLight.withAlpha(120) : AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isLive
              ? AppTheme.warning.withAlpha(80)
              : AppTheme.outline.withAlpha(80),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _iconBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(data['icon'] as IconData, size: 18, color: _iconColor),
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
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isLive)
                      Container(
                        margin: const EdgeInsets.only(left: 6),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.warning,
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Text(
                          'LIVE',
                          style: GoogleFonts.dmSans(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  data['subtitle'] as String,
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: AppTheme.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            data['time'] as String,
            style: GoogleFonts.dmSans(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppTheme.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
