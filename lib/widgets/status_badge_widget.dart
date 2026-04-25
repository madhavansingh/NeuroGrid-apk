import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

enum StatusLevel { heavy, moderate, clear, warning, info, success, error }

class StatusBadgeWidget extends StatelessWidget {
  final String label;
  final StatusLevel level;
  final bool compact;

  const StatusBadgeWidget({
    super.key,
    required this.label,
    required this.level,
    this.compact = false,
  });

  Color get _bgColor {
    switch (level) {
      case StatusLevel.heavy:
      case StatusLevel.error:
        return AppTheme.trafficHeavyLight;
      case StatusLevel.moderate:
      case StatusLevel.warning:
        return AppTheme.trafficModerateLight;
      case StatusLevel.clear:
      case StatusLevel.success:
        return AppTheme.trafficClearLight;
      case StatusLevel.info:
        return AppTheme.primaryLight;
    }
  }

  Color get _textColor {
    switch (level) {
      case StatusLevel.heavy:
      case StatusLevel.error:
        return AppTheme.trafficHeavy;
      case StatusLevel.moderate:
      case StatusLevel.warning:
        return AppTheme.trafficModerate;
      case StatusLevel.clear:
      case StatusLevel.success:
        return AppTheme.trafficClear;
      case StatusLevel.info:
        return AppTheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: _bgColor,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        label,
        style: GoogleFonts.dmSans(
          fontSize: compact ? 10 : 11,
          fontWeight: FontWeight.w600,
          color: _textColor,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
