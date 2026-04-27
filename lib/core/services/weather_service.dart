import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class WeatherData {
  final double tempCelsius;
  final String condition;
  final String description;
  final int humidity;
  final double windSpeed;
  final int weatherId;
  final String iconCode;
  final bool hasAlert;

  const WeatherData({
    required this.tempCelsius,
    required this.condition,
    required this.description,
    required this.humidity,
    required this.windSpeed,
    required this.weatherId,
    required this.iconCode,
    required this.hasAlert,
  });

  /// Human-readable condition label for UI display
  String get conditionLabel {
    switch (condition.toLowerCase()) {
      case 'thunderstorm':
        return 'Thunderstorm';
      case 'drizzle':
        return 'Drizzle';
      case 'rain':
        return 'Rain';
      case 'snow':
        return 'Snow';
      case 'clear':
        return 'Clear';
      case 'clouds':
        final id = weatherId;
        if (id == 801) return 'Few Clouds';
        if (id == 802) return 'Partly Cloudy';
        return 'Cloudy';
      case 'mist':
      case 'fog':
      case 'haze':
        return 'Foggy';
      default:
        return condition;
    }
  }

  /// Subtitle shown below condition in insight card
  String get insightSubtitle {
    final temp = tempCelsius.round();
    return '$temp°C · $humidity% hum';
  }

  /// Whether conditions are adverse for traffic
  bool get isAdverseWeather {
    return [
      'thunderstorm',
      'rain',
      'drizzle',
      'snow',
      'mist',
      'fog',
      'haze',
    ].contains(condition.toLowerCase());
  }

  /// Traffic-friendly weather condition string for AI prompt
  String get trafficWeatherString {
    if (weatherId >= 200 && weatherId < 300) return 'Thunderstorm';
    if (weatherId >= 300 && weatherId < 400) return 'Drizzle';
    if (weatherId >= 500 && weatherId < 600) {
      if (weatherId >= 502) return 'Heavy rain';
      return 'Rain expected';
    }
    if (weatherId >= 600 && weatherId < 700) return 'Snow';
    if (weatherId >= 700 && weatherId < 800) return 'Foggy';
    if (weatherId == 800) return 'Clear';
    return 'Cloudy';
  }

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    final weather = (json['weather'] as List).first as Map<String, dynamic>;
    final main = json['main'] as Map<String, dynamic>;
    final wind = json['wind'] as Map<String, dynamic>? ?? {};
    final weatherId = weather['id'] as int? ?? 800;

    // Flag severe weather as alert
    final hasAlert = weatherId < 700 || (weatherId >= 900 && weatherId < 1000);

    return WeatherData(
      tempCelsius: (main['temp'] as num).toDouble(),
      condition: weather['main'] as String? ?? 'Clear',
      description: weather['description'] as String? ?? '',
      humidity: (main['humidity'] as num?)?.toInt() ?? 0,
      windSpeed: (wind['speed'] as num?)?.toDouble() ?? 0.0,
      weatherId: weatherId,
      iconCode: weather['icon'] as String? ?? '01d',
      hasAlert: hasAlert,
    );
  }

  /// Fallback data when API is unavailable
  static WeatherData get fallback => const WeatherData(
    tempCelsius: 32,
    condition: 'Clear',
    description: 'clear sky',
    humidity: 55,
    windSpeed: 2.5,
    weatherId: 800,
    iconCode: '01d',
    hasAlert: false,
  );
}

class WeatherService {
  static const String _baseUrl =
      'https://api.openweathermap.org/data/2.5/weather';

  // Bhopal, India coordinates
  static const double _lat = 23.2599;
  static const double _lon = 77.4126;

  final Dio _dio;

  WeatherService()
    : _dio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 8),
          receiveTimeout: const Duration(seconds: 8),
        ),
      );

  Future<WeatherData> fetchWeather() async {
    const envKey = String.fromEnvironment('OPENWEATHER_API_KEY');
    // Set OPENWEATHER_API_KEY in env.json (see env.json.example)
    // or pass via: flutter run --dart-define=OPENWEATHER_API_KEY=your_key
    const fallbackKey = '';
    final apiKey = envKey.isNotEmpty ? envKey : fallbackKey;

    if (apiKey.isEmpty) {
      debugPrint(
        '[WeatherService] OPENWEATHER_API_KEY not set, using fallback',
      );
      return WeatherData.fallback;
    }

    try {
      final response = await _dio.get(
        _baseUrl,
        queryParameters: {
          'lat': _lat,
          'lon': _lon,
          'appid': apiKey,
          'units': 'metric',
          'lang': 'en',
        },
      );

      if (response.statusCode == 200) {
        final data = response.data is String
            ? jsonDecode(response.data as String) as Map<String, dynamic>
            : response.data as Map<String, dynamic>;
        return WeatherData.fromJson(data);
      }
      return WeatherData.fallback;
    } catch (e) {
      debugPrint('[WeatherService] Error fetching weather: $e');
      return WeatherData.fallback;
    }
  }
}
