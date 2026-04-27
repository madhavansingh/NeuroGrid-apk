import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_navigation.dart';
import '../../core/services/tomtom_traffic_service.dart';

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

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with TickerProviderStateMixin {
  int _navIndex = 1;

  // Map
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

    _fetchTrafficData();

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
    _mapController.dispose();
    _sheetController.dispose();
    super.dispose();
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
          if (i == 2) Navigator.pushNamed(context, '/traffic-screen');
          if (i == 3) Navigator.pushNamed(context, '/ai-assistant-screen');
          if (i == 4) Navigator.pushNamed(context, '/profile-screen');
        },
      ),
    );
  }

  // ── Map widget ────────────────────────────────────────────────────────────

  Widget _buildMap() {
    final visibleMarkers = _cityMarkers
        .where((m) => _activeLayers.contains(m.layer))
        .toList();

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _bhopalCenter,
        initialZoom: 13.0,
        minZoom: 5,
        maxZoom: 18,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all,
        ),
        onTap: (_, __) {
          if (_showAreaDetail) _closeAreaDetail();
        },
      ),
      children: [
        // Satellite base layer (ESRI World Imagery — free, no key)
        TileLayer(
          urlTemplate:
              'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
          userAgentPackageName: 'com.example.neurogrid',
          maxZoom: 18,
        ),

        // OSM labels overlay on top of satellite
        TileLayer(
          urlTemplate:
              'https://{s}.basemaps.cartocdn.com/light_only_labels/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.neurogrid',
          maxZoom: 18,
          tileDisplay: TileDisplay.instantaneous(opacity: 0.55),
        ),

        // ── Animated traffic overlay ──────────────────────────────────────
        if (_activeLayers.contains('Traffic') && !_isLoading)
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

        // Route polylines
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

        // City layer markers
        if (visibleMarkers.isNotEmpty)
          MarkerLayer(
            markers: visibleMarkers.map((m) {
              return Marker(
                point: m.point,
                width: 38,
                height: 38,
                child: GestureDetector(
                  onTap: () => _onMarkerTapped(m),
                  child: Container(
                    decoration: BoxDecoration(
                      color: m.color,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2.5),
                      boxShadow: [
                        BoxShadow(
                          color: m.color.withAlpha(100),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(m.icon, color: Colors.white, size: 16),
                  ),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  // ── Search bar ────────────────────────────────────────────────────────────

  Widget _buildSearchBar() {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(28),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const SizedBox(width: 16),
          Icon(Icons.search_rounded, size: 20, color: AppTheme.textMuted),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _searchController,
              onSubmitted: _onSearchSubmit,
              style: GoogleFonts.dmSans(
                fontSize: 14,
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
              child: Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Icon(
                  Icons.close_rounded,
                  size: 18,
                  color: AppTheme.textMuted,
                ),
              ),
            )
          else
            const SizedBox(width: 12),
        ],
      ),
    );
  }

  // ── Live badge ────────────────────────────────────────────────────────────

  Widget _buildLiveBadge() {
    return AnimatedBuilder(
      animation: _pulseAnim,
      builder: (_, __) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(235),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(18),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: const Color(0xFF16A34A).withOpacity(_pulseAnim.value),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              _updateLabel,
              style: GoogleFonts.dmSans(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
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
      {
        'id': 'Parking',
        'icon': Icons.local_parking_rounded,
        'label': 'Parking',
      },
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: isActive
                      ? const Color(0xFF1A6BF5)
                      : Colors.white.withAlpha(235),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(20),
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
                      size: 14,
                      color: isActive ? Colors.white : AppTheme.textSecondary,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      label,
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isActive ? Colors.white : AppTheme.textSecondary,
                      ),
                    ),
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

  // ── Area detail panel ─────────────────────────────────────────────────────

  Widget _buildAreaDetailPanel() {
    final marker = _selectedMarker;
    if (marker == null) return const SizedBox.shrink();

    // Find traffic status near this marker
    String trafficState = 'Unknown';
    Color trafficColor = AppTheme.textMuted;
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
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(30),
            blurRadius: 24,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 12),
            decoration: BoxDecoration(
              color: marker.color.withAlpha(18),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: marker.color,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(marker.icon, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        marker.title,
                        style: GoogleFonts.dmSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        marker.subtitle,
                        style: GoogleFonts.dmSans(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
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
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      size: 14,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Info row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
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
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
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
                        0.45,
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 24,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: ListView(
        controller: scrollController,
        padding: EdgeInsets.only(bottom: bottomPad + 16),
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 14),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
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
          // City status headline
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
          const SizedBox(height: 14),

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
          const SizedBox(height: 16),

          // Road segment list
          Text(
            'Live Road Conditions',
            style: GoogleFonts.dmSans(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppTheme.textSecondary,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 10),
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
  const _FloatBtn({
    required this.icon,
    required this.onTap,
    required this.tooltip,
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
            color: Colors.white,
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
            color: const Color(0xFF475569),
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
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withAlpha(15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(height: 4),
            Text(
              value,
              style: GoogleFonts.dmSans(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.dmSans(
                fontSize: 10,
                color: AppTheme.textMuted,
              ),
            ),
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: valueColor),
            const SizedBox(width: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: GoogleFonts.dmSans(
                    fontSize: 10,
                    color: AppTheme.textMuted,
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
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

class _ActionBtn extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withAlpha(18),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withAlpha(50)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.dmSans(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
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