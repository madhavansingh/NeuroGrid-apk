import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MapCanvasWidget extends StatefulWidget {
  final Set<String> activeLayers;
  final String mapStyle;
  final Function(Map<String, dynamic>) onAreaTapped;
  final void Function(MapController)? onMapCreated;

  const MapCanvasWidget({
    super.key,
    required this.activeLayers,
    required this.mapStyle,
    required this.onAreaTapped,
    this.onMapCreated,
  });

  @override
  State<MapCanvasWidget> createState() => _MapCanvasWidgetState();
}

class _MapCanvasWidgetState extends State<MapCanvasWidget> {
  late final MapController _mapController;

  // Bhopal, Madhya Pradesh center
  static const LatLng _bhopalCenter = LatLng(23.2599, 77.4126);

  // Real Bhopal area data
  static const List<Map<String, dynamic>> _bhopalAreas = [
    {
      'name': 'MP Nagar',
      'lat': 23.2332,
      'lng': 77.4272,
      'congestion': 'moderate',
      'alerts': 1,
      'parking': 'Limited',
    },
    {
      'name': 'New Market',
      'lat': 23.2368,
      'lng': 77.4011,
      'congestion': 'heavy',
      'alerts': 3,
      'parking': 'Full',
    },
    {
      'name': 'Hamidia Road',
      'lat': 23.2687,
      'lng': 77.4018,
      'congestion': 'heavy',
      'alerts': 2,
      'parking': 'Full',
    },
    {
      'name': 'Arera Colony',
      'lat': 23.2156,
      'lng': 77.4394,
      'congestion': 'moderate',
      'alerts': 1,
      'parking': 'Limited',
    },
    {
      'name': 'TT Nagar',
      'lat': 23.2415,
      'lng': 77.4072,
      'congestion': 'moderate',
      'alerts': 1,
      'parking': 'Limited',
    },
    {
      'name': 'Shyamla Hills',
      'lat': 23.2530,
      'lng': 77.4350,
      'congestion': 'clear',
      'alerts': 0,
      'parking': 'Available',
    },
    {
      'name': 'Bittan Market',
      'lat': 23.2200,
      'lng': 77.4500,
      'congestion': 'clear',
      'alerts': 0,
      'parking': 'Available',
    },
  ];

  // Traffic polylines for Bhopal roads
  static final List<Map<String, dynamic>> _trafficRoutes = [
    {
      'points': [
        LatLng(23.2332, 77.4272),
        LatLng(23.2368, 77.4200),
        LatLng(23.2368, 77.4011),
      ],
      'congestion': 'heavy',
    },
    {
      'points': [
        LatLng(23.2687, 77.4018),
        LatLng(23.2550, 77.4050),
        LatLng(23.2415, 77.4072),
      ],
      'congestion': 'heavy',
    },
    {
      'points': [
        LatLng(23.2415, 77.4072),
        LatLng(23.2332, 77.4272),
        LatLng(23.2156, 77.4394),
      ],
      'congestion': 'moderate',
    },
    {
      'points': [
        LatLng(23.2530, 77.4350),
        LatLng(23.2415, 77.4300),
        LatLng(23.2200, 77.4500),
      ],
      'congestion': 'clear',
    },
    {
      'points': [
        LatLng(23.2599, 77.4126),
        LatLng(23.2530, 77.4350),
        LatLng(23.2415, 77.4072),
      ],
      'congestion': 'moderate',
    },
  ];

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onMapCreated?.call(_mapController);
    });
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  Color _congestionColor(String congestion) {
    switch (congestion) {
      case 'heavy':
        return const Color(0xFFEF4444);
      case 'moderate':
        return const Color(0xFFF59E0B);
      case 'clear':
        return const Color(0xFF22C55E);
      default:
        return const Color(0xFF22C55E);
    }
  }

  Color _markerColor(String congestion) {
    switch (congestion) {
      case 'heavy':
        return const Color(0xFFEF4444);
      case 'moderate':
        return const Color(0xFFF59E0B);
      case 'clear':
        return const Color(0xFF22C55E);
      default:
        return const Color(0xFF22C55E);
    }
  }

  String _tileUrl() {
    if (widget.mapStyle == 'Satellite') {
      return 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}';
    }
    // CartoDB Positron — clean light neutral, matches app design system
    return 'https://a.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png';
  }

  @override
  Widget build(BuildContext context) {
    final showTraffic = widget.activeLayers.contains('Traffic');

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _bhopalCenter,
        initialZoom: 12.5,
        minZoom: 5,
        maxZoom: 18,
      ),
      children: [
        // Base tile layer
        TileLayer(
          urlTemplate: _tileUrl(),
          userAgentPackageName: 'com.example.neurogrid',
          maxZoom: 18,
        ),

        // Traffic polyline layer
        if (showTraffic)
          PolylineLayer(
            polylines: _trafficRoutes.map((route) {
              return Polyline(
                points: List<LatLng>.from(route['points'] as List),
                color: _congestionColor(route['congestion'] as String),
                strokeWidth: 5.0,
              );
            }).toList(),
          ),

        // Marker layer
        MarkerLayer(
          markers: _bhopalAreas.map((area) {
            final congestion = area['congestion'] as String;
            return Marker(
              point: LatLng(area['lat'] as double, area['lng'] as double),
              width: 36,
              height: 36,
              child: GestureDetector(
                onTap: () => widget.onAreaTapped(area),
                child: Container(
                  decoration: BoxDecoration(
                    color: _markerColor(congestion),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: _markerColor(congestion).withAlpha(100),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.location_on_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
