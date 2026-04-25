import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';
import '../../../routes/app_routes.dart';

class CityServicesGridWidget extends StatelessWidget {
  const CityServicesGridWidget({super.key});

  static final List<Map<String, dynamic>> _servicesMaps = [
    {
      'icon': Icons.local_parking_rounded,
      'label': 'Parking',
      'status': '12 spots',
      'statusLevel': 'clear',
      'route': AppRoutes.parkingZonesScreen,
    },
    {
      'icon': Icons.delete_outline_rounded,
      'label': 'Waste',
      'status': 'Tomorrow',
      'statusLevel': 'info',
      'route': AppRoutes.wastePickupScreen,
    },
    {
      'icon': Icons.report_problem_outlined,
      'label': 'Issues',
      'status': 'Report',
      'statusLevel': 'warning',
      'route': AppRoutes.civicIssuesScreen,
    },
    {
      'icon': Icons.smart_toy_outlined,
      'label': 'AI Chat',
      'status': 'Ask me',
      'statusLevel': 'info',
      'route': AppRoutes.aiAssistantScreen,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'City Services',
          style: GoogleFonts.dmSans(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 0.85,
          ),
          itemCount: _servicesMaps.length,
          itemBuilder: (context, i) {
            final s = _servicesMaps[i];
            return _ServiceTile(data: s);
          },
        ),
      ],
    );
  }
}

class _ServiceTile extends StatelessWidget {
  final Map<String, dynamic> data;

  const _ServiceTile({required this.data});

  Color get _statusColor {
    switch (data['statusLevel'] as String) {
      case 'clear':
        return AppTheme.trafficClear;
      case 'warning':
        return AppTheme.warning;
      case 'info':
      default:
        return AppTheme.primary;
    }
  }

  Color get _statusBg {
    switch (data['statusLevel'] as String) {
      case 'clear':
        return AppTheme.trafficClearLight;
      case 'warning':
        return AppTheme.warningLight;
      case 'info':
      default:
        return AppTheme.primaryLight;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (data['route'] != null) {
          Navigator.pushNamed(context, data['route'] as String);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(10),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _statusBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                data['icon'] as IconData,
                size: 20,
                color: _statusColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              data['label'] as String,
              style: GoogleFonts.dmSans(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),
            Text(
              data['status'] as String,
              style: GoogleFonts.dmSans(
                fontSize: 10,
                fontWeight: FontWeight.w400,
                color: _statusColor,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
