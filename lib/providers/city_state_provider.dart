import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import '../services/ws_service.dart';

// ── cityStateProvider ─────────────────────────────────────────────────────────

class CityStateNotifier extends AsyncNotifier<CityState?> {
  StreamSubscription<WsEvent>? _wsSub;

  @override
  Future<CityState?> build() async {
    // Ensure WebSocket is connected
    WsService.instance.connect();

    // React to infrastructure WS events by re-fetching city state
    _wsSub?.cancel();
    _wsSub = WsService.instance.events.listen((event) {
      if (event.type == WsEventType.trafficUpdate ||
          event.type == WsEventType.parkingUpdate ||
          event.type == WsEventType.wasteUpdate) {
        _refresh();
      }
    });

    ref.onDispose(() => _wsSub?.cancel());

    return ApiService.instance.fetchCityState();
  }

  Future<void> _refresh() async {
    final updated = await ApiService.instance.fetchCityState();
    if (updated != null) state = AsyncData(updated);
  }

  /// Pull latest city state from backend.
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = AsyncData(await ApiService.instance.fetchCityState());
  }
}

final cityStateProvider =
    AsyncNotifierProvider<CityStateNotifier, CityState?>(
  CityStateNotifier.new,
);

// ── citySummaryProvider ───────────────────────────────────────────────────────

final citySummaryProvider = FutureProvider<CitySummary?>((ref) async {
  return ApiService.instance.fetchCitySummary();
});
