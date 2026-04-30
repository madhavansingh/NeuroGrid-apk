import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/config/app_config.dart';
import '../core/services/weather_service.dart';

// ── Bhopal default coords ─────────────────────────────────────────────────
const double _defaultLat = 23.2599;
const double _defaultLon = 77.4126;

final _dio = Dio(BaseOptions(
  connectTimeout: const Duration(seconds: 12),
  receiveTimeout: const Duration(seconds: 12),
));

/// Fetches real weather for Bhopal (or device GPS if available).
/// 
/// Does NOT depend on locationProvider — it fetches weather immediately
/// with Bhopal coords so the card never stays in loading state.
/// GPS upgrade happens via [weatherWithLocationProvider].
final weatherProvider = FutureProvider<WeatherData>((ref) async {
  final apiKey = AppConfig.openWeatherKey;

  debugPrint('[WeatherProvider] API key length: ${apiKey.length}');

  if (apiKey.isEmpty) {
    debugPrint('[WeatherProvider] No API key — returning fallback');
    return WeatherData.fallback;
  }

  try {
    final response = await _dio.get<dynamic>(
      'https://api.openweathermap.org/data/2.5/weather',
      queryParameters: {
        'lat': _defaultLat,
        'lon': _defaultLon,
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
        '[WeatherProvider] ✓ ${data['name']} '
        '${weather.tempCelsius.round()}°C ${weather.conditionLabel}',
      );
      return weather;
    }

    debugPrint('[WeatherProvider] HTTP ${response.statusCode}');
    return WeatherData.fallback;
  } on DioException catch (e) {
    debugPrint('[WeatherProvider] DioError ${e.response?.statusCode}: ${e.message}');
    return WeatherData.fallback;
  } catch (e) {
    debugPrint('[WeatherProvider] Error: $e');
    return WeatherData.fallback;
  }
});
