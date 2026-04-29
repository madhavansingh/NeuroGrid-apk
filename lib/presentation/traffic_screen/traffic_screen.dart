import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_navigation.dart';
import '../../core/services/tomtom_traffic_service.dart';

// ── Animated traffic polyline ─────────────────────────────────────────────────
/// Smoothly transitions a single road segment's color when traffic status changes.
class _AnimatedTrafficPolyline extends StatefulWidget {
  final TrafficSegment segment;
  final Color targetColor;
  final double strokeWidth;
  final double flowOffset; // 0.0–1.0, drives the dash flow animation

  const _AnimatedTrafficPolyline({
    required this.segment,
    required this.targetColor,
    required this.strokeWidth,
    required this.flowOffset,
  });

  @override
  State<_AnimatedTrafficPolyline> createState() =>
      _AnimatedTrafficPolylineState();
}

class _AnimatedTrafficPolylineState extends State<_AnimatedTrafficPolyline>
    with SingleTickerProviderStateMixin {
  late AnimationController _colorController;
  late Animation<Color?> _colorAnim;
  Color _fromColor = Colors.transparent;

  @override
  void initState() {
    super.initState();
    _fromColor = widget.targetColor;
    _colorController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _colorAnim = ColorTween(begin: _fromColor, end: widget.targetColor).animate(
      CurvedAnimation(parent: _colorController, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(_AnimatedTrafficPolyline oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.targetColor != widget.targetColor) {
      _fromColor = _colorAnim.value ?? _fromColor;
      _colorAnim = ColorTween(begin: _fromColor, end: widget.targetColor)
          .animate(
            CurvedAnimation(parent: _colorController, curve: Curves.easeInOut),
          );
      _colorController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _colorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _colorAnim,
      builder: (_, __) {
        final color = _colorAnim.value ?? widget.targetColor;
        // Compute a subtle pulsing opacity (0.72–0.92) driven by flowOffset
        final pulse = 0.72 + 0.20 * sin(widget.flowOffset * 2 * pi);
        return PolylineLayer(
          polylines: [
            // Shadow / glow layer
            Polyline(
              points: widget.segment.points,
              color: color.withAlpha(46),
              strokeWidth: widget.strokeWidth + 5,
              strokeCap: StrokeCap.round,
              strokeJoin: StrokeJoin.round,
            ),
            // Main colored road line
            Polyline(
              points: widget.segment.points,
              color: color.withOpacity(pulse),
              strokeWidth: widget.strokeWidth,
              strokeCap: StrokeCap.round,
              strokeJoin: StrokeJoin.round,
            ),
          ],
        );
      },
    );
  }
}

// ── Main screen ───────────────────────────────────────────────────────────────

class TrafficScreen extends StatefulWidget {
  const TrafficScreen({super.key});

  @override
  State<TrafficScreen> createState() => _TrafficScreenState();
}

class _TrafficScreenState extends State<TrafficScreen>
    with TickerProviderStateMixin {
  int _navIndex = 1;

  // Map
  late final MapController _mapController;
  bool _trafficLayerOn = true;

  // Traffic data
  List<TrafficSegment> _segments = [];
  bool _isSimulated = false;
  bool _isLoading = true;

  // Search / route
  final TextEditingController _searchController = TextEditingController();
  bool _showRouteResult = false;
  String _destination = '';

  // Bottom sheet
  late DraggableScrollableController _sheetController;

  // ── Animation controllers ─────────────────────────────────────────────────
  // Drives the flowing dash / pulse effect on polylines (continuous loop)
  late AnimationController _flowController;
  late Animation<double> _flowAnim;

  // Drives the fade-in of the traffic layer when data first loads or refreshes
  late AnimationController _fadeController;
  late Animation<double> _fadeAnim;

  // Drives the live-badge pulse dot
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  // Route draw animation
  late AnimationController _routeDrawController;

  // Live update timer
  Timer? _updateTimer;
  int _secondsSinceUpdate = 0;

  // Bhopal center
  static const LatLng _bhopalCenter = LatLng(23.2599, 77.4126);

  // Route polylines
  static const List<LatLng> _mainRoute = [
    LatLng(23.2599, 77.4126),
    LatLng(23.2560, 77.4100),
    LatLng(23.2520, 77.4080),
    LatLng(23.2480, 77.4060),
    LatLng(23.2440, 77.4040),
    LatLng(23.2400, 77.4020),
    LatLng(23.2368, 77.4011),
  ];

  static const List<LatLng> _altRoute = [
    LatLng(23.2599, 77.4126),
    LatLng(23.2580, 77.4200),
    LatLng(23.2540, 77.4280),
    LatLng(23.2480, 77.4360),
    LatLng(23.2420, 77.4420),
    LatLng(23.2368, 77.4011),
  ];

  // ── Color helpers ─────────────────────────────────────────────────────────

  Color _statusColor(TrafficStatus status) {
    switch (status) {
      case TrafficStatus.smooth:
        return const Color(0xFF16A34A);
      case TrafficStatus.moderate:
        return const Color(0xFFF59E0B);
      case TrafficStatus.heavy:
        return const Color(0xFFDC2626);
    }
  }

  String _statusLabel(TrafficStatus status) {
    switch (status) {
      case TrafficStatus.smooth:
        return 'Smooth';
      case TrafficStatus.moderate:
        return 'Moderate';
      case TrafficStatus.heavy:
        return 'Heavy';
    }
  }

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    _mapController = MapController();
    _sheetController = DraggableScrollableController();

    // Continuous flow animation — drives the polyline pulse/flow effect
    _flowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
    _flowAnim = Tween<double>(begin: 0.0, end: 1.0).animate(_flowController);

    // Fade-in when traffic data loads/refreshes
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);

    // Live badge pulse dot
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _routeDrawController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _fetchTrafficData();

    // Refresh every 30 s; update "X sec ago" every second
    _updateTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _secondsSinceUpdate++;
        if (_secondsSinceUpdate >= 30) {
          _secondsSinceUpdate = 0;
          _fetchTrafficData();
        }
      });
    });
  }

  @override
  void dispose() {
    _flowController.dispose();
    _fadeController.dispose();
    _pulseController.dispose();
    _routeDrawController.dispose();
    _updateTimer?.cancel();
    _searchController.dispose();
    _mapController.dispose();
    _sheetController.dispose();
    super.dispose();
  }

  // ── Data fetching ─────────────────────────────────────────────────────────

  Future<void> _fetchTrafficData() async {
    final result = await TomTomTrafficService.instance.fetchBhopalTraffic();
    if (!mounted) return;

    // Fade out briefly before updating, then fade back in — no flicker
    if (_segments.isNotEmpty) {
      await _fadeController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeIn,
      );
    }

    setState(() {
      _segments = result.segments;
      _isSimulated = result.isSimulated;
      _isLoading = false;
      _secondsSinceUpdate = 0;
    });

    // Fade the new data in smoothly
    _fadeController.forward(from: _fadeController.value);
  }

  // ── Map helpers ───────────────────────────────────────────────────────────

  Future<void> _goToMyLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) return;
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      _mapController.move(LatLng(position.latitude, position.longitude), 15.0);
    } catch (_) {}
  }

  void _onSearchSubmit(String value) {
    if (value.trim().isEmpty) return;
    setState(() {
      _destination = value.trim();
      _showRouteResult = true;
      _secondsSinceUpdate = 0;
    });
    _routeDrawController.forward(from: 0);
    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: LatLngBounds(
          const LatLng(23.2300, 77.3950),
          const LatLng(23.2700, 77.4450),
        ),
        padding: const EdgeInsets.all(60),
      ),
    );
    Future.delayed(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      _sheetController.animateTo(
        0.45,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    });
  }

  void _clearRoute() {
    setState(() {
      _showRouteResult = false;
      _destination = '';
      _searchController.clear();
    });
    _sheetController.animateTo(
      0.12,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _launchGoogleMapsNavigation() async {
    final encodedTo = Uri.encodeComponent(
      _destination.isEmpty ? 'MP Nagar, Bhopal' : _destination,
    );
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$encodedTo&travelmode=driving',
    );
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }

  String get _updateLabel {
    if (_secondsSinceUpdate < 5) return 'Updated just now';
    if (_secondsSinceUpdate < 60) return 'Updated ${_secondsSinceUpdate}s ago';
    return 'Updated ${(_secondsSinceUpdate / 60).floor()}m ago';
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: Colors.white,
      extendBody: true,
      body: Stack(
        children: [
          // ── Full-screen flutter_map ───────────────────────────────────────
          Positioned.fill(child: _buildMap()),

          // ── Top search bar ────────────────────────────────────────────────
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 16,
            right: 16,
            child: _buildSearchBar(),
          ),

          // ── Live update badge ─────────────────────────────────────────────
          Positioned(
            top: MediaQuery.of(context).padding.top + 76,
            left: 0,
            right: 0,
            child: Center(child: _buildLiveBadge()),
          ),

          // ── Simulation badge ──────────────────────────────────────────────
          if (_isSimulated)
            Positioned(
              top: MediaQuery.of(context).padding.top + 110,
              left: 0,
              right: 0,
              child: Center(child: _buildSimulationBadge()),
            ),

          // ── Floating right controls ───────────────────────────────────────
          Positioned(
            right: 16,
            bottom: bottomPad + 120,
            child: _buildFloatingControls(),
          ),

          // ── Draggable bottom sheet ────────────────────────────────────────
          DraggableScrollableSheet(
            controller: _sheetController,
            initialChildSize: 0.12,
            minChildSize: 0.10,
            maxChildSize: 0.72,
            snap: true,
            snapSizes: const [0.12, 0.45, 0.72],
            builder: (context, scrollController) =>
                _buildBottomSheet(scrollController, bottomPad),
          ),
        ],
      ),
      bottomNavigationBar: AppNavigation(
        currentIndex: _navIndex,
        onTap: (i) {
          setState(() => _navIndex = i);
          if (i == 0) Navigator.pushNamed(context, '/home-screen');
          if (i == 1) Navigator.pushNamed(context, '/3d-map-screen');
          if (i == 2) Navigator.pushNamed(context, '/3d-map-screen');
          if (i == 3) Navigator.pushNamed(context, '/ai-assistant-screen');
          if (i == 4) Navigator.pushNamed(context, '/profile-screen');
        },
      ),
    );
  }

  // ── Map widget ────────────────────────────────────────────────────────────

  Widget _buildMap() {
    return FlutterMap(
      mapController: _mapController,
      options: const MapOptions(
        initialCenter: _bhopalCenter,
        initialZoom: 13.0,
        minZoom: 5,
        maxZoom: 18,
        interactionOptions: InteractionOptions(flags: InteractiveFlag.all),
      ),
      children: [
        // Base OSM tile layer
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.neurogrid',
          maxZoom: 18,
        ),

        // ── Smooth animated traffic overlay ───────────────────────────────
        if (_trafficLayerOn && !_isLoading)
          AnimatedBuilder(
            animation: Listenable.merge([_flowAnim, _fadeAnim]),
            builder: (_, __) {
              return Opacity(
                opacity: _fadeAnim.value,
                child: Stack(
                  children: _segments.map((seg) {
                    return _AnimatedTrafficPolyline(
                      segment: seg,
                      targetColor: _statusColor(seg.status),
                      strokeWidth: 6.0,
                      flowOffset: _flowAnim.value,
                    );
                  }).toList(),
                ),
              );
            },
          ),

        // Route polylines (shown when destination entered)
        if (_showRouteResult) ...[
          PolylineLayer(
            polylines: [
              Polyline(
                points: _altRoute,
                color: const Color(0xFF94A3B8),
                strokeWidth: 5.0,
                strokeCap: StrokeCap.round,
              ),
              Polyline(
                points: _mainRoute,
                color: const Color(0xFF1A6BF5),
                strokeWidth: 8.0,
                strokeCap: StrokeCap.round,
              ),
            ],
          ),
        ],
      ],
    );
  }

  // ── Search bar ────────────────────────────────────────────────────────────

  Widget _buildSearchBar() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          height: 54,
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(230),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white.withAlpha(200), width: 1),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1A6BF5).withAlpha(18),
                blurRadius: 24,
                offset: const Offset(0, 6),
              ),
              BoxShadow(
                color: Colors.black.withAlpha(14),
                blurRadius: 12,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              const SizedBox(width: 16),
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1A6BF5), Color(0xFF4A8FFF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.search_rounded, size: 17, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onSubmitted: _onSearchSubmit,
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search destination in Bhopal…',
                    hintStyle: GoogleFonts.dmSans(
                      fontSize: 14,
                      color: AppTheme.textMuted,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                ),
              ),
              if (_showRouteResult)
                GestureDetector(
                  onTap: _clearRoute,
                  child: Container(
                    margin: const EdgeInsets.only(right: 12),
                    width: 28, height: 28,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.close_rounded, size: 16,
                        color: Color(0xFF64748B)),
                  ),
                )
              else
                const SizedBox(width: 14),
            ],
          ),
        ),
      ),
    );
  }

  // ── Live badge ────────────────────────────────────────────────────────────

  Widget _buildLiveBadge() {
    final heavyCount = _segments
        .where((s) => s.status == TrafficStatus.heavy)
        .length;
    final modCount = _segments
        .where((s) => s.status == TrafficStatus.moderate)
        .length;
    final Color dotColor = heavyCount >= 2
        ? const Color(0xFFDC2626)
        : modCount >= 2
            ? const Color(0xFFF59E0B)
            : const Color(0xFF16A34A);

    return AnimatedBuilder(
      animation: _pulseAnim,
      builder: (_, __) => ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(230),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Colors.white.withAlpha(180), width: 1),
              boxShadow: [
                BoxShadow(
                  color: dotColor.withAlpha(30),
                  blurRadius: 12,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Pulsing dot
                Container(
                  width: 8, height: 8,
                  decoration: BoxDecoration(
                    color: dotColor.withOpacity(0.5 + 0.5 * _pulseAnim.value),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: dotColor.withAlpha(80),
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 7),
                Text(
                  'LIVE  ·  $_updateLabel',
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Simulation badge ──────────────────────────────────────────────────────

  Widget _buildSimulationBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF59E0B).withAlpha(235),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.info_outline_rounded, size: 12, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            'Simulation',
            style: GoogleFonts.dmSans(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // ── Floating controls ─────────────────────────────────────────────────────

  Widget _buildFloatingControls() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _FloatBtn(
          icon: _trafficLayerOn
              ? Icons.traffic_rounded
              : Icons.traffic_outlined,
          active: _trafficLayerOn,
          onTap: () => setState(() => _trafficLayerOn = !_trafficLayerOn),
          tooltip: _trafficLayerOn ? 'Hide Traffic' : 'Show Traffic',
        ),
        const SizedBox(height: 10),
        _FloatBtn(
          icon: Icons.my_location_rounded,
          onTap: _goToMyLocation,
          tooltip: 'My Location',
        ),
        const SizedBox(height: 10),
        _FloatBtn(
          icon: Icons.add_rounded,
          onTap: () {
            final current = _mapController.camera.zoom;
            _mapController.move(_mapController.camera.center, current + 1);
          },
          tooltip: 'Zoom In',
        ),
        const SizedBox(height: 6),
        _FloatBtn(
          icon: Icons.remove_rounded,
          onTap: () {
            final current = _mapController.camera.zoom;
            _mapController.move(_mapController.camera.center, current - 1);
          },
          tooltip: 'Zoom Out',
        ),
      ],
    );
  }

  // ── Bottom sheet ──────────────────────────────────────────────────────────

  Widget _buildBottomSheet(
    ScrollController scrollController,
    double bottomPad,
  ) {
    final heavyCount = _segments
        .where((s) => s.status == TrafficStatus.heavy)
        .length;
    final modCount = _segments
        .where((s) => s.status == TrafficStatus.moderate)
        .length;
    final List<Color> stripGradient = heavyCount >= 2
        ? [const Color(0xFFDC2626), const Color(0xFFFF6B6B)]
        : modCount >= 2
            ? [const Color(0xFFF59E0B), const Color(0xFFFBBF24)]
            : [const Color(0xFF10B981), const Color(0xFF34D399)];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(20),
            blurRadius: 32,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: Column(
          children: [
            // Gradient status strip at very top
            Container(
              height: 3,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: stripGradient),
              ),
            ),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: EdgeInsets.only(bottom: bottomPad + 16),
                children: [
                  // Drag handle
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(top: 10, bottom: 14),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  if (!_showRouteResult) ...[
                    _buildTrafficSummary(),
                  ] else ...[
                    _buildRouteInfo(),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrafficSummary() {
    final heavyCount = _segments
        .where((s) => s.status == TrafficStatus.heavy)
        .length;
    final modCount = _segments
        .where((s) => s.status == TrafficStatus.moderate)
        .length;

    String headline;
    Color headlineColor;
    if (heavyCount >= 3) {
      headline = 'Heavy traffic near MP Nagar & New Market';
      headlineColor = const Color(0xFFDC2626);
    } else if (heavyCount >= 1 || modCount >= 3) {
      headline = 'Moderate congestion on key routes';
      headlineColor = const Color(0xFFF59E0B);
    } else {
      headline = 'Traffic flowing smoothly across Bhopal';
      headlineColor = const Color(0xFF16A34A);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: headlineColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  headline,
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Legend
          Row(
            children: [
              _LegendDot(color: const Color(0xFF16A34A), label: 'Smooth'),
              const SizedBox(width: 16),
              _LegendDot(color: const Color(0xFFF59E0B), label: 'Moderate'),
              const SizedBox(width: 16),
              _LegendDot(color: const Color(0xFFDC2626), label: 'Heavy'),
            ],
          ),
          const SizedBox(height: 16),
          // Road segment list
          if (!_isLoading)
            ..._segments.take(5).map((seg) => _buildSegmentRow(seg)),
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          const SizedBox(height: 8),
          Text(
            _isSimulated ? 'Camera + simulation' : 'Based on live + AI data',
            style: GoogleFonts.dmSans(fontSize: 11, color: AppTheme.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentRow(TrafficSegment seg) {
    final color = _statusColor(seg.status);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          // Animated color bar
          TweenAnimationBuilder<Color?>(
            tween: ColorTween(begin: color, end: color),
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeInOut,
            builder: (_, c, __) => Container(
              width: 4,
              height: 32,
              decoration: BoxDecoration(
                color: c ?? color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _roadName(seg.id),
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Text(
                  '${seg.currentSpeed.toStringAsFixed(0)} km/h · ${_statusLabel(seg.status)}',
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: color.withAlpha(31),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _statusLabel(seg.status),
              style: GoogleFonts.dmSans(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _roadName(String id) {
    const names = {
      'hamidia_road': 'Hamidia Road',
      'new_market': 'New Market Road',
      'mp_nagar': 'MP Nagar Zone II',
      'arera_colony': 'Arera Colony Road',
      'bittan_market': 'Bittan Market Road',
      'shyamla_hills': 'Shyamla Hills Road',
      'tt_nagar': 'TT Nagar Road',
      'board_office': 'Board Office Road',
      'kolar_road': 'Kolar Road',
      'hoshangabad_road': 'Hoshangabad Road',
    };
    return names[id] ?? id;
  }

  Widget _buildRouteInfo() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Route to $_destination',
            style: GoogleFonts.dmSans(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          _RouteOption(
            label: 'Fastest route',
            time: '18 min',
            detail: 'via Hamidia Rd',
            color: const Color(0xFF1A6BF5),
            isSelected: true,
          ),
          const SizedBox(height: 8),
          _RouteOption(
            label: 'Avoid traffic',
            time: '23 min',
            detail: 'Save 5 min delay · via Kolar Rd',
            color: const Color(0xFF94A3B8),
            isSelected: false,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _launchGoogleMapsNavigation,
              icon: const Icon(Icons.navigation_rounded, size: 16),
              label: Text(
                'Start Navigation',
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A6BF5),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              _isSimulated ? 'Camera + simulation' : 'Based on live + AI data',
              style: GoogleFonts.dmSans(
                fontSize: 11,
                color: AppTheme.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Helper widgets ────────────────────────────────────────────────────────────

class _FloatBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;
  final bool active;

  const _FloatBtn({
    required this.icon,
    required this.onTap,
    required this.tooltip,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: active ? const Color(0xFF1A6BF5) : Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(30),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Icon(
            icon,
            size: 20,
            color: active ? Colors.white : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 11,
            color: const Color(0xFF64748B),
          ),
        ),
      ],
    );
  }
}

class _RouteOption extends StatelessWidget {
  final String label;
  final String time;
  final String detail;
  final Color color;
  final bool isSelected;

  const _RouteOption({
    required this.label,
    required this.time,
    required this.detail,
    required this.color,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFF0F5FF) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected
              ? const Color(0xFF1A6BF5).withAlpha(77)
              : Colors.transparent,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 36,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                Text(
                  detail,
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: GoogleFonts.dmSans(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: isSelected
                  ? const Color(0xFF1A6BF5)
                  : const Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }
}
