import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

/// Immutable location snapshot exposed to UI.
class LocationState {
  final bool loading;
  final double? latitude;
  final double? longitude;
  final String areaLabel;     // "MP Nagar, Bhopal" — shown in header
  final String? error;

  const LocationState({
    this.loading = false,
    this.latitude,
    this.longitude,
    this.areaLabel = 'Bhopal • MP Nagar',
    this.error,
  });

  bool get hasLocation => latitude != null && longitude != null;

  LocationState copyWith({
    bool? loading,
    double? latitude,
    double? longitude,
    String? areaLabel,
    String? error,
    bool clearError = false,
  }) => LocationState(
    loading: loading ?? this.loading,
    latitude: latitude ?? this.latitude,
    longitude: longitude ?? this.longitude,
    areaLabel: areaLabel ?? this.areaLabel,
    error: clearError ? null : (error ?? this.error),
  );
}

final locationProvider =
    StateNotifierProvider<LocationNotifier, LocationState>(
  (ref) => LocationNotifier(),
);

class LocationNotifier extends StateNotifier<LocationState> {
  LocationNotifier() : super(const LocationState());

  // Default fallback: Oriental College, Patel Nagar, Bhopal
  static const double _fallbackLat = 23.2599;
  static const double _fallbackLng = 77.4126;

  /// Call once after onboarding / permission granted.
  Future<void> fetchLocation() async {
    state = state.copyWith(loading: true, clearError: true);

    try {
      // Check permission
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        perm = await Geolocator.requestPermission();
      }

      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        // Fall back gracefully
        state = state.copyWith(
          loading: false,
          latitude: _fallbackLat,
          longitude: _fallbackLng,
          areaLabel: 'Bhopal • MP Nagar',
        );
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 8),
        ),
      );

      final label = await _reverseGeocode(pos.latitude, pos.longitude);

      state = state.copyWith(
        loading: false,
        latitude: pos.latitude,
        longitude: pos.longitude,
        areaLabel: label,
      );
    } catch (e) {
      // Graceful fallback — never show raw error to user
      state = state.copyWith(
        loading: false,
        latitude: _fallbackLat,
        longitude: _fallbackLng,
        areaLabel: 'Bhopal • MP Nagar',
      );
    }
  }

  Future<String> _reverseGeocode(double lat, double lng) async {
    try {
      final placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isEmpty) return 'Bhopal';
      final p = placemarks.first;
      final sub = p.subLocality ?? p.locality ?? '';
      final city = p.locality ?? p.administrativeArea ?? 'Bhopal';
      if (sub.isNotEmpty && sub != city) return '$city • $sub';
      return city;
    } catch (_) {
      return 'Bhopal • MP Nagar';
    }
  }
}
