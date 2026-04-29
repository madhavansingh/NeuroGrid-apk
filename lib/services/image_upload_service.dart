import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../core/config/app_config.dart';

/// Uploads images to Supabase Storage and returns the public URL.
///
/// Bucket: `waste-reports` (Supabase dashboard → Storage → New bucket
/// → name: waste-reports, Public: ON).
class ImageUploadService {
  static ImageUploadService? _instance;
  static ImageUploadService get instance =>
      _instance ??= ImageUploadService._();
  ImageUploadService._();

  static const _bucket = 'waste-reports';

  final _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 20),
    receiveTimeout: const Duration(seconds: 30),
  ));


  /// Uploads [bytes] to Supabase Storage and returns the public CDN URL.
  /// Returns null on failure.
  Future<String?> uploadImage(
    Uint8List bytes, {
    String extension = 'jpg',
    void Function(double progress)? onProgress,
  }) async {
    final supabaseUrl = AppConfig.supabaseUrl;
    final supabaseAnonKey = AppConfig.supabaseAnonKey;

    if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
      debugPrint('[ImageUpload] Supabase credentials not set in env.json.');
      return null;
    }

    final fileName = '${const Uuid().v4()}.$extension';
    final uploadUrl = '$supabaseUrl/storage/v1/object/$_bucket/$fileName';

    try {
      await _dio.put(
        uploadUrl,
        data: Stream.fromIterable(bytes.map((e) => [e])),
        options: Options(
          headers: {
            'apikey': supabaseAnonKey,
            'Authorization': 'Bearer $supabaseAnonKey',
            'Content-Type': 'image/jpeg',
            'Content-Length': bytes.length.toString(),
          },
        ),
        onSendProgress: (sent, total) {
          if (total > 0 && onProgress != null) {
            onProgress(sent / total);
          }
        },
      );
      final publicUrl =
          '$supabaseUrl/storage/v1/object/public/$_bucket/$fileName';
      debugPrint('[ImageUpload] ✓ Uploaded → $publicUrl');
      return publicUrl;
    } on DioException catch (e) {
      debugPrint('[ImageUpload] ✗ ${e.response?.statusCode} ${e.message}');
      return null;
    }
  }
}
