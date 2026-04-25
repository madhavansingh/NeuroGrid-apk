import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';

class SavedLocationsWidget extends StatefulWidget {
  const SavedLocationsWidget({super.key});

  @override
  State<SavedLocationsWidget> createState() => _SavedLocationsWidgetState();
}

class _SavedLocationsWidgetState extends State<SavedLocationsWidget> {
  final List<_LocationData> _locations = [
    _LocationData(
      label: 'Home',
      address: 'E-7, Arera Colony, Bhopal',
      icon: Icons.home_rounded,
      color: const Color(0xFF1A6BF5),
    ),
    _LocationData(
      label: 'Work',
      address: 'MP Nagar Zone II, Bhopal',
      icon: Icons.business_center_rounded,
      color: const Color(0xFF7C3AED),
    ),
    _LocationData(
      label: 'Gym',
      address: 'New Market, T.T. Nagar',
      icon: Icons.fitness_center_rounded,
      color: const Color(0xFF16A34A),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.outline, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Saved Locations',
                style: GoogleFonts.dmSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () {},
                child: Text(
                  '+ Add',
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ..._locations.asMap().entries.map((entry) {
            final i = entry.key;
            final loc = entry.value;
            return Column(
              children: [
                _LocationRow(location: loc),
                if (i < _locations.length - 1)
                  Divider(
                    color: AppTheme.outlineVariant,
                    height: 20,
                    thickness: 1,
                  ),
              ],
            );
          }),
        ],
      ),
    );
  }
}

class _LocationRow extends StatelessWidget {
  final _LocationData location;

  const _LocationRow({required this.location});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: location.color.withAlpha(20),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(location.icon, size: 18, color: location.color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                location.label,
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                location.address,
                style: GoogleFonts.dmSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                  color: AppTheme.textMuted,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        Icon(Icons.chevron_right_rounded, size: 18, color: AppTheme.textMuted),
      ],
    );
  }
}

class _LocationData {
  final String label;
  final String address;
  final IconData icon;
  final Color color;

  const _LocationData({
    required this.label,
    required this.address,
    required this.icon,
    required this.color,
  });
}
