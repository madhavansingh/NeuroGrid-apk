import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mbx;
import '../../core/config/app_config.dart';
import '../../providers/location_provider.dart';
import '../../widgets/app_navigation.dart';
import '../../widgets/voice_fab.dart';
import '../../core/services/tomtom_traffic_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ── Animated traffic polyline ─────────────────────────────────────────────────
class _AnimatedTrafficPolyline extends StatefulWidget {
  final TrafficSegment segment;
  final Color targetColor;
  final double strokeWidth;
  final double flowOffset;

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
        final pulse = 0.72 + 0.20 * sin(widget.flowOffset * 2 * pi);
        return PolylineLayer(
          polylines: [
            Polyline(
              points: widget.segment.points,
              color: color.withAlpha(46),
              strokeWidth: widget.strokeWidth + 5,
              strokeCap: StrokeCap.round,
              strokeJoin: StrokeJoin.round,
            ),
            Polyline(
              points: widget.segment.points,
              color: color.withValues(alpha: pulse),
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

// ── City layer data ───────────────────────────────────────────────────────────

class _CityMarker {
  final String layer;
  final LatLng point;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _CityMarker({
    required this.layer,
    required this.point,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });
}

// ── Main screen ───────────────────────────────────────────────────────────────

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> with TickerProviderStateMixin {
  int _navIndex = 1;

  // Mapbox
  mbx.MapboxMap? _mapboxMap;
  static String _mapboxToken = '';

  // flutter_map controller (kept for polyline/marker compat — not used as base map)
  late final MapController _mapController;

  // Active layers
  final Set<String> _activeLayers = {'Traffic', 'Alerts'};

  // Traffic data
  List<TrafficSegment> _segments = [];
  bool _isSimulated = false;
  bool _isLoading = true;

  // Search / route
  final TextEditingController _searchController = TextEditingController();
  bool _showRouteResult = false;
  String _destination = '';

  // Area detail panel
  bool _showAreaDetail = false;
  _CityMarker? _selectedMarker;

  // Bottom sheet
  late DraggableScrollableController _sheetController;

  // ── Animation controllers ─────────────────────────────────────────────────
  late AnimationController _flowController;
  late Animation<double> _flowAnim;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnim;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  late AnimationController _routeDrawController;

  late AnimationController _panelController;
  late Animation<Offset> _panelSlide;

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

  // City layer markers
  static const List<_CityMarker> _cityMarkers = [
    // Alerts
    _CityMarker(
      layer: 'Alerts',
      point: LatLng(23.2368, 77.4011),
      title: 'New Market',
      subtitle: 'Road closure · Diversion active',
      icon: Icons.warning_amber_rounded,
      color: Color(0xFFEF4444),
    ),
    _CityMarker(
      layer: 'Alerts',
      point: LatLng(23.2687, 77.4018),
      title: 'Hamidia Road',
      subtitle: 'Accident reported · Slow traffic',
      icon: Icons.warning_amber_rounded,
      color: Color(0xFFEF4444),
    ),
    _CityMarker(
      layer: 'Alerts',
      point: LatLng(23.2332, 77.4272),
      title: 'MP Nagar',
      subtitle: 'Event traffic · Expect delays',
      icon: Icons.info_outline_rounded,
      color: Color(0xFFF59E0B),
    ),
    // Parking
    _CityMarker(
      layer: 'Parking',
      point: LatLng(23.2415, 77.4072),
      title: 'TT Nagar Parking',
      subtitle: '12 spots available',
      icon: Icons.local_parking_rounded,
      color: Color(0xFF3B82F6),
    ),
    _CityMarker(
      layer: 'Parking',
      point: LatLng(23.2156, 77.4394),
      title: 'Arera Colony P2',
      subtitle: '3 spots · Almost full',
      icon: Icons.local_parking_rounded,
      color: Color(0xFFF59E0B),
    ),
    _CityMarker(
      layer: 'Parking',
      point: LatLng(23.2530, 77.4350),
      title: 'Shyamla Hills Lot',
      subtitle: '28 spots available',
      icon: Icons.local_parking_rounded,
      color: Color(0xFF22C55E),
    ),
    // Waste
    _CityMarker(
      layer: 'Waste',
      point: LatLng(23.2200, 77.4500),
      title: 'Bittan Market Bin',
      subtitle: '87% full · Pickup due',
      icon: Icons.delete_outline_rounded,
      color: Color(0xFF8B5CF6),
    ),
    _CityMarker(
      layer: 'Waste',
      point: LatLng(23.2550, 77.4370),
      title: 'Shyamla Hills Bin',
      subtitle: '34% full · Normal',
      icon: Icons.delete_outline_rounded,
      color: Color(0xFF22C55E),
    ),
    // Camera
    _CityMarker(
      layer: 'Camera',
      point: LatLng(23.2599, 77.4126),
      title: 'City Center Cam',
      subtitle: 'Live · HD · Active',
      icon: Icons.videocam_rounded,
      color: Color(0xFF0EA5E9),
    ),
    _CityMarker(
      layer: 'Camera',
      point: LatLng(23.2480, 77.4060),
      title: 'Hamidia Junction Cam',
      subtitle: 'Live · HD · Active',
      icon: Icons.videocam_rounded,
      color: Color(0xFF0EA5E9),
    ),
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

    // Token already loaded by AppConfig.load() in main() — synchronous, instant.
    _mapboxToken = AppConfig.mapboxToken;
    if (_mapboxToken.isNotEmpty) {
      mbx.MapboxOptions.setAccessToken(_mapboxToken);
    }

    // Fetch real GPS on map open
    _flowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
    _flowAnim = Tween<double>(begin: 0.0, end: 1.0).animate(_flowController);

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);

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

    _panelController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 360),
    );
    _panelSlide = Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _panelController, curve: Curves.easeOutCubic),
        );

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
    _panelController.dispose();
    _updateTimer?.cancel();
    _searchController.dispose();
    _sheetController.dispose();
    super.dispose();
  }

  void _onMapCreated(mbx.MapboxMap mapboxMap) {
    // Kept for API compatibility but no longer used — using flutter_map instead.
  }

  Future<void> _flyToUserLocation() async {
    final loc = ref.read(locationProvider);
    final lat =
        loc.hasLocation ? loc.latitude! : _bhopalCenter.latitude;
    final lng =
        loc.hasLocation ? loc.longitude! : _bhopalCenter.longitude;
    // Animated move via flutter_map controller
    _mapController.move(LatLng(lat, lng), 15.0);
  }

  // ── Data fetching ─────────────────────────────────────────────────────────

  Future<void> _fetchTrafficData() async {
    final result = await TomTomTrafficService.instance.fetchBhopalTraffic();
    if (!mounted) return;

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

    _fadeController.forward(from: _fadeController.value);
  }

  // ── Map helpers ───────────────────────────────────────────────────────────

  Future<void> _goToMyLocation() async {
    // Always prefer locationProvider (already cached); re-fly to real GPS
    await ref.read(locationProvider.notifier).fetchLocation();
    await _flyToUserLocation();
  }

  void _onMarkerTapped(_CityMarker marker) {
    setState(() {
      _selectedMarker = marker;
      _showAreaDetail = true;
    });
    _panelController.forward(from: 0);
    // Collapse bottom sheet when panel opens
    _sheetController.animateTo(
      0.10,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  void _closeAreaDetail() {
    _panelController.reverse().then((_) {
      if (mounted) setState(() => _showAreaDetail = false);
    });
  }

  void _onSearchSubmit(String value) {
    if (value.trim().isEmpty) return;
    setState(() {
      _destination = value.trim();
      _showRouteResult = true;
      _secondsSinceUpdate = 0;
      _showAreaDetail = false;
    });
    _panelController.reverse();
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
    final topPad = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: Colors.white,
      extendBody: true,
      body: Stack(
        children: [
          // ── Full-screen map ───────────────────────────────────────────────
          Positioned.fill(child: _buildMap()),

          // ── Top search bar ────────────────────────────────────────────────
          Positioned(
            top: topPad + 12,
            left: 16,
            right: 16,
            child: _buildSearchBar(),
          ),

          // ── Live badge ────────────────────────────────────────────────────
          Positioned(
            top: topPad + 76,
            left: 0,
            right: 0,
            child: Center(child: _buildLiveBadge()),
          ),

          // ── Simulation badge ──────────────────────────────────────────────
          if (_isSimulated)
            Positioned(
              top: topPad + 110,
              left: 0,
              right: 0,
              child: Center(child: _buildSimulationBadge()),
            ),

          // ── Layer toggle strip ────────────────────────────────────────────
          Positioned(
            top: topPad + (_isSimulated ? 144 : 110),
            left: 0,
            right: 0,
            child: _buildLayerStrip(),
          ),

          // ── Floating right controls ───────────────────────────────────────
          Positioned(
            right: 16,
            bottom: bottomPad + 120,
            child: _buildFloatingControls(),
          ),

          // ── Contextual area detail panel ──────────────────────────────────
          if (_showAreaDetail)
            Positioned(
              left: 16,
              right: 16,
              bottom: bottomPad + 120,
              child: SlideTransition(
                position: _panelSlide,
                child: _buildAreaDetailPanel(),
              ),
            ),

          // ── Draggable bottom sheet ────────────────────────────────────────
          DraggableScrollableSheet(
            controller: _sheetController,
            initialChildSize: 0.14,
            minChildSize: 0.12,
            maxChildSize: 0.76,
            snap: true,
            snapSizes: const [0.14, 0.46, 0.76],
            builder: (context, scrollController) =>
                _buildBottomSheet(scrollController, bottomPad),
          ),
        ],
      ),
      floatingActionButton: const VoiceFab(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: AppNavigation(
        currentIndex: _navIndex,
        onTap: (i) {
          setState(() => _navIndex = i);
          if (i == 0) Navigator.pushNamed(context, '/home-screen');
          if (i == 2) Navigator.pushNamed(context, '/traffic-screen');
          if (i == 3) Navigator.pushNamed(context, '/ai-assistant-screen');
          if (i == 4) Navigator.pushNamed(context, '/profile-screen');
        },
      ),
    );
  }

  // ── Map widget (OSM tiles + interactive FlutterMap) ──────────────────────

  Widget _buildMap() {
    // Always start at Bhopal — device GPS is only used via the "My Location" button.
    // Using locationProvider here caused the map to open at the device/emulator
    // default GPS (e.g. Mountain View, CA) which is incorrect for this city app.
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _bhopalCenter,
        initialZoom: 14.5,
        minZoom: 10.0,
        maxZoom: 19.0,
        onTap: (_, __) {
          if (_showAreaDetail) _closeAreaDetail();
        },
      ),
      children: [
        // ── Base tile layer (OSM — loads instantly, no token needed) ─────────
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.neurogrid',
          maxZoom: 19,
          tileDisplay: const TileDisplay.fadeIn(
            duration: Duration(milliseconds: 150),
          ),
        ),

        // ── Animated traffic polylines ────────────────────────────────────────
        if (_activeLayers.contains('Traffic') && !_isLoading)
          AnimatedBuilder(
            animation: Listenable.merge([_flowAnim, _fadeAnim]),
            builder: (_, __) => Opacity(
              opacity: _fadeAnim.value,
              child: Stack(
                children: _segments
                    .map((seg) => _AnimatedTrafficPolyline(
                          segment: seg,
                          targetColor: _statusColor(seg.status),
                          strokeWidth: 6.0,
                          flowOffset: _flowAnim.value,
                        ))
                    .toList(),
              ),
            ),
          ),

        // ── Route polylines ───────────────────────────────────────────────────
        if (_showRouteResult)
          PolylineLayer(polylines: [
            Polyline(
                points: _altRoute,
                color: const Color(0xFF94A3B8),
                strokeWidth: 5.0,
                strokeCap: StrokeCap.round),
            Polyline(
                points: _mainRoute,
                color: const Color(0xFF1A6BF5),
                strokeWidth: 8.0,
                strokeCap: StrokeCap.round),
          ]),

        // ── User location dot (shown only if GPS is within Bhopal area) ───────
        Builder(builder: (_) {
          final loc = ref.watch(locationProvider);
          if (!loc.hasLocation) return const SizedBox.shrink();
          final lat = loc.latitude!;
          final lng = loc.longitude!;
          // Only show GPS dot if within ~50 km of Bhopal center
          final dlat = lat - _bhopalCenter.latitude;
          final dlng = lng - _bhopalCenter.longitude;
          final isNearBhopal = (dlat * dlat + dlng * dlng) < 0.25; // ~50 km
          if (!isNearBhopal) return const SizedBox.shrink();
          return MarkerLayer(markers: [
            Marker(
              point: LatLng(lat, lng),
              width: 20,
              height: 20,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1A6BF5),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1A6BF5).withAlpha(80),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
            ),
          ]);
        }),

        // ── City markers ──────────────────────────────────────────────────────
        MarkerLayer(
          markers: _cityMarkers
              .where((m) => _activeLayers.contains(m.layer))
              .map((m) => Marker(
                    point: m.point,
                    width: 48,
                    height: 56,
                    child: _PinMarker(
                        color: m.color,
                        icon: m.icon,
                        onTap: () => _onMarkerTapped(m)),
                  ))
              .toList(),
        ),
      ],
    );
  }

  // ── Search bar ────────────────────────────────────────────────────────────

  Widget _buildSearchBar() {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(36),
            blurRadius: 24,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: const Color(0xFF1A6BF5).withAlpha(12),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const SizedBox(width: 18),
          const Icon(Icons.search_rounded, size: 22, color: Color(0xFF1A6BF5)),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _searchController,
              onSubmitted: _onSearchSubmit,
              style: GoogleFonts.dmSans(
                fontSize: 15,
                color: const Color(0xFF0F172A),
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                hintText: 'Search destination in Bhopal…',
                hintStyle: GoogleFonts.dmSans(
                  fontSize: 15,
                  color: const Color(0xFF94A3B8),
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
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close_rounded,
                    size: 15, color: Color(0xFF64748B)),
              ),
            )
          else
            const SizedBox(width: 16),
        ],
      ),
    );
  }

  // ── Live badge ────────────────────────────────────────────────────────────

  Widget _buildLiveBadge() {
    return AnimatedBuilder(
      animation: _pulseAnim,
      builder: (_, child) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(20),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8, height: 8,
              decoration: BoxDecoration(
                color: const Color(0xFF16A34A)
                    .withValues(alpha: _pulseAnim.value),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 7),
            Text(
              '● Live  ·  $_updateLabel',
              style: GoogleFonts.dmSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1E293B),
              ),
            ),
          ],
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

  // ── Layer toggle strip ────────────────────────────────────────────────────

  Widget _buildLayerStrip() {
    const layers = [
      {'id': 'Traffic', 'icon': Icons.traffic_rounded, 'label': 'Traffic'},
      {'id': 'Alerts', 'icon': Icons.warning_amber_rounded, 'label': 'Alerts'},
      {'id': 'Parking', 'icon': Icons.local_parking_rounded, 'label': 'Parking'},
      {'id': 'Waste', 'icon': Icons.delete_outline_rounded, 'label': 'Waste'},
      {'id': 'Camera', 'icon': Icons.videocam_rounded, 'label': 'Cams'},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: layers.map((layer) {
          final id = layer['id'] as String;
          final icon = layer['icon'] as IconData;
          final label = layer['label'] as String;
          final isActive = _activeLayers.contains(id);
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  if (isActive) {
                    _activeLayers.remove(id);
                  } else {
                    _activeLayers.add(id);
                  }
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                decoration: BoxDecoration(
                  color: isActive
                      ? const Color(0xFF1A6BF5)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: isActive
                          ? const Color(0xFF1A6BF5).withAlpha(50)
                          : Colors.black.withAlpha(20),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 15,
                        color: isActive ? Colors.white : const Color(0xFF475569)),
                    const SizedBox(width: 6),
                    Text(label,
                        style: GoogleFonts.dmSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isActive ? Colors.white : const Color(0xFF475569),
                        )),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Floating controls ─────────────────────────────────────────────────────

  Widget _buildFloatingControls() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _FloatBtn(
          icon: Icons.my_location_rounded,
          onTap: _goToMyLocation,
          tooltip: 'My Location',
          accent: true,
        ),
        const SizedBox(height: 8),
        _FloatBtn(
          icon: Icons.add_rounded,
          onTap: () {
            final cur = _mapController.camera.zoom;
            _mapController.move(_mapController.camera.center, cur + 1);
          },
          tooltip: 'Zoom In',
        ),
        const SizedBox(height: 4),
        _FloatBtn(
          icon: Icons.remove_rounded,
          onTap: () {
            final cur = _mapController.camera.zoom;
            _mapController.move(_mapController.camera.center, cur - 1);
          },
          tooltip: 'Zoom Out',
        ),
        const SizedBox(height: 8),
        _FloatBtn(
          icon: Icons.layers_rounded,
          onTap: () {},
          tooltip: 'Layers',
        ),
      ],
    );
  }

  // ── Area detail panel ─────────────────────────────────────────────────────

  Widget _buildAreaDetailPanel() {
    final marker = _selectedMarker;
    if (marker == null) return const SizedBox.shrink();

    String trafficState = 'Unknown';
    Color trafficColor = const Color(0xFF94A3B8);
    if (_segments.isNotEmpty) {
      final nearest = _segments.reduce((a, b) {
        final da = _distanceTo(a.points.first, marker.point);
        final db = _distanceTo(b.points.first, marker.point);
        return da < db ? a : b;
      });
      trafficState = _statusLabel(nearest.status);
      trafficColor = _statusColor(nearest.status);
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(36),
            blurRadius: 28,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: marker.color.withAlpha(20),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 14, 14),
            decoration: BoxDecoration(
              color: marker.color.withAlpha(15),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 42, height: 42,
                  decoration: BoxDecoration(
                    color: marker.color,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: marker.color.withAlpha(80),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(marker.icon, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        marker.title,
                        style: GoogleFonts.dmSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        marker.subtitle,
                        style: GoogleFonts.dmSans(
                          fontSize: 13,
                          color: const Color(0xFF64748B),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: _closeAreaDetail,
                  child: Container(
                    width: 32, height: 32,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF1F5F9),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      size: 16,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Info row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              children: [
                _InfoChip(
                  icon: Icons.traffic_rounded,
                  label: 'Traffic',
                  value: trafficState,
                  valueColor: trafficColor,
                ),
                const SizedBox(width: 10),
                _InfoChip(
                  icon: Icons.layers_rounded,
                  label: 'Layer',
                  value: marker.layer,
                  valueColor: marker.color,
                ),
              ],
            ),
          ),

          // Quick actions
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: _ActionBtn(
                    icon: Icons.navigation_rounded,
                    label: 'Navigate',
                    color: const Color(0xFF1A6BF5),
                    onTap: () async {
                      final encodedTo = Uri.encodeComponent(
                        '${marker.title}, Bhopal',
                      );
                      final uri = Uri.parse(
                        'https://www.google.com/maps/dir/?api=1&destination=$encodedTo&travelmode=driving',
                      );
                      try {
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(
                            uri,
                            mode: LaunchMode.externalApplication,
                          );
                        }
                      } catch (_) {}
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ActionBtn(
                    icon: Icons.info_outline_rounded,
                    label: 'Details',
                    color: const Color(0xFF64748B),
                    onTap: () {
                      _closeAreaDetail();
                      _sheetController.animateTo(
                        0.46,
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeOutCubic,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  double _distanceTo(LatLng a, LatLng b) {
    final dlat = a.latitude - b.latitude;
    final dlng = a.longitude - b.longitude;
    return sqrt(dlat * dlat + dlng * dlng);
  }

  // ── Bottom sheet ──────────────────────────────────────────────────────────

  Widget _buildBottomSheet(
    ScrollController scrollController,
    double bottomPad,
  ) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 32,
            offset: Offset(0, -6),
          ),
        ],
      ),
      child: ListView(
        controller: scrollController,
        padding: EdgeInsets.only(bottom: bottomPad + 20),
        children: [
          // ── Drag handle ──────────────────────────────────────────────────
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 16),
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          if (!_showRouteResult)
            _buildCityIntelligenceSummary()
          else
            _buildRouteInfo(),
        ],
      ),
    );
  }

  Widget _buildCityIntelligenceSummary() {
    final heavyCount =
        _segments.where((s) => s.status == TrafficStatus.heavy).length;
    final modCount =
        _segments.where((s) => s.status == TrafficStatus.moderate).length;

    String headline;
    Color headlineColor;
    IconData headlineIcon;
    if (heavyCount >= 3) {
      headline = 'Heavy traffic near MP Nagar & New Market';
      headlineColor = const Color(0xFFDC2626);
      headlineIcon = Icons.warning_rounded;
    } else if (heavyCount >= 1 || modCount >= 3) {
      headline = 'Moderate congestion on key routes';
      headlineColor = const Color(0xFFF59E0B);
      headlineIcon = Icons.info_rounded;
    } else {
      headline = 'Traffic flowing smoothly across Bhopal';
      headlineColor = const Color(0xFF16A34A);
      headlineIcon = Icons.check_circle_rounded;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // City status headline
          Row(
            children: [
              Container(
                width: 34, height: 34,
                decoration: BoxDecoration(
                  color: headlineColor.withAlpha(20),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(headlineIcon, size: 18, color: headlineColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  headline,
                  style: GoogleFonts.dmSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Traffic legend
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

          // City stats row
          Row(
            children: [
              _StatCard(
                icon: Icons.warning_amber_rounded,
                value: '3',
                label: 'Alerts',
                color: const Color(0xFFEF4444),
              ),
              const SizedBox(width: 10),
              _StatCard(
                icon: Icons.local_parking_rounded,
                value: '43',
                label: 'Parking',
                color: const Color(0xFF3B82F6),
              ),
              const SizedBox(width: 10),
              _StatCard(
                icon: Icons.delete_outline_rounded,
                value: '2',
                label: 'Pickups',
                color: const Color(0xFF8B5CF6),
              ),
              const SizedBox(width: 10),
              _StatCard(
                icon: Icons.videocam_rounded,
                value: '2',
                label: 'Cams',
                color: const Color(0xFF0EA5E9),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Road segment list
          Text(
            'LIVE ROAD CONDITIONS',
            style: GoogleFonts.dmSans(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF94A3B8),
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 12),
          if (!_isLoading)
            ..._segments.take(5).map((seg) => _buildSegmentRow(seg)),
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor:
                        AlwaysStoppedAnimation(Color(0xFF1A6BF5))),
              ),
            ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.info_outline_rounded,
                  size: 13, color: Color(0xFF94A3B8)),
              const SizedBox(width: 5),
              Text(
                _isSimulated
                    ? 'Camera + AI simulation data'
                    : 'Based on live camera + AI data',
                style: GoogleFonts.dmSans(
                    fontSize: 12, color: const Color(0xFF94A3B8)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentRow(TrafficSegment seg) {
    final color = _statusColor(seg.status);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          TweenAnimationBuilder<Color?>(
            tween: ColorTween(begin: color, end: color),
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeInOut,
            builder: (_, c, child) => Container(
              width: 4, height: 36,
              decoration: BoxDecoration(
                color: c ?? color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _roadName(seg.id),
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                Text(
                  '${seg.currentSpeed.toStringAsFixed(0)} km/h  ·  ${_statusLabel(seg.status)}',
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: color.withAlpha(28),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              _statusLabel(seg.status),
              style: GoogleFonts.dmSans(
                fontSize: 12,
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
          Row(
            children: [
              const Icon(Icons.navigation_rounded,
                  size: 18, color: Color(0xFF1A6BF5)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Route to $_destination',
                  style: GoogleFonts.dmSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _RouteOption(
            label: 'Fastest route',
            time: '18 min',
            detail: 'via Hamidia Rd',
            delay: null,
            color: const Color(0xFF1A6BF5),
            isSelected: true,
          ),
          const SizedBox(height: 10),
          _RouteOption(
            label: 'Avoid traffic',
            time: '23 min',
            detail: 'via Kolar Rd',
            delay: '+5 min delay saved',
            color: const Color(0xFF94A3B8),
            isSelected: false,
          ),
          const SizedBox(height: 20),
          // Start Navigation button (gradient)
          GestureDetector(
            onTap: _launchGoogleMapsNavigation,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1A6BF5), Color(0xFF3A8BFF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1A6BF5).withAlpha(70),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.navigation_rounded,
                      size: 18, color: Colors.white),
                  const SizedBox(width: 10),
                  Text('Start Navigation',
                      style: GoogleFonts.dmSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      )),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.open_in_new_rounded,
                    size: 12, color: Color(0xFF94A3B8)),
                const SizedBox(width: 4),
                Text(
                  'Opens Google Maps',
                  style: GoogleFonts.dmSans(
                      fontSize: 12, color: const Color(0xFF94A3B8)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Helper widgets ────────────────────────────────────────────────────────────

class _FloatBtn extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;
  final bool accent;
  const _FloatBtn({
    required this.icon,
    required this.onTap,
    required this.tooltip,
    this.accent = false,
  });
  @override
  State<_FloatBtn> createState() => _FloatBtnState();
}

class _FloatBtnState extends State<_FloatBtn>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 90));
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      child: GestureDetector(
        onTapDown: (_) => _c.forward(),
        onTapUp: (_) {
          _c.reverse();
          widget.onTap();
        },
        onTapCancel: () => _c.reverse(),
        child: AnimatedBuilder(
          animation: _c,
          builder: (_, child) =>
              Transform.scale(scale: 1.0 - _c.value * 0.08, child: child),
          child: Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: widget.accent
                  ? const Color(0xFF1A6BF5)
                  : Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: widget.accent
                      ? const Color(0xFF1A6BF5).withAlpha(70)
                      : Colors.black.withAlpha(30),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(widget.icon, size: 22,
                color: widget.accent
                    ? Colors.white
                    : const Color(0xFF334155)),
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
          width: 10, height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(label,
            style: GoogleFonts.dmSans(
              fontSize: 13,
              color: const Color(0xFF475569),
            )),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withAlpha(18),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(height: 5),
            Text(value,
                style: GoogleFonts.dmSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: color,
                )),
            Text(label,
                style: GoogleFonts.dmSans(
                  fontSize: 11,
                  color: const Color(0xFF64748B),
                )),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color valueColor;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: valueColor.withAlpha(10),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: valueColor.withAlpha(30)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: valueColor),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: valueColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionBtn extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  State<_ActionBtn> createState() => _ActionBtnState();
}

class _ActionBtnState extends State<_ActionBtn>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 80));
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _c.forward(),
      onTapUp: (_) {
        _c.reverse();
        widget.onTap();
      },
      onTapCancel: () => _c.reverse(),
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, child) =>
            Transform.scale(scale: 1.0 - _c.value * 0.05, child: child),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 13),
          decoration: BoxDecoration(
            color: widget.color.withAlpha(18),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: widget.color.withAlpha(50)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(widget.icon, size: 16, color: widget.color),
              const SizedBox(width: 7),
              Text(
                widget.label,
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: widget.color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RouteOption extends StatelessWidget {
  final String label;
  final String time;
  final String detail;
  final String? delay;
  final Color color;
  final bool isSelected;

  const _RouteOption({
    required this.label,
    required this.time,
    required this.detail,
    this.delay,
    required this.color,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFF0F5FF) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isSelected
              ? const Color(0xFF1A6BF5).withAlpha(77)
              : Colors.transparent,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 4, height: 42,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1E293B),
                    )),
                const SizedBox(height: 2),
                Text(detail,
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      color: const Color(0xFF64748B),
                    )),
                if (delay != null) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(delay!,
                        style: GoogleFonts.dmSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF059669),
                        )),
                  ),
                ],
              ],
            ),
          ),
          Text(time,
              style: GoogleFonts.dmSans(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: isSelected
                    ? const Color(0xFF1A6BF5)
                    : const Color(0xFF94A3B8),
              )),
        ],
      ),
    );
  }
}

// ── Premium animated pin marker ───────────────────────────────────────────────

class _PinMarker extends StatefulWidget {
  final Color color;
  final IconData icon;
  final VoidCallback onTap;

  const _PinMarker({
    required this.color,
    required this.icon,
    required this.onTap,
  });

  @override
  State<_PinMarker> createState() => _PinMarkerState();
}

class _PinMarkerState extends State<_PinMarker>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 100));
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _c.forward(),
      onTapUp: (_) {
        _c.reverse();
        widget.onTap();
      },
      onTapCancel: () => _c.reverse(),
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, child) =>
            Transform.scale(scale: 1.0 - _c.value * 0.12, child: child),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Pin head
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: widget.color,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white, width: 2.5),
                boxShadow: [
                  BoxShadow(
                    color: widget.color.withAlpha(130),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                  BoxShadow(
                    color: widget.color.withAlpha(50),
                    blurRadius: 20,
                    spreadRadius: 2,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(widget.icon, color: Colors.white, size: 18),
            ),
            // Pin tail
            Container(
              width: 3, height: 10,
              decoration: BoxDecoration(
                color: widget.color,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(3),
                  bottomRight: Radius.circular(3),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}