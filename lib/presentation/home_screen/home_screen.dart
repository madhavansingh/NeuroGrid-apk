import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/app_export.dart';
import '../../routes/app_routes.dart';
import './widgets/city_services_grid_widget.dart';
import './widgets/home_header_widget.dart';
import './widgets/leave_now_card_widget.dart';
import './widgets/quick_insights_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
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
      duration: const Duration(milliseconds: 1000),
    );
    _sectionAnimations = List.generate(
      5,
      (i) => CurvedAnimation(
        parent: _entranceController,
        curve: Interval(i * 0.12, 0.65 + i * 0.07, curve: Curves.easeOutCubic),
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
            // Header: greeting + location
            SliverToBoxAdapter(
              child: FadeTransition(
                opacity: _sectionAnimations[0],
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.04),
                    end: Offset.zero,
                  ).animate(_sectionAnimations[0]),
                  child: const HomeHeaderWidget(),
                ),
              ),
            ),
            // Hero card: Should you leave now?
            SliverToBoxAdapter(
              child: FadeTransition(
                opacity: _sectionAnimations[1],
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.06),
                    end: Offset.zero,
                  ).animate(_sectionAnimations[1]),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: LeaveNowCardWidget(),
                  ),
                ),
              ),
            ),
            // 3 insight cards: Traffic, Weather, Alerts
            SliverToBoxAdapter(
              child: FadeTransition(
                opacity: _sectionAnimations[2],
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.05),
                    end: Offset.zero,
                  ).animate(_sectionAnimations[2]),
                  child: const Padding(
                    padding: EdgeInsets.only(top: 28, left: 20, right: 20),
                    child: QuickInsightsWidget(),
                  ),
                ),
              ),
            ),
            // Quick actions grid (4 max)
            SliverToBoxAdapter(
              child: FadeTransition(
                opacity: _sectionAnimations[3],
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.05),
                    end: Offset.zero,
                  ).animate(_sectionAnimations[3]),
                  child: const Padding(
                    padding: EdgeInsets.only(top: 28, left: 20, right: 20),
                    child: CityServicesGridWidget(),
                  ),
                ),
              ),
            ),
            // Emergency mode banner
            SliverToBoxAdapter(
              child: FadeTransition(
                opacity: _sectionAnimations[4],
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.05),
                    end: Offset.zero,
                  ).animate(_sectionAnimations[4]),
                  child: Padding(
                    padding: const EdgeInsets.only(
                      top: 28,
                      left: 20,
                      right: 20,
                    ),
                    child: _EmergencyBanner(),
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
          if (i == 1) Navigator.pushNamed(context, AppRoutes.mapScreen);
          if (i == 2) Navigator.pushNamed(context, AppRoutes.trafficScreen);
          if (i == 3) Navigator.pushNamed(context, AppRoutes.aiAssistantScreen);
          if (i == 4) Navigator.pushNamed(context, AppRoutes.profileScreen);
        },
      ),
    );
  }
}

class _EmergencyBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, AppRoutes.emergencyScreen),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: AppTheme.errorLight,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.error.withAlpha(60), width: 1),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.error,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.emergency_rounded,
                size: 20,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Emergency Mode',
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.error,
                    ),
                  ),
                  Text(
                    'Tap to activate emergency services',
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: AppTheme.error.withAlpha(180),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: AppTheme.error, size: 20),
          ],
        ),
      ),
    );
  }
}
