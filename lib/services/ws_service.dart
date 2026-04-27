import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
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

// ── WsService singleton ───────────────────────────────────────────────────────

/// Singleton WebSocket service for ws://host/api/v1/ws.
/// Broadcasts parsed events to all listeners; auto-reconnects on disconnect.
class WsService {
  static WsService? _instance;
  static WsService get instance => _instance ??= WsService._();
  WsService._();

  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _subscription;
  Timer? _reconnectTimer;
  bool _intentionalClose = false;
  bool _connected = false;

  final _controller = StreamController<WsEvent>.broadcast();

  Stream<WsEvent> get events => _controller.stream;
  bool get isConnected => _connected;

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Connect to the backend WebSocket. Safe to call multiple times.
  void connect() {
    if (_connected) return;
    _intentionalClose = false;
    _doConnect();
  }

  /// Cleanly disconnect. Does not trigger auto-reconnect.
  void disconnect() {
    _intentionalClose = true;
    _cleanup();
  }

  // ── Internal ───────────────────────────────────────────────────────────────

  void _doConnect() {
    try {
      final uri = Uri.parse(ApiClient.instance.wsUrl);
      _channel = WebSocketChannel.connect(uri);
      _connected = true;
      _reconnectTimer?.cancel();

      _subscription = _channel!.stream.listen(
        _onMessage,
        onError: _onError,
        onDone: _onDone,
        cancelOnError: false,
      );

      debugPrint('[WS] Connected to ${ApiClient.instance.wsUrl}');
    } catch (e) {
      debugPrint('[WS] Connect failed: $e');
      _connected = false;
      _scheduleReconnect();
    }
  }

  void _onMessage(dynamic raw) {
    try {
      final json = jsonDecode(raw as String) as Map<String, dynamic>;
      final eventStr = json['event'] as String? ?? '';
      final data = json['data'] as Map<String, dynamic>? ?? {};
      final event = WsEvent(type: _parse(eventStr), data: data);
      debugPrint('[WS] ← $eventStr');
      _controller.add(event);
    } catch (e) {
      debugPrint('[WS] Parse error: $e');
    }
  }

  void _onError(Object error) {
    debugPrint('[WS] Error: $error');
    _connected = false;
    _cleanup();
    if (!_intentionalClose) _scheduleReconnect();
  }

  void _onDone() {
    debugPrint('[WS] Connection closed');
    _connected = false;
    if (!_intentionalClose) _scheduleReconnect();
  }

  void _cleanup() {
    _subscription?.cancel();
    _subscription = null;
    try {
      _channel?.sink.close();
    } catch (_) {}
    _channel = null;
    _connected = false;
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 5), () {
      debugPrint('[WS] Reconnecting…');
      _doConnect();
    });
  }

  WsEventType _parse(String event) {
    switch (event) {
      case 'issue.created':
        return WsEventType.issueCreated;
      case 'issue.updated':
        return WsEventType.issueUpdated;
      case 'traffic.update':
        return WsEventType.trafficUpdate;
      case 'parking.update':
        return WsEventType.parkingUpdate;
      case 'waste.update':
        return WsEventType.wasteUpdate;
      default:
        return WsEventType.unknown;
    }
  }
}
