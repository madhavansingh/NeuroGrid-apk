import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../routes/app_routes.dart';
import '../../widgets/app_navigation.dart';

class WastePickupScreen extends StatefulWidget {
  const WastePickupScreen({super.key});
  @override
  State<WastePickupScreen> createState() => _WastePickupScreenState();
}

class _WastePickupScreenState extends State<WastePickupScreen>
    with TickerProviderStateMixin {
  int _navIndex = 0;
  late AnimationController _enter;
  late AnimationController _pulseCtrl;
  late Animation<double> _pulse;
  late List<Animation<double>> _anims;

  // Simulated live data — would come from backend in production
  final double _binLevel = 0.72;
  final List<_RecentEvent> _events = [
    _RecentEvent('Pickup completed', 'Zone A · Patel Nagar', '2 hrs ago', Icons.check_circle_rounded, Color(0xFF16A34A), Color(0xFFDCFCE7)),
    _RecentEvent('Truck entered your area', 'Vehicle #BHP-34', '5 hrs ago', Icons.local_shipping_rounded, Color(0xFF1A6BF5), Color(0xFFEFF6FF)),
    _RecentEvent('Bin 75% full alert', 'Sensor threshold reached', '8 hrs ago', Icons.warning_amber_rounded, Color(0xFFD97706), Color(0xFFFEF3C7)),
    _RecentEvent('Route updated', 'Diverted via Roshanpura', 'Yesterday', Icons.route_rounded, Color(0xFF7C3AED), Color(0xFFF5F3FF)),
  ];

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent, statusBarIconBrightness: Brightness.dark));
    _enter = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.85, end: 1.0).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _anims = List.generate(6, (i) => CurvedAnimation(
      parent: _enter, curve: Interval(i * 0.1, 0.6 + i * 0.07, curve: Curves.easeOutCubic)));
    _enter.forward();
  }

  @override
  void dispose() { _enter.dispose(); _pulseCtrl.dispose(); super.dispose(); }

  Widget _animated(int idx, Widget child) => FadeTransition(opacity: _anims[idx],
    child: SlideTransition(position: Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero).animate(_anims[idx]), child: child));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      extendBody: true,
      body: SafeArea(bottom: false, child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(child: _animated(0, _buildHeader())),
          SliverToBoxAdapter(child: _animated(1, _buildNextPickupCard())),
          SliverToBoxAdapter(child: _animated(2, _buildBinStatusCard())),
          SliverToBoxAdapter(child: _animated(3, _buildQuickStats())),
          SliverToBoxAdapter(child: _animated(4, _buildRecentUpdates())),
          SliverToBoxAdapter(child: _animated(5, _buildReportCTA())),
          const SliverToBoxAdapter(child: SizedBox(height: 110)),
        ],
      )),
      bottomNavigationBar: AppNavigation(currentIndex: _navIndex, onTap: (i) {
        setState(() => _navIndex = i);
        if (i == 0) Navigator.pushNamed(context, '/home-screen');
        if (i == 1) Navigator.pushNamed(context, '/3d-map-screen');
        if (i == 2) Navigator.pushNamed(context, '/traffic-screen');
        if (i == 3) Navigator.pushNamed(context, '/ai-assistant-screen');
        if (i == 4) Navigator.pushNamed(context, '/profile-screen');
      }),
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────────

  Widget _buildHeader() => Padding(
    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
    child: Row(children: [
      GestureDetector(onTap: () => Navigator.pop(context),
        child: Container(width: 40, height: 40,
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 10, offset: const Offset(0, 3))]),
          child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: Color(0xFF0F172A)))),
      const SizedBox(width: 14),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Waste Management', style: GoogleFonts.dmSans(fontSize: 19, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A), letterSpacing: -0.3)),
        Text('Patel Nagar · Zone A', style: GoogleFonts.dmSans(fontSize: 12, color: const Color(0xFF64748B))),
      ])),
      ScaleTransition(scale: _pulse, child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(20)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 6, height: 6, decoration: const BoxDecoration(color: Color(0xFF16A34A), shape: BoxShape.circle)),
          const SizedBox(width: 5),
          Text('Live', style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF16A34A))),
        ]),
      )),
    ]),
  );

  // ── Next pickup card ────────────────────────────────────────────────────────

  Widget _buildNextPickupCard() => Container(
    margin: const EdgeInsets.fromLTRB(20, 8, 20, 0),
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
        colors: [Color(0xFF1A6BF5), Color(0xFF2563EB)]),
      borderRadius: BorderRadius.circular(20),
      boxShadow: [BoxShadow(color: const Color(0xFF1A6BF5).withAlpha(80), blurRadius: 20, offset: const Offset(0, 8))],
    ),
    child: Row(children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.schedule_rounded, size: 14, color: Colors.white70),
          const SizedBox(width: 5),
          Text('Next Pickup', style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.white70)),
        ]),
        const SizedBox(height: 8),
        Text('Tomorrow • 8:00 AM', style: GoogleFonts.dmSans(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.4)),
        const SizedBox(height: 6),
        Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(color: Colors.white.withAlpha(30), borderRadius: BorderRadius.circular(20)),
          child: Text('Truck arriving in your area', style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.white))),
      ])),
      Container(width: 64, height: 64, decoration: BoxDecoration(color: Colors.white.withAlpha(25), borderRadius: BorderRadius.circular(18)),
        child: const Icon(Icons.local_shipping_rounded, size: 32, color: Colors.white)),
    ]),
  );

  // ── Bin status card ─────────────────────────────────────────────────────────

  Widget _buildBinStatusCard() {
    final pct = (_binLevel * 100).toInt();
    final barColor = _binLevel < 0.5 ? const Color(0xFF16A34A)
        : _binLevel < 0.8 ? const Color(0xFFD97706)
        : const Color(0xFFDC2626);
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 12, offset: const Offset(0, 4))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 40, height: 40, decoration: BoxDecoration(color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.delete_rounded, size: 20, color: Color(0xFFD97706))),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Bin Status', style: GoogleFonts.dmSans(fontSize: 15, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A))),
            Text('Residential bin · Smart sensor', style: GoogleFonts.dmSans(fontSize: 12, color: const Color(0xFF64748B))),
          ])),
          Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(color: barColor.withAlpha(20), borderRadius: BorderRadius.circular(20)),
            child: Text('$pct% Full', style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w700, color: barColor))),
        ]),
        const SizedBox(height: 16),
        ClipRRect(borderRadius: BorderRadius.circular(8), child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: _binLevel), duration: const Duration(milliseconds: 1200), curve: Curves.easeOutCubic,
          builder: (_, v, __) => LinearProgressIndicator(value: v, minHeight: 10,
            backgroundColor: const Color(0xFFF1F5F9), color: barColor),
        )),
        const SizedBox(height: 10),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('0%', style: GoogleFonts.dmSans(fontSize: 11, color: const Color(0xFF94A3B8))),
          Text('Estimated full in ~2 days', style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w500, color: const Color(0xFF64748B))),
          Text('100%', style: GoogleFonts.dmSans(fontSize: 11, color: const Color(0xFF94A3B8))),
        ]),
      ]),
    );
  }

  // ── Quick stats row ─────────────────────────────────────────────────────────

  Widget _buildQuickStats() => Padding(
    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
    child: Row(children: [
      _StatCard('On Schedule', Icons.check_circle_rounded, const Color(0xFF16A34A), const Color(0xFFDCFCE7)),
      const SizedBox(width: 10),
      _StatCard('Truck Active', Icons.local_shipping_outlined, const Color(0xFF1A6BF5), const Color(0xFFEFF6FF)),
      const SizedBox(width: 10),
      _StatCard('3 Issues Open', Icons.report_problem_outlined, const Color(0xFFD97706), const Color(0xFFFEF3C7)),
    ]),
  );

  // ── Recent updates ──────────────────────────────────────────────────────────

  Widget _buildRecentUpdates() => Padding(
    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text('Recent Updates', style: GoogleFonts.dmSans(fontSize: 15, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A))),
        GestureDetector(
          onTap: () => Navigator.pushNamed(context, AppRoutes.civicIssuesScreen),
          child: Text('View all', style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF1A6BF5))),
        ),
      ]),
      const SizedBox(height: 12),
      Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 12, offset: const Offset(0, 4))]),
        child: Column(children: List.generate(_events.length, (i) {
          final e = _events[i];
          return Column(children: [
            Padding(padding: const EdgeInsets.fromLTRB(16, 14, 16, 14), child: Row(children: [
              Container(width: 38, height: 38, decoration: BoxDecoration(color: e.bg, borderRadius: BorderRadius.circular(10)),
                child: Icon(e.icon, size: 18, color: e.color)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(e.title, style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF0F172A))),
                const SizedBox(height: 2),
                Text(e.subtitle, style: GoogleFonts.dmSans(fontSize: 11, color: const Color(0xFF64748B))),
              ])),
              Text(e.time, style: GoogleFonts.dmSans(fontSize: 11, color: const Color(0xFF94A3B8))),
            ])),
            if (i < _events.length - 1) const Divider(height: 1, indent: 66, color: Color(0xFFF1F5F9)),
          ]);
        })),
      ),
    ]),
  );

  // ── Report waste CTA ────────────────────────────────────────────────────────

  Widget _buildReportCTA() => Padding(
    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
    child: GestureDetector(
      onTap: () => Navigator.pushNamed(context, AppRoutes.reportIssueScreen),
      child: Container(
        width: double.infinity, padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Row(children: [
          Container(width: 52, height: 52,
            decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(14),
              boxShadow: [BoxShadow(color: const Color(0xFFDC2626).withAlpha(40), blurRadius: 12, offset: const Offset(0, 4))]),
            child: const Icon(Icons.report_problem_rounded, size: 26, color: Color(0xFFDC2626))),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Report Waste Issue', style: GoogleFonts.dmSans(fontSize: 15, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A))),
            const SizedBox(height: 3),
            Text('Garbage overflow, missed pickup\nor illegal dumping', style: GoogleFonts.dmSans(fontSize: 12, color: const Color(0xFF64748B), height: 1.4)),
          ])),
          Container(width: 36, height: 36, decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.arrow_forward_ios_rounded, size: 15, color: Color(0xFF1A6BF5))),
        ]),
      ),
    ),
  );
}

// ── Stat card helper ────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String label; final IconData icon; final Color color; final Color bg;
  const _StatCard(this.label, this.icon, this.color, this.bg);
  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 8, offset: const Offset(0, 3))]),
      child: Column(children: [
        Container(width: 34, height: 34, decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, size: 16, color: color)),
        const SizedBox(height: 6),
        Text(label, textAlign: TextAlign.center, style: GoogleFonts.dmSans(fontSize: 10, fontWeight: FontWeight.w600, color: const Color(0xFF0F172A))),
      ]),
    ),
  );
}

// ── Event data model ────────────────────────────────────────────────────────

class _RecentEvent {
  final String title, subtitle, time; final IconData icon; final Color color, bg;
  const _RecentEvent(this.title, this.subtitle, this.time, this.icon, this.color, this.bg);
}
