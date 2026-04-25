import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';

class TrafficConditionsBarWidget extends StatelessWidget {
  const TrafficConditionsBarWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'City Overview',
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const Spacer(),
              Text(
                'Apr 25 · 10:46 AM',
                style: GoogleFonts.dmSans(
                  fontSize: 11,
                  color: AppTheme.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Segmented bar
          ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: Row(
              children: [
                Expanded(
                  flex: 40,
                  child: Container(height: 10, color: AppTheme.trafficHeavy),
                ),
                Expanded(
                  flex: 35,
                  child: Container(height: 10, color: AppTheme.trafficModerate),
                ),
                Expanded(
                  flex: 25,
                  child: Container(height: 10, color: AppTheme.trafficClear),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _BarLegend(color: AppTheme.trafficHeavy, label: 'Heavy 40%'),
              const SizedBox(width: 14),
              _BarLegend(
                color: AppTheme.trafficModerate,
                label: 'Moderate 35%',
              ),
              const SizedBox(width: 14),
              _BarLegend(color: AppTheme.trafficClear, label: 'Clear 25%'),
            ],
          ),
        ],
      ),
    );
  }
}

class _BarLegend extends StatelessWidget {
  final Color color;
  final String label;

  const _BarLegend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }
}
