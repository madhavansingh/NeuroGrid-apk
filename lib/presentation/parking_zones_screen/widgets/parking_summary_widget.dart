import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';

class ParkingSummaryWidget extends StatelessWidget {
  final int totalAvailable;
  final int totalZones;
  final double avgRate;

  const ParkingSummaryWidget({
    super.key,
    required this.totalAvailable,
    required this.totalZones,
    required this.avgRate,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.primary.withAlpha(220),
                AppTheme.primaryDark.withAlpha(240),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withAlpha(40), width: 1),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primary.withAlpha(60),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              _SummaryStatItem(
                value: '$totalAvailable',
                label: 'Slots Free',
                icon: Icons.local_parking_rounded,
              ),
              _Divider(),
              _SummaryStatItem(
                value: '$totalZones',
                label: 'Zones',
                icon: Icons.grid_view_rounded,
              ),
              _Divider(),
              _SummaryStatItem(
                value: '₹${avgRate.toStringAsFixed(0)}/hr',
                label: 'Avg Rate',
                icon: Icons.payments_outlined,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 36,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      color: Colors.white.withAlpha(40),
    );
  }
}

class _SummaryStatItem extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;

  const _SummaryStatItem({
    required this.value,
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 16, color: Colors.white.withAlpha(200)),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.dmSans(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.3,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.dmSans(
              fontSize: 10,
              fontWeight: FontWeight.w400,
              color: Colors.white.withAlpha(180),
            ),
          ),
        ],
      ),
    );
  }
}
