import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';

class TrafficTrendChartWidget extends StatefulWidget {
  const TrafficTrendChartWidget({super.key});

  @override
  State<TrafficTrendChartWidget> createState() =>
      _TrafficTrendChartWidgetState();
}

class _TrafficTrendChartWidgetState extends State<TrafficTrendChartWidget>
    with SingleTickerProviderStateMixin {
  // TODO: Replace with Riverpod/Bloc for production
  late AnimationController _chartController;
  late Animation<double> _chartAnimation;

  // Realistic Bhopal traffic density — hourly, 6AM to 8PM
  // Values: 0–100 congestion index
  static const List<double> _hourlyDensity = [
    18, // 6 AM — early commuters
    42, // 7 AM — school traffic starts
    78, // 8 AM — peak morning rush
    88, // 9 AM — peak (current hour)
    71, // 10 AM — tapering
    52, // 11 AM — moderate midday
    48, // 12 PM — lunch hour
    55, // 1 PM — post-lunch spike
    44, // 2 PM — quiet afternoon
    38, // 3 PM — low
    62, // 4 PM — school dismissal
    82, // 5 PM — evening rush starts
    90, // 6 PM — peak evening
    76, // 7 PM — tapering
    54, // 8 PM — evening wind-down
  ];

  static const List<String> _hourLabels = [
    '6A',
    '7A',
    '8A',
    '9A',
    '10A',
    '11A',
    '12P',
    '1P',
    '2P',
    '3P',
    '4P',
    '5P',
    '6P',
    '7P',
    '8P',
  ];

  // Current hour index (9 AM = index 3)
  static const int _currentHourIndex = 3;

  @override
  void initState() {
    super.initState();
    _chartController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _chartAnimation = CurvedAnimation(
      parent: _chartController,
      curve: Curves.easeOutCubic,
    );
    _chartController.forward();
  }

  @override
  void dispose() {
    _chartController.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 14,
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
                'Today\'s Traffic Density',
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.trafficHeavyLight,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  'Peak now',
                  style: GoogleFonts.dmSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.trafficHeavy,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Congestion index · Bhopal City · Apr 25',
            style: GoogleFonts.dmSans(fontSize: 11, color: AppTheme.textMuted),
          ),
          const SizedBox(height: 20),
          AnimatedBuilder(
            animation: _chartAnimation,
            builder: (context, _) {
              return SizedBox(
                height: 180,
                child: LineChart(
                  LineChartData(
                    minX: 0,
                    maxX: (_hourlyDensity.length - 1).toDouble(),
                    minY: 0,
                    maxY: 110,
                    clipData: const FlClipData.all(),
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: 25,
                      getDrawingHorizontalLine: (_) => FlLine(
                        color: AppTheme.outlineVariant,
                        strokeWidth: 1,
                        dashArray: [4, 4],
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    titlesData: FlTitlesData(
                      leftTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: 2,
                          reservedSize: 24,
                          getTitlesWidget: (value, meta) {
                            final index = value.toInt();
                            if (index < 0 ||
                                index >= _hourLabels.length ||
                                index % 2 != 0) {
                              return const SizedBox.shrink();
                            }
                            return Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                _hourLabels[index],
                                style: GoogleFonts.dmSans(
                                  fontSize: 10,
                                  fontWeight: index == _currentHourIndex
                                      ? FontWeight.w700
                                      : FontWeight.w400,
                                  color: index == _currentHourIndex
                                      ? AppTheme.primary
                                      : AppTheme.textMuted,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    lineTouchData: LineTouchData(
                      touchTooltipData: LineTouchTooltipData(
                        getTooltipColor: (_) => AppTheme.textPrimary,
                        tooltipPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        getTooltipItems: (touchedSpots) {
                          return touchedSpots.map((spot) {
                            final hour = _hourLabels[spot.x.toInt()];
                            final density = spot.y.toInt();
                            String level;
                            if (density >= 70) {
                              level = 'Heavy';
                            } else if (density >= 45) {
                              level = 'Moderate';
                            } else {
                              level = 'Clear';
                            }
                            return LineTooltipItem(
                              '$hour  •  $level\n',
                              GoogleFonts.dmSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: Colors.white.withAlpha(191),
                              ),
                              children: [
                                TextSpan(
                                  text: 'Index: $density',
                                  style: GoogleFonts.dmSans(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            );
                          }).toList();
                        },
                      ),
                    ),
                    lineBarsData: [
                      // Future hours — dashed gray
                      LineChartBarData(
                        spots: List.generate(
                          _hourlyDensity.length - _currentHourIndex,
                          (i) => FlSpot(
                            (_currentHourIndex + i).toDouble(),
                            _hourlyDensity[_currentHourIndex + i],
                          ),
                        ),
                        isCurved: true,
                        curveSmoothness: 0.3,
                        color: AppTheme.textMuted.withAlpha(102),
                        barWidth: 2,
                        isStrokeCapRound: true,
                        dotData: const FlDotData(show: false),
                        dashArray: [5, 5],
                        belowBarData: BarAreaData(show: false),
                      ),
                      // Past + current hours — colored line
                      LineChartBarData(
                        spots: List.generate(
                          _currentHourIndex + 1,
                          (i) => FlSpot(
                            i.toDouble(),
                            _hourlyDensity[i] * _chartAnimation.value,
                          ),
                        ),
                        isCurved: true,
                        curveSmoothness: 0.35,
                        gradient: const LinearGradient(
                          colors: [AppTheme.primary, AppTheme.trafficHeavy],
                        ),
                        barWidth: 2.5,
                        isStrokeCapRound: true,
                        dotData: FlDotData(
                          show: true,
                          checkToShowDot: (spot, barData) =>
                              spot.x == _currentHourIndex.toDouble(),
                          getDotPainter: (spot, percent, barData, index) =>
                              FlDotCirclePainter(
                                radius: 5,
                                color: AppTheme.trafficHeavy,
                                strokeWidth: 2.5,
                                strokeColor: Colors.white,
                              ),
                        ),
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            colors: [
                              AppTheme.primary.withAlpha(46),
                              AppTheme.primary.withAlpha(0),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          // Legend row
          Row(
            children: [
              _ChartLegend(
                color: AppTheme.primary,
                label: 'Past hours',
                isDashed: false,
              ),
              const SizedBox(width: 16),
              _ChartLegend(
                color: AppTheme.textMuted,
                label: 'Forecast',
                isDashed: true,
              ),
              const Spacer(),
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: AppTheme.trafficHeavy,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 5),
              Text(
                'Now (9 AM)',
                style: GoogleFonts.dmSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.trafficHeavy,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChartLegend extends StatelessWidget {
  final Color color;
  final String label;
  final bool isDashed;

  const _ChartLegend({
    required this.color,
    required this.label,
    required this.isDashed,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 20,
          height: 2,
          child: isDashed
              ? Row(
                  children: [
                    Container(width: 6, height: 2, color: color),
                    const SizedBox(width: 2),
                    Container(width: 6, height: 2, color: color),
                  ],
                )
              : Container(color: color),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 11,
            fontWeight: FontWeight.w400,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }
}
