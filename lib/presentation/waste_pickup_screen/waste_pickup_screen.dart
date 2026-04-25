import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/app_export.dart';
import './widgets/arrival_alerts_widget.dart';
import './widgets/bin_fullness_widget.dart';
import './widgets/pickup_countdown_widget.dart';

class WastePickupScreen extends StatefulWidget {
  const WastePickupScreen({super.key});

  @override
  State<WastePickupScreen> createState() => _WastePickupScreenState();
}

class _WastePickupScreenState extends State<WastePickupScreen>
    with TickerProviderStateMixin {
  int _navIndex = 0;
  late AnimationController _entranceController;
  late List<Animation<double>> _sectionAnimations;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _sectionAnimations = List.generate(
      5,
      (i) => CurvedAnimation(
        parent: _entranceController,
        curve: Interval(i * 0.12, 0.6 + i * 0.08, curve: Curves.easeOutCubic),
      ),
    );
    _entranceController.forward();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      extendBody: true,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: FadeTransition(
                opacity: _sectionAnimations[0],
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.04),
                    end: Offset.zero,
                  ).animate(_sectionAnimations[0]),
                  child: _buildHeader(context),
                ),
              ),
            ),
            // Status summary bar
            SliverToBoxAdapter(
              child: FadeTransition(
                opacity: _sectionAnimations[0],
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildStatusBar(),
                ),
              ),
            ),
            // Pickup countdown card
            SliverToBoxAdapter(
              child: FadeTransition(
                opacity: _sectionAnimations[1],
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.05),
                    end: Offset.zero,
                  ).animate(_sectionAnimations[1]),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: PickupCountdownWidget(),
                  ),
                ),
              ),
            ),
            // Bin fullness tracker
            SliverToBoxAdapter(
              child: FadeTransition(
                opacity: _sectionAnimations[2],
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.05),
                    end: Offset.zero,
                  ).animate(_sectionAnimations[2]),
                  child: const Padding(
                    padding: EdgeInsets.only(top: 16, left: 20, right: 20),
                    child: BinFullnessWidget(),
                  ),
                ),
              ),
            ),
            // Pickup schedule strip
            SliverToBoxAdapter(
              child: FadeTransition(
                opacity: _sectionAnimations[3],
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.05),
                    end: Offset.zero,
                  ).animate(_sectionAnimations[3]),
                  child: Padding(
                    padding: const EdgeInsets.only(
                      top: 16,
                      left: 20,
                      right: 20,
                    ),
                    child: _buildScheduleStrip(),
                  ),
                ),
              ),
            ),
            // Arrival alerts
            SliverToBoxAdapter(
              child: FadeTransition(
                opacity: _sectionAnimations[4],
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.05),
                    end: Offset.zero,
                  ).animate(_sectionAnimations[4]),
                  child: const Padding(
                    padding: EdgeInsets.only(top: 24, left: 20, right: 20),
                    child: ArrivalAlertsWidget(),
                  ),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 110)),
          ],
        ),
      ),
      bottomNavigationBar: AppNavigation(
        currentIndex: _navIndex,
        onTap: (i) {
          setState(() => _navIndex = i);
          if (i == 0) Navigator.pushNamed(context, '/home-screen');
          if (i == 1) Navigator.pushNamed(context, '/3d-map-screen');
          if (i == 2) Navigator.pushNamed(context, '/traffic-screen');
          if (i == 3) Navigator.pushNamed(context, '/ai-assistant-screen');
          if (i == 4) Navigator.pushNamed(context, '/profile-screen');
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(10),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 16,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Waste Pickup',
                style: GoogleFonts.dmSans(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
              Text(
                'MP Nagar · Zone A',
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: AppTheme.textMuted,
                ),
              ),
            ],
          ),
          const Spacer(),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.warningLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.notifications_outlined,
              size: 18,
              color: AppTheme.warning,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBar() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          _StatusChip(
            icon: Icons.check_circle_rounded,
            label: 'On Schedule',
            color: AppTheme.success,
            bg: AppTheme.successLight,
          ),
          const SizedBox(width: 8),
          _StatusChip(
            icon: Icons.local_shipping_outlined,
            label: 'Truck Active',
            color: AppTheme.primary,
            bg: AppTheme.primaryLight,
          ),
          const SizedBox(width: 8),
          _StatusChip(
            icon: Icons.warning_amber_rounded,
            label: '75% Full',
            color: AppTheme.warning,
            bg: AppTheme.warningLight,
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleStrip() {
    final days = [
      {'day': 'Mon', 'date': '28', 'type': 'Mixed', 'active': false},
      {'day': 'Tue', 'date': '29', 'type': 'Next', 'active': true},
      {'day': 'Wed', 'date': '30', 'type': 'Recycle', 'active': false},
      {'day': 'Thu', 'date': '1', 'type': 'Skip', 'active': false},
      {'day': 'Fri', 'date': '2', 'type': 'Mixed', 'active': false},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Weekly Schedule',
          style: GoogleFonts.dmSans(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: days.map((d) {
            final isActive = d['active'] as bool;
            final isSkip = d['type'] == 'Skip';
            return Expanded(
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isActive ? AppTheme.primary : AppTheme.surface,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: isActive
                          ? AppTheme.primary.withAlpha(60)
                          : Colors.black.withAlpha(8),
                      blurRadius: isActive ? 12 : 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      d['day'] as String,
                      style: GoogleFonts.dmSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: isActive
                            ? Colors.white.withAlpha(200)
                            : AppTheme.textMuted,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      d['date'] as String,
                      style: GoogleFonts.dmSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: isActive ? Colors.white : AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      d['type'] as String,
                      style: GoogleFonts.dmSans(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: isActive
                            ? Colors.white.withAlpha(200)
                            : isSkip
                            ? AppTheme.textMuted
                            : AppTheme.primary,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color bg;

  const _StatusChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.bg,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 7),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                style: GoogleFonts.dmSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
