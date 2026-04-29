import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../config/api_config.dart';
import 'api_client.dart';

// ── Event types ───────────────────────────────────────────────────────────────

enum WsEventType {
  issueCreated,
  issueUpdated,
  trafficUpdate,
  parkingUpdate,
  wasteUpdate,
  unknown,
}

class WsEvent {
  final WsEventType type;
  final Map<String, dynamic> data;
  const WsEvent({required this.type, required this.data});
}

// ── Connection state ──────────────────────────────────────────────────────────

enum WsConnectionState { disconnected, connecting, connected, waking }

// ── WsService singleton ───────────────────────────────────────────────────────

/// Singleton WebSocket service (wss:// — always secure).
/// Auto-reconnects with exponential back-off; handles Render cold-start delays.
class WsService {
  static WsService? _instance;
  static WsService get instance => _instance ??= WsService._();
  WsService._();

  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _subscription;
  Timer? _reconnectTimer;
  bool _intentionalClose = false;
  int _reconnectAttempts = 0;

  // Public state stream
  final _stateController =
      StreamController<WsConnectionState>.broadcast();
  final _eventController = StreamController<WsEvent>.broadcast();

  Stream<WsEvent> get events => _eventController.stream;
  Stream<WsConnectionState> get connectionState => _stateController.stream;
  WsConnectionState _state = WsConnectionState.disconnected;
  WsConnectionState get state => _state;
  bool get isConnected => _state == WsConnectionState.connected;

  // ── Public API ──────────────────────────────────────────────────────────────

  /// Connect to the backend WebSocket. Safe to call multiple times.
  void connect() {
    if (_state == WsConnectionState.connected ||
        _state == WsConnectionState.connecting) return;
    _intentionalClose = false;
    _reconnectAttempts = 0;
    _doConnect();
  }

  /// Cleanly disconnect. Does not trigger auto-reconnect.
  void disconnect() {
    _intentionalClose = true;
    _cleanup();
    _setState(WsConnectionState.disconnected);
  }

  // ── Internal ────────────────────────────────────────────────────────────────

  void _setState(WsConnectionState s) {
    _state = s;
    _stateController.add(s);
  }

  void _doConnect() {
    _setState(WsConnectionState.connecting);

    // On first attempt after a cold start Render can be slow — show "waking"
    if (_reconnectAttempts == 0) {
      _setState(WsConnectionState.waking);
    }

    try {
      // Use ApiClient.wsUrl which is derived from the production base URL
      final wsUrl = ApiClient.instance.wsUrl;
      debugPrint('[WS] Connecting → $wsUrl');
      final uri = Uri.parse(wsUrl);
      _channel = WebSocketChannel.connect(uri);

      _setState(WsConnectionState.connected);
      _reconnectAttempts = 0;

      _subscription = _channel!.stream.listen(
        _onMessage,
        onError: _onError,
        onDone: _onDone,
        cancelOnError: false,
      );

      debugPrint('[WS] Connected ✓');
    } catch (e) {
      debugPrint('[WS] Connect failed: $e');
      _setState(WsConnectionState.disconnected);
      if (!_intentionalClose) _scheduleReconnect();
    }
  }

  void _onMessage(dynamic raw) {
    try {
      final json = jsonDecode(raw as String) as Map<String, dynamic>;
      final eventStr = json['event'] as String? ?? '';
      final data = json['data'] as Map<String, dynamic>? ?? {};
      final event = WsEvent(type: _parse(eventStr), data: data);
      _eventController.add(event);
    } catch (e) {
      debugPrint('[WS] Parse error: $e');
    }
  }

  void _onError(Object error) {
    debugPrint('[WS] Error: $error');
    _cleanup();
    _setState(WsConnectionState.disconnected);
    if (!_intentionalClose) _scheduleReconnect();
  }

  void _onDone() {
    debugPrint('[WS] Connection closed');
    _cleanup();
    _setState(WsConnectionState.disconnected);
    if (!_intentionalClose) _scheduleReconnect();
  }

  void _cleanup() {
    _reconnectTimer?.cancel();
    _subscription?.cancel();
    _subscription = null;
    try { _channel?.sink.close(); } catch (_) {}
    _channel = null;
  }

  /// Exponential back-off: 5s → 10s → 20s → … capped at 60s.
  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    _reconnectAttempts++;
    final base = ApiConfig.wsReconnectBase.inSeconds;
    final cap  = ApiConfig.wsReconnectMax.inSeconds;
    final delay = Duration(
      seconds: min(cap, (base * pow(2, _reconnectAttempts - 1)).toInt()),
    );
    debugPrint('[WS] Reconnecting in ${delay.inSeconds}s '
        '(attempt $_reconnectAttempts)…');
    _reconnectTimer = Timer(delay, _doConnect);
  }

  WsEventType _parse(String event) {
    switch (event) {
      case 'issue.created':  return WsEventType.issueCreated;
      case 'issue.updated':  return WsEventType.issueUpdated;
      case 'traffic.update': return WsEventType.trafficUpdate;
      case 'parking.update': return WsEventType.parkingUpdate;
      case 'waste.update':   return WsEventType.wasteUpdate;
      default:               return WsEventType.unknown;
    }
  }
}
