import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/status_badge_widget.dart';

class TrafficEventCardWidget extends StatefulWidget {
  final Map<String, dynamic> data;

  const TrafficEventCardWidget({super.key, required this.data});

  @override
  State<TrafficEventCardWidget> createState() => _TrafficEventCardWidgetState();
}

class _TrafficEventCardWidgetState extends State<TrafficEventCardWidget> {
  bool _expanded = false;

  Color get _severityColor {
    switch (widget.data['severity'] as String) {
      case 'heavy':
        return AppTheme.trafficHeavy;
      case 'moderate':
        return AppTheme.trafficModerate;
      case 'clear':
      default:
        return AppTheme.trafficClear;
    }
  }

  Color get _severityBg {
    switch (widget.data['severity'] as String) {
      case 'heavy':
        return AppTheme.trafficHeavyLight;
      case 'moderate':
        return AppTheme.trafficModerateLight;
      case 'clear':
      default:
        return AppTheme.trafficClearLight;
    }
  }

  StatusLevel get _statusLevel {
    switch (widget.data['severity'] as String) {
      case 'heavy':
        return StatusLevel.heavy;
      case 'moderate':
        return StatusLevel.moderate;
      case 'clear':
      default:
        return StatusLevel.clear;
    }
  }

  IconData get _severityIcon {
    switch (widget.data['severity'] as String) {
      case 'heavy':
        return Icons.warning_amber_rounded;
      case 'moderate':
        return Icons.info_outline_rounded;
      case 'clear':
      default:
        return Icons.check_circle_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final affectedRoutes = (widget.data['affectedRoutes'] as List<dynamic>)
        .cast<String>();

    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border(left: BorderSide(color: _severityColor, width: 3.5)),
          boxShadow: [
            BoxShadow(
              color: _severityColor.withAlpha(20),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _severityBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(_severityIcon, size: 20, color: _severityColor),
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
                                widget.data['area'] as String,
                                style: GoogleFonts.dmSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            StatusBadgeWidget(
                              label:
                                  (widget.data['severity'] as String)
                                      .substring(0, 1)
                                      .toUpperCase() +
                                  (widget.data['severity'] as String).substring(
                                    1,
                                  ),
                              level: _statusLevel,
                              compact: true,
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.data['zone'] as String,
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
              const SizedBox(height: 12),
              Text(
                widget.data['description'] as String,
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: AppTheme.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 12),
              // Metadata row
              Row(
                children: [
                  _MetaChip(
                    icon: Icons.schedule_rounded,
                    label: widget.data['delay'] as String,
                    color: widget.data['delay'] == 'No delay'
                        ? AppTheme.trafficClear
                        : AppTheme.trafficHeavy,
                  ),
                  const SizedBox(width: 8),
                  _MetaChip(
                    icon: Icons.near_me_rounded,
                    label: widget.data['distance'] as String,
                    color: AppTheme.primary,
                  ),
                  const Spacer(),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0.0,
                    duration: const Duration(milliseconds: 220),
                    child: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 18,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ],
              ),
              // Expanded: affected routes + timestamp
              AnimatedCrossFade(
                duration: const Duration(milliseconds: 240),
                crossFadeState: _expanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                firstChild: const SizedBox(height: 0),
                secondChild: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),
                    Container(height: 1, color: AppTheme.outlineVariant),
                    const SizedBox(height: 12),
                    Text(
                      'Affected Routes',
                      style: GoogleFonts.dmSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textMuted,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: affectedRoutes.map((route) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceVariant,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            route,
                            style: GoogleFonts.dmSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      widget.data['updatedAt'] as String,
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
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _MetaChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.dmSans(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
