import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/api_config.dart';

// ── States ────────────────────────────────────────────────────────────────────

enum ServerStatus { unknown, waking, online, offline }

// ── Notifier ──────────────────────────────────────────────────────────────────

class ServerStatusNotifier extends AsyncNotifier<ServerStatus> {
  final _dio = Dio(BaseOptions(
    connectTimeout: ApiConfig.connectTimeout,
    receiveTimeout: ApiConfig.receiveTimeout,
  ));

  @override
  Future<ServerStatus> build() async => _check();

  Future<ServerStatus> _check() async {
    state = const AsyncData(ServerStatus.waking);
    try {
      await _dio.get<dynamic>('${ApiConfig.productionBaseUrl}/health');
      return ServerStatus.online;
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        return ServerStatus.waking;
      }
      // 4xx/5xx still means server is up
      if (e.response != null) return ServerStatus.online;
      return ServerStatus.offline;
    } catch (_) {
      return ServerStatus.offline;
    }
  }

  /// Re-ping the server (call from retry button).
  Future<void> retry() async {
    state = const AsyncData(ServerStatus.waking);
    state = AsyncData(await _check());
  }
}

final serverStatusProvider =
    AsyncNotifierProvider<ServerStatusNotifier, ServerStatus>(
  ServerStatusNotifier.new,
);
