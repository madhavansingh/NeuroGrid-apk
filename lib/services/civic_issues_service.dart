import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class CivicIssue {
  final String id;
  final String? userId;
  final String title;
  final String description;
  final String issueType;
  final String? imageUrl;
  final double? latitude;
  final double? longitude;
  final String? locationName;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  CivicIssue({
    required this.id,
    this.userId,
    required this.title,
    required this.description,
    required this.issueType,
    this.imageUrl,
    this.latitude,
    this.longitude,
    this.locationName,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CivicIssue.fromJson(Map<String, dynamic> json) {
    return CivicIssue(
      id: json['id'] as String,
      userId: json['user_id'] as String?,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      issueType: json['issue_type'] as String? ?? 'other',
      imageUrl: json['image_url'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      locationName: json['location_name'] as String?,
      status: json['status'] as String? ?? 'pending',
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'description': description,
      'issue_type': issueType,
      'image_url': imageUrl,
      'latitude': latitude,
      'longitude': longitude,
      'location_name': locationName,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  CivicIssue copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    String? issueType,
    String? imageUrl,
    double? latitude,
    double? longitude,
    String? locationName,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CivicIssue(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      issueType: issueType ?? this.issueType,
      imageUrl: imageUrl ?? this.imageUrl,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      locationName: locationName ?? this.locationName,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class CivicIssuesService {
  static CivicIssuesService? _instance;
  static CivicIssuesService get instance =>
      _instance ??= CivicIssuesService._();
  CivicIssuesService._();

  SupabaseClient get _client => Supabase.instance.client;
  static const String _bucketName = 'issue-images';

  /// Fetch all issues ordered by newest first
  Future<List<CivicIssue>> fetchIssues({String? statusFilter}) async {
    try {
      var query = _client.from('issues').select();
      if (statusFilter != null && statusFilter.isNotEmpty) {
        query = query.eq('status', statusFilter);
      }
      final data = await query.order('created_at', ascending: false);
      return (data as List).map((e) => CivicIssue.fromJson(e)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Upload image to Supabase Storage and return public URL
  Future<String?> uploadImage(dynamic imageFile) async {
    try {
      const uuid = Uuid();
      final fileName = '${uuid.v4()}.jpg';
      final path = 'issues/$fileName';

      if (kIsWeb) {
        // imageFile is Uint8List on web
        final bytes = imageFile as Uint8List;
        await _client.storage
            .from(_bucketName)
            .uploadBinary(
              path,
              bytes,
              fileOptions: const FileOptions(
                contentType: 'image/jpeg',
                upsert: true,
              ),
            );
      } else {
        // imageFile is File on mobile
        final file = imageFile as File;
        await _client.storage
            .from(_bucketName)
            .upload(
              path,
              file,
              fileOptions: const FileOptions(
                contentType: 'image/jpeg',
                upsert: true,
              ),
            );
      }

      final publicUrl = _client.storage.from(_bucketName).getPublicUrl(path);
      return publicUrl;
    } catch (e) {
      return null;
    }
  }

  /// Submit a new civic issue
  Future<CivicIssue?> submitIssue({
    required String title,
    required String description,
    required String issueType,
    String? imageUrl,
    double? latitude,
    double? longitude,
    String? locationName,
  }) async {
    try {
      final user = _client.auth.currentUser;
      final data = await _client
          .from('issues')
          .insert({
            'user_id': user?.id,
            'title': title,
            'description': description,
            'issue_type': issueType,
            'image_url': imageUrl,
            'latitude': latitude,
            'longitude': longitude,
            'location_name': locationName,
            'status': 'pending',
          })
          .select()
          .single();
      return CivicIssue.fromJson(data);
    } catch (e) {
      return null;
    }
  }

  /// Update issue status (simulate operator action)
  Future<bool> updateIssueStatus(String issueId, String newStatus) async {
    try {
      await _client
          .from('issues')
          .update({'status': newStatus})
          .eq('id', issueId);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Subscribe to real-time issue changes
  RealtimeChannel subscribeToIssues({
    required void Function(CivicIssue issue, String eventType) onEvent,
  }) {
    return _client
        .channel('public:issues')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'issues',
          callback: (payload) {
            try {
              final record = payload.eventType == PostgresChangeEvent.delete
                  ? payload.oldRecord
                  : payload.newRecord;
              if (record.isNotEmpty) {
                final issue = CivicIssue.fromJson(record);
                onEvent(issue, payload.eventType.name);
              }
            } catch (_) {}
          },
        )
        .subscribe();
  }

  /// Simulate operator progression: pending → in_progress → resolved
  Future<void> simulateOperatorUpdate(
    String issueId,
    String currentStatus,
  ) async {
    String nextStatus;
    switch (currentStatus) {
      case 'pending':
        nextStatus = 'in_progress';
        break;
      case 'in_progress':
        nextStatus = 'resolved';
        break;
      default:
        return;
    }
    await updateIssueStatus(issueId, nextStatus);
  }
}
