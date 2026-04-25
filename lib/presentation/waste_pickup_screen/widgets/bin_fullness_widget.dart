import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';

class BinFullnessWidget extends StatefulWidget {
  const BinFullnessWidget({super.key});

  @override
  State<BinFullnessWidget> createState() => _BinFullnessWidgetState();
}

class _BinFullnessWidgetState extends State<BinFullnessWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fillAnimation;

  // 75% full
  static const double _fillLevel = 0.75;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _fillAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color get _fillColor {
    if (_fillLevel >= 0.85) return AppTheme.error;
    if (_fillLevel >= 0.60) return AppTheme.warning;
    return AppTheme.trafficClear;
  }

  Color get _fillColorLight {
    if (_fillLevel >= 0.85) return AppTheme.errorLight;
    if (_fillLevel >= 0.60) return AppTheme.warningLight;
    return AppTheme.trafficClearLight;
  }

  String get _statusLabel {
    if (_fillLevel >= 0.85) return 'Almost Full';
    if (_fillLevel >= 0.60) return 'Filling Up';
    return 'Good';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(12),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _fillColorLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.delete_outline_rounded,
                  size: 18,
                  color: _fillColor,
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bin Fullness',
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  Text(
                    'Household · Zone A',
                    style: GoogleFonts.dmSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _fillColorLight,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  _statusLabel,
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _fillColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              // Arc gauge
              SizedBox(
                width: 110,
                height: 80,
                child: AnimatedBuilder(
                  animation: _fillAnimation,
                  builder: (_, __) => CustomPaint(
                    painter: _ArcGaugePainter(
                      progress: _fillAnimation.value * _fillLevel,
                      fillColor: _fillColor,
                    ),
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${(_fillAnimation.value * _fillLevel * 100).toInt()}%',
                              style: GoogleFonts.dmSans(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: _fillColor,
                                letterSpacing: -0.5,
                              ),
                            ),
                            Text(
                              'full',
                              style: GoogleFonts.dmSans(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              // Bin segments visual
              Expanded(
                child: AnimatedBuilder(
                  animation: _fillAnimation,
                  builder: (_, __) => _BinSegments(
                    fillLevel: _fillAnimation.value * _fillLevel,
                    fillColor: _fillColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Capacity bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Capacity used',
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  Text(
                    '37.5L / 50L',
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(100),
                child: AnimatedBuilder(
                  animation: _fillAnimation,
                  builder: (_, __) => LinearProgressIndicator(
                    value: _fillAnimation.value * _fillLevel,
                    minHeight: 6,
                    backgroundColor: AppTheme.outlineVariant,
                    valueColor: AlwaysStoppedAnimation<Color>(_fillColor),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ArcGaugePainter extends CustomPainter {
  final double progress;
  final Color fillColor;

  _ArcGaugePainter({required this.progress, required this.fillColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height - 4);
    final radius = size.width / 2 - 8;
    const startAngle = math.pi;
    const sweepAngle = math.pi;

    // Background arc
    final bgPaint = Paint()
      ..color = AppTheme.outlineVariant
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      bgPaint,
    );

    // Fill arc
    final fillPaint = Paint()
      ..color = fillColor
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle * progress,
      false,
      fillPaint,
    );
  }

  @override
  bool shouldRepaint(_ArcGaugePainter old) =>
      old.progress != progress || old.fillColor != fillColor;
}

class _BinSegments extends StatelessWidget {
  final double fillLevel;
  final Color fillColor;

  const _BinSegments({required this.fillLevel, required this.fillColor});

  @override
  Widget build(BuildContext context) {
    const segments = 5;
    final filledCount = (fillLevel * segments).ceil();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Bin Level',
          style: GoogleFonts.dmSans(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: AppTheme.textMuted,
          ),
        ),
        const SizedBox(height: 8),
        Column(
          children: List.generate(segments, (i) {
            final segIndex = segments - 1 - i;
            final isFilled = segIndex < filledCount;
            return Container(
              margin: const EdgeInsets.only(bottom: 4),
              height: 10,
              decoration: BoxDecoration(
                color: isFilled
                    ? fillColor.withAlpha(
                        ((segIndex / segments) * 180 + 75).toInt(),
                      )
                    : AppTheme.outlineVariant,
                borderRadius: BorderRadius.circular(4),
              ),
            );
          }),
        ),
      ],
    );
  }
}
