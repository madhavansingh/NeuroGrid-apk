import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/config/app_config.dart';
import '../core/services/weather_service.dart';
import 'location_provider.dart';

// ── Bhopal fallback coords (Oriental College, Patel Nagar) ────────────────
const double _bhopalLat = 23.2599;
const double _bhopalLon = 77.4126;

final _dio = Dio(BaseOptions(
  connectTimeout: const Duration(seconds: 10),
  receiveTimeout: const Duration(seconds: 10),
));

/// Auto-fetches real weather using GPS coordinates from [locationProvider].
/// Falls back to Bhopal center if location is unavailable.
/// Returns [WeatherData.fallback] if API key missing or network fails.
final weatherProvider = FutureProvider<WeatherData>((ref) async {
  // Wait for location (GPS or fallback) to be resolved
  final locState = ref.watch(locationProvider);

  final lat = locState.hasLocation ? locState.latitude! : _bhopalLat;
  final lon = locState.hasLocation ? locState.longitude! : _bhopalLon;

  final apiKey = AppConfig.openWeatherKey;
  if (apiKey.isEmpty) {
    debugPrint('[WeatherProvider] OPENWEATHER_API_KEY not set — using fallback');
    return WeatherData.fallback;
  }

  try {
    final response = await _dio.get<dynamic>(
      'https://api.openweathermap.org/data/2.5/weather',
      queryParameters: {
        'lat': lat,
        'lon': lon,
        'appid': apiKey,
        'units': 'metric',
        'lang': 'en',
      },
    );

    if (response.statusCode == 200) {
      final raw = response.data;
      final Map<String, dynamic> data = raw is String
          ? jsonDecode(raw) as Map<String, dynamic>
          : raw as Map<String, dynamic>;

      final weather = WeatherData.fromJson(data);
      debugPrint(
        '[WeatherProvider] ✓ ${data['name']} — '
        '${weather.tempCelsius.round()}°C ${weather.conditionLabel}',
      );
      return weather;
    }

    debugPrint('[WeatherProvider] HTTP ${response.statusCode} — using fallback');
    return WeatherData.fallback;
  } on DioException catch (e) {
    debugPrint('[WeatherProvider] Error: ${e.response?.statusCode} ${e.message}');
    return WeatherData.fallback;
  } catch (e) {
    debugPrint('[WeatherProvider] Unexpected: $e');
    return WeatherData.fallback;
  }
});
