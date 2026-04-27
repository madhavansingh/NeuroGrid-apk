/// CivicIssue model — shared across the app.
///
/// Supabase has been fully removed. All data now flows through
/// [ApiService] (REST) and [WsService] (WebSocket).
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

  const CivicIssue({
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

  Map<String, dynamic> toJson() => {
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
