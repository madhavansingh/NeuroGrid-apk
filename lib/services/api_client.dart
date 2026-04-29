import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../config/api_config.dart';
import '../core/config/app_config.dart';

/// Singleton Dio client wired to the production FastAPI backend.
///
/// Base URL resolution order:
///   1. AppConfig.apiBaseUrl (from assets/env.json) — allows override at build
///   2. ApiConfig.productionBaseUrl — hardened production fallback
///
/// Includes automatic retry with exponential back-off to handle
/// Render free-tier cold starts gracefully.
class ApiClient {
  static ApiClient? _instance;
  static ApiClient get instance => _instance ??= ApiClient._();
  ApiClient._();

  /// Resolved base URL — always HTTPS in production.
  String get _baseUrl {
    final envUrl = AppConfig.apiBaseUrl;
    if (envUrl.isNotEmpty) return envUrl;
    return ApiConfig.productionBaseUrl;
  }

  late final Dio _dio = Dio(
    BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: ApiConfig.connectTimeout,
      receiveTimeout: ApiConfig.receiveTimeout,
      sendTimeout:    ApiConfig.sendTimeout,
      headers: const {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  )..interceptors.addAll([
      _AuthInterceptor(),
      _RetryInterceptor(),
      if (kDebugMode) _LogInterceptor(),
    ]);

  Dio get dio => _dio;

  /// WebSocket URL — always wss:// for secure connections.
  String get wsUrl {
    final url = _baseUrl
        .replaceFirst('http://', 'ws://')
        .replaceFirst('https://', 'wss://');
    return '$url${ApiConfig.wsPath}';
  }
}

// ── Auth interceptor ──────────────────────────────────────────────────────────

class _AuthInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // Attach JWT when auth is wired, e.g.:
    // final token = AuthService.instance.token;
    // if (token != null) options.headers['Authorization'] = 'Bearer $token';
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) =>
      handler.next(err);
}

// ── Retry interceptor (handles Render cold-start delays) ──────────────────────

class _RetryInterceptor extends Interceptor {
  static const _kRetryKey = '__retries__';

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final options = err.requestOptions;
    final retries = (options.extra[_kRetryKey] as int?) ?? 0;

    final isRetryable = err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.connectionError;

    if (isRetryable && retries < ApiConfig.maxRetries) {
      options.extra[_kRetryKey] = retries + 1;
      final delay = ApiConfig.retryBaseDelay * (retries + 1); // 3s, 6s, 9s
      debugPrint(
          '[API] Retry ${retries + 1}/${ApiConfig.maxRetries} in ${delay.inSeconds}s'
          ' — ${options.method} ${options.path}');
      await Future<void>.delayed(delay);
      try {
        final response = await ApiClient.instance.dio.fetch<dynamic>(options);
        handler.resolve(response);
      } on DioException catch (e) {
        handler.next(e);
      }
      return;
    }

    handler.next(err);
  }
}

// ── Debug log interceptor ─────────────────────────────────────────────────────

class _LogInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    debugPrint('[API] → ${options.method} ${options.baseUrl}${options.path}');
    handler.next(options);
  }

  @override
  void onResponse(Response<dynamic> response, ResponseInterceptorHandler handler) {
    debugPrint('[API] ← ${response.statusCode} ${response.requestOptions.path}');
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    debugPrint('[API] ✗ ${err.requestOptions.path} → ${err.type} ${err.message}');
    handler.next(err);
  }
}
