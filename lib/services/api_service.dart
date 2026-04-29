import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'api_client.dart';
import 'civic_issues_service.dart';

// ── City State models ─────────────────────────────────────────────────────────

class CityTrafficState {
  final String status; // smooth | moderate | heavy
  final double congestionLevel; // 0.0 – 1.0
  final String hotspot;

  const CityTrafficState({
    required this.status,
    required this.congestionLevel,
    required this.hotspot,
  });

  factory CityTrafficState.fromJson(Map<String, dynamic> json) {
    return CityTrafficState(
      status: json['status'] as String? ?? 'smooth',
      congestionLevel: (json['congestion_level'] as num?)?.toDouble() ?? 0.0,
      hotspot: json['hotspot'] as String? ?? '',
    );
  }

  String get displayLabel {
    switch (status.toLowerCase()) {
      case 'heavy':
        return 'Heavy';
      case 'moderate':
        return 'Moderate';
      default:
        return 'Smooth';
    }
  }
}

class CityState {
  final CityTrafficState traffic;
  final Map<String, dynamic> parking;
  final Map<String, dynamic> waste;
  final List<dynamic> alerts;

  const CityState({
    required this.traffic,
    required this.parking,
    required this.waste,
    required this.alerts,
  });

  factory CityState.fromJson(Map<String, dynamic> json) {
    return CityState(
      traffic: CityTrafficState.fromJson(
        json['traffic'] as Map<String, dynamic>? ?? {},
      ),
      parking: json['parking'] as Map<String, dynamic>? ?? {},
      waste: json['waste'] as Map<String, dynamic>? ?? {},
      alerts: json['alerts'] as List<dynamic>? ?? [],
    );
  }
}

class CitySummary {
  final int totalIssues;
  final int pending;
  final int inProgress;
  final int resolved;

  const CitySummary({
    required this.totalIssues,
    required this.pending,
    required this.inProgress,
    required this.resolved,
  });

  factory CitySummary.fromJson(Map<String, dynamic> json) {
    return CitySummary(
      totalIssues: (json['total_issues'] as num?)?.toInt() ?? 0,
      pending: (json['pending'] as num?)?.toInt() ?? 0,
      inProgress: (json['in_progress'] as num?)?.toInt() ?? 0,
      resolved: (json['resolved'] as num?)?.toInt() ?? 0,
    );
  }
}

// ── ApiService ────────────────────────────────────────────────────────────────

class ApiService {
  static ApiService? _instance;
  static ApiService get instance => _instance ??= ApiService._();
  ApiService._();

  final Dio _dio = ApiClient.instance.dio;

  // ── City endpoints ─────────────────────────────────────────────────────────

  Future<CityState?> fetchCityState() async {
    try {
      final response =
          await _dio.get<Map<String, dynamic>>('/api/v1/city/state');
      if (response.data != null) return CityState.fromJson(response.data!);
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<CitySummary?> fetchCitySummary() async {
    try {
      final response =
          await _dio.get<Map<String, dynamic>>('/api/v1/city/summary');
      if (response.data != null) return CitySummary.fromJson(response.data!);
      return null;
    } catch (_) {
      return null;
    }
  }

  // ── Issues endpoints ───────────────────────────────────────────────────────

  Future<List<CivicIssue>> fetchIssues({String? statusFilter}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (statusFilter != null && statusFilter.isNotEmpty) {
        queryParams['status'] = statusFilter;
      }
      final response = await _dio.get<dynamic>(
        '/api/v1/issues',
        queryParameters: queryParams,
      );
      final list = response.data;
      if (list is List) {
        return list
            .map((e) => CivicIssue.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<CivicIssue?> createIssue({
    required String title,
    required String description,
    required String issueType,
    String? imageUrl,
    double? latitude,
    double? longitude,
    String? locationName,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/v1/issues',
        data: {
          'title': title,
          'description': description,
          'issue_type': issueType,
          if (imageUrl != null) 'image_url': imageUrl,
          if (latitude != null) 'latitude': latitude,
          if (longitude != null) 'longitude': longitude,
          if (locationName != null) 'location_name': locationName,
          'status': 'pending',
        },
      );
      if (response.data != null) return CivicIssue.fromJson(response.data!);
      return null;
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final body = e.response?.data?.toString() ?? e.message;
      debugPrint('[Issues] createIssue failed — HTTP $status: $body');
      // Rethrow with human-readable message so the UI can display it
      throw Exception('Server error $status: $body');
    } catch (e) {
      debugPrint('[Issues] createIssue unexpected error: $e');
      rethrow;
    }
  }

  Future<bool> updateIssueStatus(String issueId, String newStatus) async {
    try {
      await _dio.patch<dynamic>(
        '/api/v1/issues/$issueId/status',
        data: {'status': newStatus},
      );
      return true;
    } catch (_) {
      return false;
    }
  }
}
