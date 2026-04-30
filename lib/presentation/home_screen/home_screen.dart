import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/app_export.dart';
import '../../providers/location_provider.dart';
import '../../providers/server_status_provider.dart';
import '../../routes/app_routes.dart';
import '../../widgets/server_wake_banner.dart';

import './widgets/home_header_widget.dart';
import './widgets/leave_now_card_widget.dart';
import './widgets/quick_insights_widget.dart';
import './widgets/city_services_grid_widget.dart';
import './widgets/city_alerts_feed_widget.dart';
import './widgets/weather_hero_card.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with TickerProviderStateMixin {
  int _navIndex = 0;
  bool _refreshing = false;
  late AnimationController _entranceCtrl;
  late List<Animation<double>> _sectionAnims;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));
    _entranceCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _sectionAnims = List.generate(
      7,
      (i) => CurvedAnimation(
        parent: _entranceCtrl,
        curve:
            Interval(i * 0.09, 0.55 + i * 0.07, curve: Curves.easeOutCubic),
      ),
    );
    _entranceCtrl.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Server wake check
      ref.read(serverStatusProvider);
      // Kick off GPS so weather card gets real coordinates
      final loc = ref.read(locationProvider);
      if (!loc.hasLocation && !loc.loading) {
        ref.read(locationProvider.notifier).fetchLocation();
      }
    });
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    setState(() => _refreshing = true);
    HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 1600));
    if (mounted) setState(() => _refreshing = false);
  }

  Widget _animated(int idx, Widget child) {
    return FadeTransition(
      opacity: _sectionAnims[idx],
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
            .animate(_sectionAnims[idx]),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      extendBody: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFEEF2FF), Color(0xFFF8FAFF), Color(0xFFF4F7FF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: [0.0, 0.4, 1.0],
          ),
        ),
        child: RefreshIndicator(
        onRefresh: _handleRefresh,
        color: const Color(0xFF1A6BF5),
        backgroundColor: Colors.white,
        displacement: 60,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics()),
          slivers: [
            // ── Render cold-start banner ──────────────────────────────────
            const SliverToBoxAdapter(child: ServerWakeBanner()),

            // ── Refreshing banner ─────────────────────────────────────────
            if (_refreshing)
              SliverToBoxAdapter(
                child: _RefreshBanner(),
              ),

            // ── Header ────────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: _animated(0, const HomeHeaderWidget()),
            ),

            // ── Hero: Should you leave now? ───────────────────────────────
            SliverToBoxAdapter(
              child: _animated(
                1,
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 4, 20, 0),
                  child: LeaveNowCardWidget(),
                ),
              ),
            ),

            // ── Quick insights row ────────────────────────────────────────
            SliverToBoxAdapter(
              child: _animated(
                2,
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 24, 20, 0),
                  child: QuickInsightsWidget(),
                ),
              ),
            ),

            // ── Weather section label ──────────────────────────────────────
            SliverToBoxAdapter(
              child: _animated(
                3,
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 24, 20, 10),
                  child: _SectionLabel(
                      title: 'Current Weather',
                      subtitle: 'Bhopal · Real-time'),
                ),
              ),
            ),

            // ── Weather hero card ─────────────────────────────────────────
            SliverToBoxAdapter(
              child: _animated(
                3,
                const Padding(
                  padding: EdgeInsets.fromLTRB(0, 0, 0, 0),
                  child: WeatherHeroCard(),
                ),
              ),
            ),

            // ── Smart actions grid ────────────────────────────────────────
            SliverToBoxAdapter(
              child: _animated(
                4,
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 28, 20, 0),
                  child: CityServicesGridWidget(),
                ),
              ),
            ),

            // ── Live city feed ────────────────────────────────────────────
            SliverToBoxAdapter(
              child: _animated(
                5,
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 28, 20, 0),
                  child: CityAlertsFeedWidget(),
                ),
              ),
            ),

            // ── Emergency banner ──────────────────────────────────────────
            SliverToBoxAdapter(
              child: _animated(
                6,
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                  child: _EmergencyBanner(),
                ),
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 120)),
          ],
        ),
      ),
      ),
      bottomNavigationBar: AppNavigation(
        currentIndex: _navIndex,
        onTap: (i) {
          setState(() => _navIndex = i);
          // 0=Home (stay), 1=Map, 2=Issues, 3=AI, 4=Profile
          if (i == 1) Navigator.pushNamed(context, AppRoutes.mapScreen);
          if (i == 2) Navigator.pushNamed(context, AppRoutes.civicIssuesScreen);
          if (i == 3) Navigator.pushNamed(context, AppRoutes.aiAssistantScreen);
          if (i == 4) Navigator.pushNamed(context, AppRoutes.profileScreen);
        },
      ),
    );
  }
}


// ── Refresh banner ─────────────────────────────────────────────────────────────

class _RefreshBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1A6BF5),
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 14, height: 14,
            child: CircularProgressIndicator(
                strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)),
          ),
          const SizedBox(width: 10),
          Text('Updating city data…',
              style: GoogleFonts.dmSans(
                  fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
        ],
      ),
    );
  }
}

// ── Emergency banner ────────────────────────────────────────────────────────────

class _EmergencyBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, AppRoutes.emergencyScreen),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFF3B30), Color(0xFFFF6B6B)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: const Color(0xFFFF3B30).withAlpha(60),
                blurRadius: 20,
                offset: const Offset(0, 8)),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                  color: Colors.white.withAlpha(30),
                  borderRadius: BorderRadius.circular(14)),
              child: const Icon(Icons.emergency_rounded, size: 22,
                  color: Colors.white),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Emergency Mode',
                      style: GoogleFonts.dmSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white)),
                  Text('Tap to activate emergency services',
                      style: GoogleFonts.dmSans(
                          fontSize: 13, color: Colors.white70)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: Colors.white70, size: 22),
          ],
        ),
      ),
    );
  }
}

// ── Section label ───────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String title;
  final String subtitle;
  const _SectionLabel({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: GoogleFonts.dmSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F172A))),
            const SizedBox(height: 2),
            Text(subtitle,
                style: GoogleFonts.dmSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF64748B))),
          ],
        ),
      ],
    );
  }
}
