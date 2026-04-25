import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';

class NotificationTogglesWidget extends StatefulWidget {
  const NotificationTogglesWidget({super.key});

  @override
  State<NotificationTogglesWidget> createState() =>
      _NotificationTogglesWidgetState();
}

class _NotificationTogglesWidgetState extends State<NotificationTogglesWidget> {
  final List<_ToggleItem> _toggles = [
    _ToggleItem(
      label: 'Traffic Alerts',
      subtitle: 'Heavy congestion & route updates',
      icon: Icons.traffic_rounded,
      color: Color(0xFFEF4444),
      enabled: true,
    ),
    _ToggleItem(
      label: 'Weather Warnings',
      subtitle: 'Rain, fog & severe conditions',
      icon: Icons.cloud_rounded,
      color: Color(0xFF3B82F6),
      enabled: true,
    ),
    _ToggleItem(
      label: 'Waste Pickup',
      subtitle: 'Pickup reminders & truck arrival',
      icon: Icons.delete_outline_rounded,
      color: Color(0xFF16A34A),
      enabled: true,
    ),
    _ToggleItem(
      label: 'Parking Updates',
      subtitle: 'Slot availability in saved zones',
      icon: Icons.local_parking_rounded,
      color: Color(0xFF7C3AED),
      enabled: false,
    ),
    _ToggleItem(
      label: 'City Announcements',
      subtitle: 'Events, maintenance & news',
      icon: Icons.campaign_rounded,
      color: Color(0xFFD97706),
      enabled: false,
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
                'Notifications',
                style: GoogleFonts.dmSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primaryLight,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '3 active',
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ..._toggles.asMap().entries.map((entry) {
            final i = entry.key;
            final item = entry.value;
            return Column(
              children: [
                _ToggleRow(
                  item: item,
                  onChanged: (val) {
                    setState(() => _toggles[i] = item.copyWith(enabled: val));
                  },
                ),
                if (i < _toggles.length - 1)
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

class _ToggleRow extends StatelessWidget {
  final _ToggleItem item;
  final ValueChanged<bool> onChanged;

  const _ToggleRow({required this.item, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: item.enabled
                ? item.color.withAlpha(20)
                : AppTheme.outlineVariant,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(
            item.icon,
            size: 17,
            color: item.enabled ? item.color : AppTheme.textMuted,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.label,
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: item.enabled
                      ? AppTheme.textPrimary
                      : AppTheme.textMuted,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                item.subtitle,
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
        const SizedBox(width: 8),
        Transform.scale(
          scale: 0.82,
          child: Switch(
            value: item.enabled,
            onChanged: onChanged,
            activeThumbColor: AppTheme.primary,
            activeTrackColor: AppTheme.primaryLight,
            inactiveThumbColor: AppTheme.textMuted,
            inactiveTrackColor: AppTheme.outlineVariant,
          ),
        ),
      ],
    );
  }
}

class _ToggleItem {
  final String label;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool enabled;

  const _ToggleItem({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.enabled,
  });

  _ToggleItem copyWith({bool? enabled}) {
    return _ToggleItem(
      label: label,
      subtitle: subtitle,
      icon: icon,
      color: color,
      enabled: enabled ?? this.enabled,
    );
  }
}
