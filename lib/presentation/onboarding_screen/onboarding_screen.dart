import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sizer/sizer.dart';
import '../../providers/user_session_provider.dart';
import '../../routes/app_routes.dart';
import '../../services/auth_service.dart';
import 'onboarding_painters.dart';

// ── Intro page data ───────────────────────────────────────────────────────────
class _IntroPage {
  final String title, sub;
  final Color bg, accent;
  final Widget Function(double t) illustration;
  const _IntroPage(this.title, this.sub, this.bg, this.accent, this.illustration);
}

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});
  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen>
    with TickerProviderStateMixin {

  // ── Phase A: intro (3 swipeable pages) ──────────────────────────────────────
  final _introCtrl = PageController();
  int _introPage = 0;
  bool _showingIntro = true;

  // ── Phase B: setup (4 non-swipeable steps) ──────────────────────────────────
  int _setupStep = 0; // 0=login 1=location 2=prefs 3=finish

  // Setup state
  bool _googleLoading = false;
  bool _googleDone = false;
  bool _locLoading = false;
  bool _locGranted = false;
  final Set<String> _selectedPrefs = {};
  bool _finishing = false;

  // Animations
  late AnimationController _illustCtrl;
  late AnimationController _fadeCtrl;

  final _prefs = [
    ['Traffic & Commute', '🚗'],
    ['Clean City', '♻️'],
    ['Parking', '🅿️'],
    ['Safety & Alerts', '🛡️'],
    ['All of the above', '⭐'],
  ];

  late final List<_IntroPage> _pages = [
    _IntroPage(
      'Your Smart City,\nSimplified',
      'Visualise city intelligence —\ntraffic, alerts, and AI in one place.',
      const Color(0xFFF0F7FF), const Color(0xFF1A6BF5),
      (t) => CustomPaint(painter: CityNetworkPainter(t), child: const SizedBox.expand()),
    ),
    _IntroPage(
      'Real-Time\nCity Insights',
      'Traffic, parking, waste, and alerts —\nalways live, always accurate.',
      const Color(0xFFF0FBFF), const Color(0xFF0EA5E9),
      (t) => CustomPaint(painter: InsightsDashPainter(t), child: const SizedBox.expand()),
    ),
    _IntroPage(
      'AI That Helps\nYou Decide',
      '"Should you leave now?"\nNeuroGrid thinks ahead so you don\'t have to.',
      const Color(0xFFF5F0FF), const Color(0xFF7C3AED),
      (t) => CustomPaint(painter: AiDecisionPainter(t), child: const SizedBox.expand()),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _illustCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat();
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _introCtrl.dispose();
    _illustCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  void _nextIntro() {
    if (_introPage < 2) {
      _introCtrl.nextPage(duration: const Duration(milliseconds: 400), curve: Curves.easeInOutCubic);
      setState(() => _introPage++);
    } else {
      setState(() => _showingIntro = false);
      _fadeCtrl.reset();
      _fadeCtrl.forward();
    }
  }

  void _nextSetup() {
    _fadeCtrl.reset();
    setState(() => _setupStep++);
    _fadeCtrl.forward();
  }

  Future<void> _doGoogleLogin() async {
    setState(() => _googleLoading = true);
    try {
      final session = await AuthService.instance.signIn();
      if (!mounted) return;
      ref.read(userSessionProvider.notifier).set(session);
      setState(() { _googleLoading = false; _googleDone = true; });
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) _nextSetup();
    } catch (e) {
      if (!mounted) return;
      setState(() => _googleLoading = false);
      final msg = e.toString();
      // User dismissed picker — don't show error
      if (msg.contains('sign_in_cancelled')) return;
      _showAuthError('Sign-in failed: $msg');
    }
  }

  Future<void> _doGuestLogin() async {
    // Creates a local guest session — no Google OAuth required
    final session = AuthService.instance.signInAsGuest();
    ref.read(userSessionProvider.notifier).set(session);
    setState(() { _googleDone = true; });
    await Future.delayed(const Duration(milliseconds: 300));
    if (mounted) _nextSetup();
  }

  void _showAuthError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.dmSans(fontSize: 13)),
      behavior: SnackBarBehavior.floating,
      backgroundColor: const Color(0xFF0F172A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      duration: const Duration(seconds: 5),
    ));
  }

  Future<void> _requestLocation() async {
    setState(() => _locLoading = true);
    final status = await Permission.location.request();
    if (!mounted) return;
    setState(() { _locLoading = false; _locGranted = status.isGranted; });
    await Future.delayed(const Duration(milliseconds: 300));
    if (mounted) _nextSetup();
  }

  Future<void> _finish() async {
    setState(() => _finishing = true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_onboarded', true);
    await prefs.setStringList('user_prefs', _selectedPrefs.toList());
    await Future.delayed(const Duration(milliseconds: 2200));
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, AppRoutes.homeScreen);
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
    if (_showingIntro) return _buildIntroPhase();
    return _buildSetupPhase();
  }

  // ── PHASE A ──────────────────────────────────────────────────────────────────
  Widget _buildIntroPhase() {
    return Scaffold(
      backgroundColor: _pages[_introPage].bg,
      body: Stack(children: [
        PageView.builder(
          controller: _introCtrl,
          onPageChanged: (i) => setState(() => _introPage = i),
          itemCount: 3,
          itemBuilder: (_, i) => _buildIntroPage(i),
        ),
        // Skip button only — dots live inside each page card
        Positioned(
          top: 0, right: 0,
          child: SafeArea(
            child: TextButton(
              onPressed: () { setState(() { _showingIntro = false; _setupStep = 0; }); },
              child: Text('Skip', style: GoogleFonts.dmSans(
                fontSize: 15, color: const Color(0xFF94A3B8), fontWeight: FontWeight.w500)),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _buildIntroPage(int i) {
    final page = _pages[i];
    return Stack(children: [
      // Page background colour
      Container(color: page.bg),

      // Illustration — fills top 52 % of screen
      Positioned(
        top: 0, left: 0, right: 0,
        height: 52.h,
        child: AnimatedBuilder(
          animation: _illustCtrl,
          builder: (_, __) => Padding(
            padding: EdgeInsets.fromLTRB(6.w, 7.h, 6.w, 1.h),
            child: page.illustration(_illustCtrl.value),
          ),
        ),
      ),

      // White card — bottom 50 %, slightly overlapping
      Positioned(
        bottom: 0, left: 0, right: 0,
        top: 50.h,
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(36)),
            boxShadow: [BoxShadow(color: Color(0x14000000), blurRadius: 24, offset: Offset(0, -6))],
          ),
          padding: EdgeInsets.fromLTRB(7.w, 4.h, 7.w, 4.h),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Title
            Text(page.title,
              style: GoogleFonts.dmSans(
                fontSize: 30, fontWeight: FontWeight.w800,
                color: const Color(0xFF0F172A), height: 1.2, letterSpacing: -0.5,
              ),
            ),
            SizedBox(height: 1.2.h),
            // Body
            Text(page.sub,
              style: GoogleFonts.dmSans(
                fontSize: 17, color: const Color(0xFF64748B), height: 1.65,
              ),
            ),
            const Spacer(),
            // Dots + pill button in same row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Indicator dots
                Row(children: List.generate(3, (j) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  margin: const EdgeInsets.only(right: 6),
                  width: i == j ? 24 : 8, height: 8,
                  decoration: BoxDecoration(
                    color: i == j ? page.accent : page.accent.withAlpha(50),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ))),
                // Pill button
                GestureDetector(
                  onTap: _nextIntro,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 1.8.h),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [page.accent, page.accent.withAlpha(200)],
                        begin: Alignment.topLeft, end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(50),
                      boxShadow: [BoxShadow(color: page.accent.withAlpha(80), blurRadius: 16, offset: const Offset(0, 6))],
                    ),
                    child: Text(
                      i < 2 ? 'Next  →' : 'Get Started',
                      style: GoogleFonts.dmSans(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ]),
        ),
      ),
    ]);
  }

  // ── PHASE B ──────────────────────────────────────────────────────────────────
  Widget _buildSetupPhase() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: FadeTransition(
        opacity: _fadeCtrl,
        child: switch (_setupStep) {
          0 => _buildLoginStep(),
          1 => _buildLocationStep(),
          2 => _buildPrefsStep(),
          _ => _buildFinishStep(),
        },
      ),
    );
  }

  // ── STEP 0: GOOGLE LOGIN ─────────────────────────────────────────────────────
  Widget _buildLoginStep() {
    return Stack(children: [
      // Gradient hero — top 42 %
      Positioned(
        top: 0, left: 0, right: 0,
        height: 42.h,
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0A2463), Color(0xFF1A6BF5)],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              // Logo icon
              Container(
                width: 84, height: 84,
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(25),
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(color: Colors.white.withAlpha(70), width: 1.5),
                ),
                child: const Icon(Icons.hub_rounded, color: Colors.white, size: 42),
              ),
              SizedBox(height: 1.8.h),
              Text('NeuroGrid',
                style: GoogleFonts.dmSans(fontSize: 32, fontWeight: FontWeight.w800,
                  color: Colors.white, letterSpacing: -0.5)),
              SizedBox(height: 0.5.h),
              Text('Smart City Intelligence',
                style: GoogleFonts.dmSans(fontSize: 16, color: Colors.white70)),
            ]),
          ),
        ),
      ),

      // White card — bottom 62 %
      Positioned(
        bottom: 0, left: 0, right: 0,
        top: 40.h,
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(36)),
            boxShadow: [BoxShadow(color: Color(0x1A000000), blurRadius: 24, offset: Offset(0, -4))],
          ),
          padding: EdgeInsets.fromLTRB(7.w, 4.h, 7.w, 4.h),
          child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
            Text('Welcome to NeuroGrid',
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(fontSize: 27, fontWeight: FontWeight.w800,
                color: const Color(0xFF0F172A), letterSpacing: -0.4)),
            SizedBox(height: 1.h),
            Text('Sign in to personalise your city experience',
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(fontSize: 16, color: const Color(0xFF64748B))),
            SizedBox(height: 4.h),
            _GoogleBtn(loading: _googleLoading, done: _googleDone, onTap: _doGoogleLogin),
            SizedBox(height: 1.8.h),
            // Guest mode — always works, no OAuth setup needed
            GestureDetector(
              onTap: _googleDone ? null : _doGuestLogin,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.person_outline_rounded,
                      size: 20, color: Color(0xFF64748B)),
                  const SizedBox(width: 10),
                  Text('Continue as Guest',
                      style: GoogleFonts.dmSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF475569))),
                ]),
              ),
            ),
            SizedBox(height: 2.h),
            Text('By continuing you agree to our Terms & Privacy Policy.',
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(fontSize: 13, color: const Color(0xFF94A3B8))),
          ]),
        ),
      ),
    ]);
  }

  // ── STEP 1: LOCATION ─────────────────────────────────────────────────────────
  Widget _buildLocationStep() {
    return SafeArea(child: Column(children: [
      Expanded(child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 7.w),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(height: 6.h),
          Center(child: _AnimatedPin()),
          SizedBox(height: 4.h),
          Text('Enable Location', style: GoogleFonts.dmSans(fontSize: 28,
              fontWeight: FontWeight.w800, color: const Color(0xFF0F172A), letterSpacing: -0.4)),
          SizedBox(height: 1.2.h),
          Text('We use your location to show real-time city insights for your area — traffic, alerts, and local services.',
              style: GoogleFonts.dmSans(fontSize: 16, color: const Color(0xFF64748B), height: 1.55)),
          SizedBox(height: 3.h),
          _InfoRow(Icons.traffic_rounded, 'Live traffic for your commute'),
          _InfoRow(Icons.notification_important_rounded, 'Alerts near your location'),
          _InfoRow(Icons.local_parking_rounded, 'Nearby parking availability'),
        ]),
      )),
      Padding(
        padding: EdgeInsets.fromLTRB(7.w, 0, 7.w, 4.h),
        child: _PrimaryBtn(
          label: _locLoading ? 'Requesting…' : (_locGranted ? 'Granted ✓' : 'Allow Location'),
          color: const Color(0xFF1A6BF5),
          onTap: _locLoading ? null : _requestLocation,
          loading: _locLoading,
        ),
      ),
    ]));
  }

  // ── STEP 2: PREFERENCES ──────────────────────────────────────────────────────
  Widget _buildPrefsStep() {
    return SafeArea(child: Column(children: [
      Expanded(child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 7.w),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(height: 5.h),
          Text('What matters\nmost to you?', style: GoogleFonts.dmSans(fontSize: 28,
              fontWeight: FontWeight.w800, color: const Color(0xFF0F172A),
              height: 1.2, letterSpacing: -0.4)),
          SizedBox(height: 0.8.h),
          Text('Pick everything that applies — we\'ll personalise your dashboard.',
              style: GoogleFonts.dmSans(fontSize: 16, color: const Color(0xFF64748B))),
          SizedBox(height: 3.h),
          ..._prefs.map((p) {
            final selected = _selectedPrefs.contains(p[0]);
            return GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                setState(() {
                  if (p[0] == 'All of the above') {
                    _selectedPrefs.clear();
                    for (final pref in _prefs) { _selectedPrefs.add(pref[0]); }
                  } else {
                    if (selected) { _selectedPrefs.remove(p[0]); } else { _selectedPrefs.add(p[0]); }
                  }
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: EdgeInsets.only(bottom: 1.5.h),
                padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: selected ? const Color(0xFF1A6BF5) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: selected ? const Color(0xFF1A6BF5) : const Color(0xFFE2E8F0), width: 1.5),
                  boxShadow: selected ? [BoxShadow(color: const Color(0xFF1A6BF5).withAlpha(50), blurRadius: 12, offset: const Offset(0,4))] : [],
                ),
                child: Row(children: [
                  Text(p[1], style: const TextStyle(fontSize: 24)),
                  SizedBox(width: 3.w),
                  Text(p[0], style: GoogleFonts.dmSans(fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: selected ? Colors.white : const Color(0xFF1E293B))),
                  const Spacer(),
                  if (selected) const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                ]),
              ),
            );
          }),
        ]),
      )),
      Padding(
        padding: EdgeInsets.fromLTRB(7.w, 0, 7.w, 4.h),
        child: _PrimaryBtn(
          label: 'Continue',
          color: const Color(0xFF1A6BF5),
          onTap: _selectedPrefs.isEmpty ? null : _nextSetup,
        ),
      ),
    ]));
  }

  // ── STEP 3: FINISH ────────────────────────────────────────────────────────────
  Widget _buildFinishStep() {
    if (!_finishing) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _finish());
    }
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      _PulsingCity(),
      const SizedBox(height: 32),
      Text('Setting up your city…', style: GoogleFonts.dmSans(
          fontSize: 22, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A))),
      const SizedBox(height: 12),
      Text('Personalising NeuroGrid for you', style: GoogleFonts.dmSans(
          fontSize: 16, color: const Color(0xFF64748B))),
      const SizedBox(height: 32),
      const _ShimmerBar(),
    ]));
  }
}

// ── Shared widgets ────────────────────────────────────────────────────────────

class _PrimaryBtn extends StatefulWidget {
  final String label;
  final Color color;
  final VoidCallback? onTap;
  final bool loading;
  const _PrimaryBtn({required this.label, required this.color, this.onTap, this.loading = false});
  @override State<_PrimaryBtn> createState() => _PrimaryBtnState();
}

class _PrimaryBtnState extends State<_PrimaryBtn> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  @override void initState() { super.initState(); _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 100)); }
  @override void dispose() { _c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    return GestureDetector(
      onTapDown: enabled ? (_) => _c.forward() : null,
      onTapUp: enabled ? (_) { _c.reverse(); widget.onTap!(); } : null,
      onTapCancel: () => _c.reverse(),
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, child) => Transform.scale(scale: 1.0 - _c.value * 0.03, child: child),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity, height: 56,
          decoration: BoxDecoration(
            gradient: enabled ? LinearGradient(colors: [widget.color, widget.color.withAlpha(200)],
                begin: Alignment.centerLeft, end: Alignment.centerRight) : null,
            color: enabled ? null : const Color(0xFFE2E8F4),
            borderRadius: BorderRadius.circular(16),
            boxShadow: enabled ? [BoxShadow(color: widget.color.withAlpha(70), blurRadius: 16, offset: const Offset(0,6))] : [],
          ),
          child: Center(child: widget.loading
              ? const SizedBox(width: 22, height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.5, valueColor: AlwaysStoppedAnimation(Colors.white)))
              : Text(widget.label, style: GoogleFonts.dmSans(fontSize: 17, fontWeight: FontWeight.w700,
                  color: enabled ? Colors.white : const Color(0xFF9BA8C0)))),
        ),
      ),
    );
  }
}

class _GoogleBtn extends StatelessWidget {
  final bool loading, done;
  final VoidCallback onTap;
  const _GoogleBtn({required this.loading, required this.done, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: (loading || done) ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: double.infinity, height: 60,
        decoration: BoxDecoration(
          color: done ? const Color(0xFFEBF1FF) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: done ? const Color(0xFF1A6BF5) : const Color(0xFFE2E8F0), width: 1.5),
          boxShadow: [BoxShadow(color: Colors.black.withAlpha(12), blurRadius: 8, offset: const Offset(0,3))],
        ),
        child: Center(child: loading
            ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation(Color(0xFF4285F4))))
            : Row(mainAxisSize: MainAxisSize.min, children: [
                if (!done) ...[
                  _GoogleG(),
                  const SizedBox(width: 12),
                ],
                if (done) const Icon(Icons.check_circle_rounded, color: Color(0xFF1A6BF5), size: 20),
                if (done) const SizedBox(width: 8),
                Text(done ? 'Signed in' : 'Continue with Google',
                    style: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w600,
                        color: done ? const Color(0xFF1A6BF5) : const Color(0xFF1E293B))),
              ])),
      ),
    );
  }
}

class _GoogleG extends StatelessWidget {
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 22, height: 22,
    child: CustomPaint(painter: _GoogleGPainter()),
  );
}

class _GoogleGPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    final c = Offset(s.width/2, s.height/2);
    final r = s.width/2 - 1;
    void arc(double start, double sweep, Color color) {
      canvas.drawArc(Rect.fromCircle(center: c, radius: r), start, sweep, false,
          Paint()..color = color..strokeWidth = 2.5..style = PaintingStyle.stroke..strokeCap = StrokeCap.round);
    }
    arc(-0.3, 2.0, const Color(0xFF4285F4));
    arc(1.7, 1.5, const Color(0xFFEA4335));
    arc(3.2, 1.2, const Color(0xFF34A853));
    arc(4.4, 1.1, const Color(0xFFFBBC05));
    canvas.drawLine(c, Offset(s.width, c.dy),
        Paint()..color = const Color(0xFF4285F4)..strokeWidth = 2.5..strokeCap = StrokeCap.round);
  }
  @override bool shouldRepaint(_) => false;
}

class _InfoRow extends StatelessWidget {
  final IconData icon; final String text;
  const _InfoRow(this.icon, this.text);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Row(children: [
      Container(padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: const Color(0xFFEBF1FF), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, size: 20, color: const Color(0xFF1A6BF5))),
      const SizedBox(width: 14),
      Text(text, style: GoogleFonts.dmSans(fontSize: 15, color: const Color(0xFF334155), fontWeight: FontWeight.w500)),
    ]),
  );
}

class _AnimatedPin extends StatefulWidget {
  @override State<_AnimatedPin> createState() => _AnimatedPinState();
}
class _AnimatedPinState extends State<_AnimatedPin> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  @override void initState() { super.initState(); _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat(reverse: true); }
  @override void dispose() { _c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _c,
    builder: (_, __) => Transform.translate(
      offset: Offset(0, -8 * math.sin(_c.value * math.pi)),
      child: Container(
        width: 100, height: 100,
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF1A6BF5), Color(0xFF5BADFF)],
              begin: Alignment.topLeft, end: Alignment.bottomRight),
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: const Color(0xFF1A6BF5).withAlpha(60), blurRadius: 24, offset: const Offset(0,8))],
        ),
        child: const Icon(Icons.location_on_rounded, color: Colors.white, size: 48),
      ),
    ),
  );
}

class _PulsingCity extends StatefulWidget {
  @override State<_PulsingCity> createState() => _PulsingCityState();
}
class _PulsingCityState extends State<_PulsingCity> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  @override void initState() { super.initState(); _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat(reverse: true); }
  @override void dispose() { _c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _c,
    builder: (_, __) => Stack(alignment: Alignment.center, children: [
      Opacity(opacity: 0.15 + 0.15 * _c.value,
        child: Container(width: 140, height: 140,
          decoration: BoxDecoration(shape: BoxShape.circle,
            color: const Color(0xFF1A6BF5).withAlpha(60)))),
      Container(
        width: 96, height: 96,
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF1A6BF5), Color(0xFF5BADFF)],
              begin: Alignment.topLeft, end: Alignment.bottomRight),
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: const Color(0xFF1A6BF5).withAlpha(80), blurRadius: 28, offset: const Offset(0,8))],
        ),
        child: const Icon(Icons.location_city_rounded, color: Colors.white, size: 44),
      ),
    ]),
  );
}

class _ShimmerBar extends StatefulWidget {
  const _ShimmerBar();
  @override State<_ShimmerBar> createState() => _ShimmerBarState();
}
class _ShimmerBarState extends State<_ShimmerBar> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  @override void initState() { super.initState(); _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))..repeat(); }
  @override void dispose() { _c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _c,
    builder: (_, __) {
      return Container(
        width: 220, height: 6,
        decoration: BoxDecoration(
          color: const Color(0xFFE2E8F0),
          borderRadius: BorderRadius.circular(3),
        ),
        child: FractionallySizedBox(
          alignment: Alignment.centerLeft,
          widthFactor: _c.value,
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF1A6BF5), Color(0xFF5BADFF)]),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ),
      );
    },
  );
}
