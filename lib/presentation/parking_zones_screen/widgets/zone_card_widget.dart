import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../theme/app_theme.dart';

enum DemandLevel { low, moderate, high }

class ParkingZoneData {
  final String zoneName;
  final String zoneCode;
  final String location;
  final int totalSlots;
  final int availableSlots;
  final DemandLevel demand;
  final double ratePerHour;
  final String distance;
  final IconData icon;
  final double lat;
  final double lng;

  const ParkingZoneData({
    required this.zoneName,
    required this.zoneCode,
    required this.location,
    required this.totalSlots,
    required this.availableSlots,
    required this.demand,
    required this.ratePerHour,
    required this.distance,
    required this.icon,
    this.lat = 23.2599,
    this.lng = 77.4126,
  });

  double get occupancyRatio => 1 - (availableSlots / totalSlots);
}

class ZoneCardWidget extends StatelessWidget {
  final ParkingZoneData zone;
  final int animIndex;

  const ZoneCardWidget({
    super.key,
    required this.zone,
    required this.animIndex,
  });

  Future<void> _openInMaps() async {
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
      '&destination=${zone.lat},${zone.lng}'
      '&travelmode=driving',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Color get _demandColor {
    switch (zone.demand) {
      case DemandLevel.low:
        return AppTheme.trafficClear;
      case DemandLevel.moderate:
        return AppTheme.trafficModerate;
      case DemandLevel.high:
        return AppTheme.trafficHeavy;
    }
  }

  Color get _demandBg {
    switch (zone.demand) {
      case DemandLevel.low:
        return AppTheme.trafficClearLight;
      case DemandLevel.moderate:
        return AppTheme.trafficModerateLight;
      case DemandLevel.high:
        return AppTheme.trafficHeavyLight;
    }
  }

  String get _demandLabel {
    switch (zone.demand) {
      case DemandLevel.low:
        return 'Low Demand';
      case DemandLevel.moderate:
        return 'Moderate';
      case DemandLevel.high:
        return 'High Demand';
    }
  }

  Color get _slotColor {
    if (zone.availableSlots == 0) return AppTheme.trafficHeavy;
    if (zone.availableSlots <= 3) return AppTheme.trafficModerate;
    return AppTheme.trafficClear;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withAlpha(12),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppTheme.surface.withAlpha(230),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppTheme.outline.withAlpha(120),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTopRow(),
                const SizedBox(height: 14),
                _buildOccupancyBar(),
                const SizedBox(height: 14),
                _buildBottomRow(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopRow() {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppTheme.primaryLight,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(zone.icon, size: 22, color: AppTheme.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    zone.zoneName,
                    style: GoogleFonts.dmSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      zone.zoneCode,
                      style: GoogleFonts.dmSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textMuted,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  const Icon(
                    Icons.location_on_rounded,
                    size: 11,
                    color: AppTheme.textMuted,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    zone.location,
                    style: GoogleFonts.dmSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                      color: AppTheme.textMuted,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '· ${zone.distance}',
                    style: GoogleFonts.dmSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '₹${zone.ratePerHour.toStringAsFixed(0)}',
              style: GoogleFonts.dmSans(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppTheme.primary,
                letterSpacing: -0.3,
              ),
            ),
            Text(
              'per hour',
              style: GoogleFonts.dmSans(
                fontSize: 10,
                fontWeight: FontWeight.w400,
                color: AppTheme.textMuted,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOccupancyBar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Occupancy',
              style: GoogleFonts.dmSans(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppTheme.textMuted,
              ),
            ),
            Text(
              '${(zone.occupancyRatio * 100).toInt()}% filled',
              style: GoogleFonts.dmSans(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: zone.occupancyRatio,
            minHeight: 6,
            backgroundColor: AppTheme.outlineVariant,
            valueColor: AlwaysStoppedAnimation<Color>(_demandColor),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomRow() {
    return Row(
      children: [
        // Available slots chip
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: _slotColor.withAlpha(20),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _slotColor.withAlpha(60), width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.local_parking_rounded, size: 13, color: _slotColor),
              const SizedBox(width: 5),
              Text(
                zone.availableSlots == 0
                    ? 'Full'
                    : '${zone.availableSlots} slots free',
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _slotColor,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        // Demand badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: _demandBg,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                zone.demand == DemandLevel.high
                    ? Icons.trending_up_rounded
                    : zone.demand == DemandLevel.moderate
                    ? Icons.trending_flat_rounded
                    : Icons.trending_down_rounded,
                size: 13,
                color: _demandColor,
              ),
              const SizedBox(width: 4),
              Text(
                _demandLabel,
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _demandColor,
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        // Navigate button → opens Google Maps
        GestureDetector(
          onTap: () => _openInMaps(),
          child: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1A6BF5), Color(0xFF4A8FFF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primary.withAlpha(60),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Icon(Icons.directions_rounded, size: 16, color: Colors.white),
          ),
        ),
      ],
    );
  }
}
