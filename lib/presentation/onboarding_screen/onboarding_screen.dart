import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sizer/sizer.dart';
import '../../routes/app_routes.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Step 2 state
  bool _isGoogleLoading = false;
  bool _googleLoggedIn = false;

  // Step 3 state
  bool _isLocationLoading = false;
  bool _locationGranted = false;

  // Step 4 state
  final List<String> _preferences = [
    'Traffic',
    'Parking',
    'Alerts',
    'Waste',
    'Weather',
  ];
  final Set<String> _selectedPrefs = {};

  late AnimationController _pageAnimController;

  @override
  void initState() {
    super.initState();
    _pageAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _pageAnimController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _pageAnimController.dispose();
    super.dispose();
  }

  void _goToPage(int page) {
    _pageAnimController.reset();
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeInOutCubic,
    );
    setState(() => _currentPage = page);
    _pageAnimController.forward();
  }

  Future<void> _finishOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_onboarded', true);
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, AppRoutes.homeScreen);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FF),
      body: Stack(
        children: [
          PageView(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildWelcomePage(),
              _buildGoogleLoginPage(),
              _buildLocationPage(),
              _buildPreferencesPage(),
              _buildFinishPage(),
            ],
          ),
          // Page indicator dots
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: EdgeInsets.only(top: 1.5.h),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (i) {
                    final isActive = i == _currentPage;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutCubic,
                      margin: const EdgeInsets.symmetric(horizontal: 3.5),
                      width: isActive ? 22.0 : 7.0,
                      height: 7.0,
                      decoration: BoxDecoration(
                        color: isActive
                            ? const Color(0xFF1A6BF5)
                            : const Color(0xFF1A6BF5).withAlpha(56),
                        borderRadius: BorderRadius.circular(4.0),
                      ),
                    );
                  }),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── PAGE 1: WELCOME ────────────────────────────────────────────────────────
  Widget _buildWelcomePage() {
    return SafeArea(
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 6.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 5.h),
            // Illustration area
            Center(
              child: Container(
                width: 80.w,
                height: 30.h,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFEBF1FF), Color(0xFFD6E8FF)],
                  ),
                  borderRadius: BorderRadius.circular(28.0),
                ),
                child: Stack(
                  children: [
                    // Background grid lines
                    Positioned.fill(
                      child: CustomPaint(painter: _GridPainter()),
                    ),
                    // City illustration elements
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildCityBlock(
                                height: 8.h,
                                width: 8.w,
                                color: const Color(0xFF1A6BF5),
                              ),
                              SizedBox(width: 1.5.w),
                              _buildCityBlock(
                                height: 12.h,
                                width: 6.w,
                                color: const Color(0xFF2E8BFF),
                              ),
                              SizedBox(width: 1.5.w),
                              _buildCityBlock(
                                height: 6.h,
                                width: 9.w,
                                color: const Color(0xFF5BADFF),
                              ),
                              SizedBox(width: 1.5.w),
                              _buildCityBlock(
                                height: 10.h,
                                width: 7.w,
                                color: const Color(0xFF1A6BF5),
                              ),
                              SizedBox(width: 1.5.w),
                              _buildCityBlock(
                                height: 7.h,
                                width: 8.w,
                                color: const Color(0xFF3B82F6),
                              ),
                            ],
                          ),
                          SizedBox(height: 1.h),
                          // Road
                          Container(
                            width: 60.w,
                            height: 1.2.h,
                            decoration: BoxDecoration(
                              color: const Color(0xFF94B4E8),
                              borderRadius: BorderRadius.circular(4.0),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Floating data nodes
                    Positioned(
                      top: 2.h,
                      right: 4.w,
                      child: _buildDataNode(
                        Icons.wifi_rounded,
                        const Color(0xFF1A6BF5),
                      ),
                    ),
                    Positioned(
                      top: 3.h,
                      left: 4.w,
                      child: _buildDataNode(
                        Icons.sensors_rounded,
                        const Color(0xFF2E8BFF),
                      ),
                    ),
                    Positioned(
                      bottom: 3.h,
                      right: 6.w,
                      child: _buildDataNode(
                        Icons.bolt_rounded,
                        const Color(0xFF5BADFF),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 5.h),
            Text(
              'Welcome to\nNeuroGrid',
              style: GoogleFonts.dmSans(
                fontSize: 17.sp,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
                height: 1.2,
                letterSpacing: -0.5,
              ),
            ),
            SizedBox(height: 1.5.h),
            Text(
              'Your smart city companion — real-time insights\nfor traffic, weather, and city services.',
              style: GoogleFonts.dmSans(
                fontSize: 11.sp,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF475569),
                height: 1.55,
              ),
            ),
                  SizedBox(height: 3.h),
                ],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(6.w, 0, 6.w, 4.h),
            child: _buildPrimaryButton(label: 'Continue', onTap: () => _goToPage(1)),
          ),
        ],
      ),
    );
  }

  Widget _buildCityBlock({
    required double height,
    required double width,
    required Color color,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color.withAlpha(179),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(4.0),
          topRight: Radius.circular(4.0),
        ),
      ),
    );
  }

  Widget _buildDataNode(IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: color.withAlpha(51),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(icon, size: 16, color: color),
    );
  }

  // ─── PAGE 2: GOOGLE LOGIN ────────────────────────────────────────────────────
  Widget _buildGoogleLoginPage() {
    return SafeArea(
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 6.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 5.h),
            Center(
              child: Container(
                width: 20.w,
                height: 20.w,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1A6BF5), Color(0xFF5BADFF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24.0),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1A6BF5).withAlpha(77),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.lock_open_rounded,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              _googleLoggedIn ? 'You\'re signed in!' : 'Sign in to continue',
              style: GoogleFonts.dmSans(
                fontSize: 17.sp,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
                letterSpacing: -0.4,
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              _googleLoggedIn
                  ? 'Welcome back. Your city data is ready.'
                  : 'Use your Google account to personalize\nyour NeuroGrid experience.',
              style: GoogleFonts.dmSans(
                fontSize: 11.sp,
                color: const Color(0xFF475569),
                height: 1.55,
              ),
            ),
            SizedBox(height: 5.h),
            if (!_googleLoggedIn) ...[
              // Google button
              GestureDetector(
                onTap: _isGoogleLoading
                    ? null
                    : () async {
                        setState(() => _isGoogleLoading = true);
                        await Future.delayed(
                          const Duration(milliseconds: 1600),
                        );
                        if (!mounted) return;
                        setState(() {
                          _isGoogleLoading = false;
                          _googleLoggedIn = true;
                        });
                      },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: double.infinity,
                  height: 7.h,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16.0),
                    border: Border.all(
                      color: const Color(0xFFE2E8F4),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(15),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: _isGoogleLoading
                      ? const Center(
                          child: SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation(
                                Color(0xFF1A6BF5),
                              ),
                            ),
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Google G icon
                            Container(
                              width: 22,
                              height: 22,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                              ),
                              child: CustomPaint(painter: _GoogleGPainter()),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Continue with Google',
                              style: GoogleFonts.dmSans(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              SizedBox(height: 2.h),
              Center(
                child: Text(
                  'We never post without your permission',
                  style: GoogleFonts.dmSans(
                    fontSize: 9.5.sp,
                    color: const Color(0xFF9BA8C0),
                  ),
                ),
              ),
            ] else ...[
              // Success state
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(4.w),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(16.0),
                  border: Border.all(
                    color: const Color(0xFF16A34A).withAlpha(77),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF16A34A).withAlpha(31),
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      child: const Icon(
                        Icons.check_circle_rounded,
                        color: Color(0xFF16A34A),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Signed in as',
                          style: GoogleFonts.dmSans(
                            fontSize: 9.5.sp,
                            color: const Color(0xFF475569),
                          ),
                        ),
                        Text(
                          'user@gmail.com',
                          style: GoogleFonts.dmSans(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
                  SizedBox(height: 3.h),
                ],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(6.w, 0, 6.w, 4.h),
            child: _googleLoggedIn
                ? _buildPrimaryButton(label: 'Continue', onTap: () => _goToPage(2))
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  // ─── PAGE 3: LOCATION ────────────────────────────────────────────────────────
  Widget _buildLocationPage() {
    return SafeArea(
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 6.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 5.h),
            Center(
              child: Container(
                width: 20.w,
                height: 20.w,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2E8BFF), Color(0xFF5BADFF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24.0),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2E8BFF).withAlpha(77),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.location_on_rounded,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              'Enable Location',
              style: GoogleFonts.dmSans(
                fontSize: 17.sp,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
                letterSpacing: -0.4,
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              'We use your location to provide real-time\ncity insights tailored to your area.',
              style: GoogleFonts.dmSans(
                fontSize: 11.sp,
                color: const Color(0xFF475569),
                height: 1.55,
              ),
            ),
            SizedBox(height: 4.h),
            if (_locationGranted) ...[
              // Map preview card
              Container(
                width: double.infinity,
                height: 22.h,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(20),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20.0),
                  child: Stack(
                    children: [
                      // Map background
                      Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFFD6E8FF), Color(0xFFEBF4FF)],
                          ),
                        ),
                      ),
                      // Grid lines
                      Positioned.fill(
                        child: CustomPaint(painter: _MapGridPainter()),
                      ),
                      // Location pin
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1A6BF5),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(
                                      0xFF1A6BF5,
                                    ).withAlpha(102),
                                    blurRadius: 16,
                                    spreadRadius: 4,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.my_location_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 2.h),
              // Location result
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(4.w),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16.0),
                  border: Border.all(color: const Color(0xFFE2E8F4)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(10),
                      blurRadius: 12,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEBF1FF),
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      child: const Icon(
                        Icons.location_city_rounded,
                        color: Color(0xFF1A6BF5),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bhopal, Madhya Pradesh',
                          style: GoogleFonts.dmSans(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          'Location detected',
                          style: GoogleFonts.dmSans(
                            fontSize: 9.5.sp,
                            color: const Color(0xFF16A34A),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    const Icon(
                      Icons.check_circle_rounded,
                      color: Color(0xFF16A34A),
                      size: 20,
                    ),
                  ],
                ),
              ),
            ] else ...[
              // Permission info cards
              _buildPermissionInfoCard(
                icon: Icons.traffic_rounded,
                title: 'Live traffic updates',
                subtitle: 'Real-time congestion near you',
              ),
              SizedBox(height: 1.5.h),
              _buildPermissionInfoCard(
                icon: Icons.cloud_rounded,
                title: 'Hyper-local weather',
                subtitle: 'Accurate forecasts for your area',
              ),
              SizedBox(height: 1.5.h),
              _buildPermissionInfoCard(
                icon: Icons.notifications_rounded,
                title: 'City alerts',
                subtitle: 'Incidents and events nearby',
              ),
            ],
                  SizedBox(height: 3.h),
                ],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(6.w, 0, 6.w, 4.h),
            child: !_locationGranted
                ? _buildPrimaryButton(
                    label: _isLocationLoading ? 'Detecting...' : 'Allow Location',
                    isLoading: _isLocationLoading,
                    onTap: _isLocationLoading
                        ? null
                        : () async {
                            setState(() => _isLocationLoading = true);
                            await Future.delayed(
                              const Duration(milliseconds: 1800),
                            );
                            if (!mounted) return;
                            setState(() {
                              _isLocationLoading = false;
                              _locationGranted = true;
                            });
                          },
                  )
                : _buildPrimaryButton(label: 'Continue', onTap: () => _goToPage(3)),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionInfoCard({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.0),
        border: Border.all(color: const Color(0xFFE2E8F4)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFEBF1FF),
              borderRadius: BorderRadius.circular(10.0),
            ),
            child: Icon(icon, color: const Color(0xFF1A6BF5), size: 18),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.dmSans(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF0F172A),
                ),
              ),
              Text(
                subtitle,
                style: GoogleFonts.dmSans(
                  fontSize: 9.5.sp,
                  color: const Color(0xFF475569),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── PAGE 4: PREFERENCES ─────────────────────────────────────────────────────
  Widget _buildPreferencesPage() {
    return SafeArea(
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 6.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 5.h),
            Center(
              child: Container(
                width: 20.w,
                height: 20.w,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF5BADFF), Color(0xFF1A6BF5)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24.0),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1A6BF5).withAlpha(77),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.tune_rounded,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              'What matters\nmost to you?',
              style: GoogleFonts.dmSans(
                fontSize: 17.sp,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
                height: 1.2,
                letterSpacing: -0.4,
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              'Select up to 3 topics to personalize\nyour city dashboard.',
              style: GoogleFonts.dmSans(
                fontSize: 11.sp,
                color: const Color(0xFF475569),
                height: 1.55,
              ),
            ),
            SizedBox(height: 4.h),
            Wrap(
              spacing: 2.5.w,
              runSpacing: 1.5.h,
              children: _preferences.map((pref) {
                final isSelected = _selectedPrefs.contains(pref);
                final icon = _prefIcon(pref);
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _selectedPrefs.remove(pref);
                      } else if (_selectedPrefs.length < 3) {
                        _selectedPrefs.add(pref);
                      }
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    padding: EdgeInsets.symmetric(
                      horizontal: 4.w,
                      vertical: 1.5.h,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF1A6BF5)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(50.0),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF1A6BF5)
                            : const Color(0xFFE2E8F4),
                        width: 1.5,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: const Color(0xFF1A6BF5).withAlpha(64),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : [
                              BoxShadow(
                                color: Colors.black.withAlpha(10),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          icon,
                          size: 16,
                          color: isSelected
                              ? Colors.white
                              : const Color(0xFF475569),
                        ),
                        const SizedBox(width: 7),
                        Text(
                          pref,
                          style: GoogleFonts.dmSans(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? Colors.white
                                : const Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            SizedBox(height: 2.h),
            if (_selectedPrefs.isNotEmpty)
              Text(
                '${_selectedPrefs.length}/3 selected',
                style: GoogleFonts.dmSans(
                  fontSize: 9.5.sp,
                  color: const Color(0xFF1A6BF5),
                  fontWeight: FontWeight.w500,
                ),
              ),
                  SizedBox(height: 3.h),
                ],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(6.w, 0, 6.w, 0),
            child: _buildPrimaryButton(
              label: 'Continue',
              onTap: _selectedPrefs.isEmpty ? null : () => _goToPage(4),
            ),
          ),
          Center(
            child: TextButton(
              onPressed: () => _goToPage(4),
              child: Text(
                'Skip for now',
                style: GoogleFonts.dmSans(
                  fontSize: 10.5.sp,
                  color: const Color(0xFF9BA8C0),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          SizedBox(height: 2.h),
        ],
      ),
    );
  }

  IconData _prefIcon(String pref) {
    switch (pref) {
      case 'Traffic':
        return Icons.traffic_rounded;
      case 'Parking':
        return Icons.local_parking_rounded;
      case 'Alerts':
        return Icons.notifications_active_rounded;
      case 'Waste':
        return Icons.delete_outline_rounded;
      case 'Weather':
        return Icons.wb_sunny_rounded;
      default:
        return Icons.circle_rounded;
    }
  }

  // ─── PAGE 5: FINISH ──────────────────────────────────────────────────────────
  Widget _buildFinishPage() {
    return SafeArea(
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 6.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(height: 5.h),
            // Celebration icon
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 600),
              curve: Curves.elasticOut,
              builder: (context, value, child) {
                return Transform.scale(scale: value, child: child);
              },
              child: Container(
                width: 25.w,
                height: 25.w,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1A6BF5), Color(0xFF5BADFF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1A6BF5).withAlpha(89),
                      blurRadius: 32,
                      spreadRadius: 4,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 44,
                ),
              ),
            ),
            SizedBox(height: 5.h),
            Text(
              'You\'re all set',
              style: GoogleFonts.dmSans(
                fontSize: 18.sp,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
                letterSpacing: -0.5,
              ),
            ),
            SizedBox(height: 1.5.h),
            Text(
              'Let\'s make your city smarter',
              style: GoogleFonts.dmSans(
                fontSize: 12.sp,
                color: const Color(0xFF475569),
                fontWeight: FontWeight.w400,
              ),
            ),
            SizedBox(height: 5.h),
            // Summary chips
            Wrap(
              spacing: 2.w,
              runSpacing: 1.2.h,
              alignment: WrapAlignment.center,
              children: [
                _buildSummaryChip(Icons.location_on_rounded, 'Bhopal, MP'),
                _buildSummaryChip(Icons.account_circle_rounded, 'Signed in'),
                ..._selectedPrefs.map(
                  (p) => _buildSummaryChip(_prefIcon(p), p),
                ),
              ],
            ),
                  SizedBox(height: 3.h),
                ],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(6.w, 0, 6.w, 4.h),
            child: _buildPrimaryButton(label: 'Enter App', onTap: _finishOnboarding),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryChip(IconData icon, String label) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 3.5.w, vertical: 1.h),
      decoration: BoxDecoration(
        color: const Color(0xFFEBF1FF),
        borderRadius: BorderRadius.circular(50.0),
        border: Border.all(color: const Color(0xFF1A6BF5).withAlpha(51)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF1A6BF5)),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.dmSans(
              fontSize: 10.sp,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1A6BF5),
            ),
          ),
        ],
      ),
    );
  }

  // ─── SHARED BUTTON ───────────────────────────────────────────────────────────
  Widget _buildPrimaryButton({
    required String label,
    VoidCallback? onTap,
    bool isLoading = false,
  }) {
    final isEnabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        height: 7.h,
        decoration: BoxDecoration(
          gradient: isEnabled
              ? const LinearGradient(
                  colors: [Color(0xFF1A6BF5), Color(0xFF2E8BFF)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                )
              : null,
          color: isEnabled ? null : const Color(0xFFE2E8F4),
          borderRadius: BorderRadius.circular(16.0),
          boxShadow: isEnabled
              ? [
                  BoxShadow(
                    color: const Color(0xFF1A6BF5).withAlpha(77),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation(Colors.white),
                  ),
                )
              : Text(
                  label,
                  style: GoogleFonts.dmSans(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: isEnabled ? Colors.white : const Color(0xFF9BA8C0),
                  ),
                ),
        ),
      ),
    );
  }
}

// ─── CUSTOM PAINTERS ─────────────────────────────────────────────────────────

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1A6BF5).withAlpha(20)
      ..strokeWidth = 1;
    const step = 24.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final roadPaint = Paint()
      ..color = const Color(0xFF94B4E8).withAlpha(128)
      ..strokeWidth = 6;
    final gridPaint = Paint()
      ..color = const Color(0xFF1A6BF5).withAlpha(15)
      ..strokeWidth = 1;

    // Grid
    const step = 20.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Roads
    canvas.drawLine(
      Offset(0, size.height * 0.5),
      Offset(size.width, size.height * 0.5),
      roadPaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.5, 0),
      Offset(size.width * 0.5, size.height),
      roadPaint,
    );
    canvas.drawLine(
      Offset(0, size.height * 0.3),
      Offset(size.width, size.height * 0.3),
      roadPaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.3, 0),
      Offset(size.width * 0.3, size.height),
      roadPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _GoogleGPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Blue arc
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -0.3,
      2.0,
      false,
      Paint()
        ..color = const Color(0xFF4285F4)
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    // Red arc
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      1.7,
      1.5,
      false,
      Paint()
        ..color = const Color(0xFFEA4335)
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    // Green arc
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      3.2,
      1.2,
      false,
      Paint()
        ..color = const Color(0xFF34A853)
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    // Yellow arc
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      4.4,
      1.1,
      false,
      Paint()
        ..color = const Color(0xFFFBBC05)
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    // Horizontal bar
    canvas.drawLine(
      Offset(center.dx, center.dy),
      Offset(size.width, center.dy),
      Paint()
        ..color = const Color(0xFF4285F4)
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
