import 'dart:async';
import 'dart:math';
import 'package:dio/dio.dart';
import 'package:latlong2/latlong.dart';

/// Traffic status derived from speed ratio
enum TrafficStatus { smooth, moderate, heavy }

/// A single road segment with live traffic data
class TrafficSegment {
  final String id;
  final List<LatLng> points;
  final double currentSpeed; // km/h
  final double freeFlowSpeed; // km/h
  final double congestionLevel; // 0.0 – 1.0
  final TrafficStatus status;
  final bool isSimulated;

  const TrafficSegment({
    required this.id,
    required this.points,
    required this.currentSpeed,
    required this.freeFlowSpeed,
    required this.congestionLevel,
    required this.status,
    required this.isSimulated,
  });

  /// Derive status from speed ratio (currentSpeed / freeFlowSpeed)
  static TrafficStatus statusFromRatio(double ratio) {
    if (ratio >= 0.75) return TrafficStatus.smooth;
    if (ratio >= 0.45) return TrafficStatus.moderate;
    return TrafficStatus.heavy;
  }
}

/// Result returned by the service after a fetch cycle
class TrafficResult {
  final List<TrafficSegment> segments;
  final bool isSimulated;
  final DateTime fetchedAt;

  const TrafficResult({
    required this.segments,
    required this.isSimulated,
    required this.fetchedAt,
  });
}

/// Bhopal road segments — each entry has a representative point used to
/// query TomTom and a list of LatLng points that draw the road on the map.
class _BhopalRoad {
  final String id;
  final String name;
  final LatLng queryPoint; // sent to TomTom API
  final List<LatLng> path; // drawn on map

  const _BhopalRoad({
    required this.id,
    required this.name,
    required this.queryPoint,
    required this.path,
  });
}

class TomTomTrafficService {
  TomTomTrafficService._();
  static final TomTomTrafficService instance = TomTomTrafficService._();

  static const String _baseUrl = 'https://api.tomtom.com/traffic/services/4';
  static const int _zoom = 13;

  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 8),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );

  // ── Bhopal road definitions ──────────────────────────────────────────────
  static const List<_BhopalRoad> _roads = [
    _BhopalRoad(
      id: 'hamidia_road',
      name: 'Hamidia Road',
      queryPoint: LatLng(23.2650, 77.4030),
      path: [
        LatLng(23.2687, 77.4018),
        LatLng(23.2665, 77.4022),
        LatLng(23.2650, 77.4030),
        LatLng(23.2620, 77.4045),
        LatLng(23.2590, 77.4060),
      ],
    ),
    _BhopalRoad(
      id: 'new_market',
      name: 'New Market Road',
      queryPoint: LatLng(23.2380, 77.4025),
      path: [
        LatLng(23.2368, 77.4011),
        LatLng(23.2375, 77.4018),
        LatLng(23.2380, 77.4025),
        LatLng(23.2395, 77.4040),
        LatLng(23.2410, 77.4055),
      ],
    ),
    _BhopalRoad(
      id: 'mp_nagar',
      name: 'MP Nagar Zone II',
      queryPoint: LatLng(23.2350, 77.4290),
      path: [
        LatLng(23.2332, 77.4272),
        LatLng(23.2345, 77.4282),
        LatLng(23.2350, 77.4290),
        LatLng(23.2370, 77.4310),
        LatLng(23.2390, 77.4330),
      ],
    ),
    _BhopalRoad(
      id: 'arera_colony',
      name: 'Arera Colony Road',
      queryPoint: LatLng(23.2175, 77.4410),
      path: [
        LatLng(23.2156, 77.4394),
        LatLng(23.2165, 77.4402),
        LatLng(23.2175, 77.4410),
        LatLng(23.2195, 77.4430),
      ],
    ),
    _BhopalRoad(
      id: 'bittan_market',
      name: 'Bittan Market Road',
      queryPoint: LatLng(23.2220, 77.4520),
      path: [
        LatLng(23.2200, 77.4500),
        LatLng(23.2210, 77.4510),
        LatLng(23.2220, 77.4520),
        LatLng(23.2240, 77.4540),
        LatLng(23.2260, 77.4560),
      ],
    ),
    _BhopalRoad(
      id: 'shyamla_hills',
      name: 'Shyamla Hills Road',
      queryPoint: LatLng(23.2550, 77.4370),
      path: [
        LatLng(23.2530, 77.4350),
        LatLng(23.2540, 77.4360),
        LatLng(23.2550, 77.4370),
        LatLng(23.2570, 77.4390),
      ],
    ),
    _BhopalRoad(
      id: 'tt_nagar',
      name: 'TT Nagar Road',
      queryPoint: LatLng(23.2430, 77.4090),
      path: [
        LatLng(23.2415, 77.4072),
        LatLng(23.2422, 77.4081),
        LatLng(23.2430, 77.4090),
        LatLng(23.2445, 77.4108),
      ],
    ),
    _BhopalRoad(
      id: 'board_office',
      name: 'Board Office Road',
      queryPoint: LatLng(23.2545, 77.4095),
      path: [
        LatLng(23.2560, 77.4080),
        LatLng(23.2553, 77.4088),
        LatLng(23.2545, 77.4095),
        LatLng(23.2530, 77.4110),
        LatLng(23.2515, 77.4125),
      ],
    ),
    _BhopalRoad(
      id: 'kolar_road',
      name: 'Kolar Road',
      queryPoint: LatLng(23.1950, 77.4300),
      path: [
        LatLng(23.2100, 77.4200),
        LatLng(23.2050, 77.4250),
        LatLng(23.1950, 77.4300),
        LatLng(23.1850, 77.4350),
      ],
    ),
    _BhopalRoad(
      id: 'hoshangabad_road',
      name: 'Hoshangabad Road',
      queryPoint: LatLng(23.2200, 77.4100),
      path: [
        LatLng(23.2350, 77.4050),
        LatLng(23.2280, 77.4075),
        LatLng(23.2200, 77.4100),
        LatLng(23.2100, 77.4130),
      ],
    ),
  ];

  // ── Public API ────────────────────────────────────────────────────────────

  /// Fetch live traffic for all Bhopal road segments.
  /// Falls back to simulated data if the API key is missing or the call fails.
  Future<TrafficResult> fetchBhopalTraffic() async {
    const apiKey = String.fromEnvironment('TOMTOM_API_KEY');

    if (apiKey.isEmpty) {
      return _simulatedResult();
    }

    try {
      final segments = await _fetchFromApi(apiKey);
      return TrafficResult(
        segments: segments,
        isSimulated: false,
        fetchedAt: DateTime.now(),
      );
    } catch (_) {
      return _simulatedResult();
    }
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  Future<List<TrafficSegment>> _fetchFromApi(String apiKey) async {
    final futures = _roads.map((road) => _fetchSegment(road, apiKey));
    final results = await Future.wait(futures, eagerError: false);
    return results.whereType<TrafficSegment>().toList();
  }

  Future<TrafficSegment?> _fetchSegment(_BhopalRoad road, String apiKey) async {
    try {
      final point = '${road.queryPoint.latitude},${road.queryPoint.longitude}';
      final url =
          '$_baseUrl/flowSegmentData/absolute/$_zoom/json'
          '?key=$apiKey&point=$point&unit=kmph';

      final response = await _dio.get<Map<String, dynamic>>(url);
      final data = response.data?['flowSegmentData'] as Map<String, dynamic>?;

      if (data == null) return null;

      final currentSpeed = (data['currentSpeed'] as num?)?.toDouble() ?? 30.0;
      final freeFlowSpeed = (data['freeFlowSpeed'] as num?)?.toDouble() ?? 50.0;
      final ratio = freeFlowSpeed > 0
          ? (currentSpeed / freeFlowSpeed).clamp(0.0, 1.0)
          : 0.5;
      final congestion = 1.0 - ratio;

      // Use coordinates from API response if available (more accurate road path)
      List<LatLng> path = road.path;
      final coords = data['coordinates']?['coordinate'];
      if (coords is List && coords.length >= 2) {
        final apiPath = coords
            .map((c) {
              final lat = (c['latitude'] as num?)?.toDouble();
              final lng = (c['longitude'] as num?)?.toDouble();
              if (lat != null && lng != null) return LatLng(lat, lng);
              return null;
            })
            .whereType<LatLng>()
            .toList();
        if (apiPath.length >= 2) path = apiPath;
      }

      return TrafficSegment(
        id: road.id,
        points: path,
        currentSpeed: currentSpeed,
        freeFlowSpeed: freeFlowSpeed,
        congestionLevel: congestion,
        status: TrafficSegment.statusFromRatio(ratio),
        isSimulated: false,
      );
    } catch (_) {
      return null;
    }
  }

  // ── Simulation fallback ───────────────────────────────────────────────────

  static final Random _rng = Random();

  TrafficResult _simulatedResult() {
    final segments = _roads.map((road) => _simulateSegment(road)).toList();
    return TrafficResult(
      segments: segments,
      isSimulated: true,
      fetchedAt: DateTime.now(),
    );
  }

  TrafficSegment _simulateSegment(_BhopalRoad road) {
    // Deterministic base per road + small random variation
    final base = _roadBaseSpeed(road.id);
    final variation = (_rng.nextDouble() - 0.5) * 8; // ±4 km/h
    final currentSpeed = (base + variation).clamp(5.0, 80.0);
    const freeFlowSpeed = 60.0;
    final ratio = (currentSpeed / freeFlowSpeed).clamp(0.0, 1.0);

    return TrafficSegment(
      id: road.id,
      points: road.path,
      currentSpeed: currentSpeed,
      freeFlowSpeed: freeFlowSpeed,
      congestionLevel: 1.0 - ratio,
      status: TrafficSegment.statusFromRatio(ratio),
      isSimulated: true,
    );
  }

  double _roadBaseSpeed(String id) {
    const speeds = {
      'hamidia_road': 22.0,
      'new_market': 18.0,
      'mp_nagar': 35.0,
      'arera_colony': 38.0,
      'bittan_market': 50.0,
      'shyamla_hills': 52.0,
      'tt_nagar': 30.0,
      'board_office': 25.0,
      'kolar_road': 45.0,
      'hoshangabad_road': 28.0,
    };
    return speeds[id] ?? 35.0;
  }
}
