import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'voice_models.dart';
import '../../../services/api_client.dart';

/// Retell AI WebRTC voice service.
///
/// Architecture (matches the web JS SDK exactly):
///
///   Flutter app
///     ↓ POST /api/v1/voice/create-web-call
///     ↓ access_token + call_id
///     ↓ WebSocket → wss://api.retellai.com/audio-websocket/v2/{access_token}
///     ↓ SDP offer/answer + ICE exchange
///     ↓ Audio: device ↔ Retell cloud (WebRTC)
///
/// Retell WebSocket events received:
///   { "type": "call_started" }
///   { "type": "call_ended" }
///   { "type": "agent_start_talking" }
///   { "type": "agent_stop_talking" }
///   { "type": "error", "error": "..." }
class RetellVoiceService {
  // ── Retell signaling endpoint ─────────────────────────────────────────────
  static const String _retellWsBase =
      'wss://api.retellai.com/audio-websocket/v2';

  // ── ICE servers (Google STUN — Retell adds TURN internally via SDP) ───────
  static const List<Map<String, dynamic>> _iceServers = [
    {'urls': 'stun:stun.l.google.com:19302'},
    {'urls': 'stun:stun1.l.google.com:19302'},
  ];

  // ── Internal state ────────────────────────────────────────────────────────
  RTCPeerConnection? _pc;
  MediaStream? _localStream;
  WebSocketChannel? _ws;
  StreamSubscription<dynamic>? _wsSub;
  Timer? _durationTick;
  Duration _elapsed = Duration.zero;

  // ── Public stream ─────────────────────────────────────────────────────────
  final _stateController = StreamController<VoiceState>.broadcast();
  Stream<VoiceState> get stateStream => _stateController.stream;

  VoiceState _state = const VoiceState();
  VoiceState get currentState => _state;

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  /// Request microphone permission.
  /// Returns true if granted.
  Future<bool> requestMicPermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  /// Full start-call flow:
  ///   1. POST backend → access_token
  ///   2. Open WebSocket to Retell
  ///   3. Capture local audio
  ///   4. Create RTCPeerConnection + SDP offer
  ///   5. Send offer → receive answer → set remote desc
  ///   6. Stream Retell events back via [stateStream]
  Future<void> startCall() async {
    if (_state.callStatus != CallStatus.idle) return;

    _emit(_state.copyWith(
      callStatus: CallStatus.connecting,
      clearError: true,
    ));

    try {
      // 1. Backend → access_token ──────────────────────────────────────────
      final token = await _fetchAccessToken();

      // 2. Mic permission ───────────────────────────────────────────────────
      final granted = await requestMicPermission();
      if (!granted) {
        _emitError('Microphone permission denied. Please enable it in Settings.');
        return;
      }

      // 3. Local audio stream ───────────────────────────────────────────────
      _localStream = await navigator.mediaDevices.getUserMedia({
        'audio': {
          'echoCancellation': true,
          'noiseSuppression': true,
          'autoGainControl': true,
        },
        'video': false,
      });

      // 4. RTCPeerConnection ────────────────────────────────────────────────
      _pc = await createPeerConnection({
        'iceServers': _iceServers,
        'sdpSemantics': 'unified-plan',
      });

      // Add local audio tracks
      for (final track in _localStream!.getAudioTracks()) {
        await _pc!.addTrack(track, _localStream!);
      }

      // ICE candidate handler — queue until WS is open, then flush
      final pendingCandidates = <RTCIceCandidate>[];
      bool wsReady = false;

      _pc!.onIceCandidate = (candidate) {
        if (candidate.candidate == null || candidate.candidate!.isEmpty) {
          return;
        }
        final msg = jsonEncode({
          'type': 'ice_candidate',
          'candidate': candidate.toMap(),
        });
        if (wsReady && _ws != null) {
          _ws!.sink.add(msg);
        } else {
          pendingCandidates.add(candidate);
        }
      };

      _pc!.onConnectionState = (state) {
        debugPrint('[Retell] PC state: $state');
        if (state == RTCPeerConnectionState.RTCPeerConnectionStateFailed ||
            state == RTCPeerConnectionState.RTCPeerConnectionStateDisconnected) {
          _handleCallEnded();
        }
      };

      // 5. SDP offer ────────────────────────────────────────────────────────
      final offer = await _pc!.createOffer({'offerToReceiveAudio': true});
      await _pc!.setLocalDescription(offer);

      // 6. WebSocket to Retell ──────────────────────────────────────────────
      _ws = WebSocketChannel.connect(
        Uri.parse('$_retellWsBase/$token'),
      );

      wsReady = true;

      // Flush queued ICE candidates
      for (final c in pendingCandidates) {
        _ws!.sink.add(jsonEncode({
          'type': 'ice_candidate',
          'candidate': c.toMap(),
        }));
      }
      pendingCandidates.clear();

      // Send SDP offer
      _ws!.sink.add(jsonEncode({'type': 'offer', 'sdp': offer.sdp}));

      // 7. Handle inbound WS messages ───────────────────────────────────────
      _wsSub = _ws!.stream.listen(
        _handleWsMessage,
        onError: (Object e) => _emitError('Connection error: $e'),
        onDone: _handleCallEnded,
      );
    } catch (e) {
      debugPrint('[Retell] startCall error: $e');
      _emitError('Could not start voice call: $e');
    }
  }

  /// Gracefully end the active call.
  Future<void> endCall() async {
    if (_state.callStatus == CallStatus.idle ||
        _state.callStatus == CallStatus.ending) {
      return;
    }

    _emit(_state.copyWith(callStatus: CallStatus.ending));
    await _tearDown();
    // Small delay so ending → idle transition is visible in UI
    await Future.delayed(const Duration(milliseconds: 600));
    _emit(const VoiceState());
  }

  void dispose() {
    _tearDown();
    _stateController.close();
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  Future<String> _fetchAccessToken() async {
    try {
      final response = await ApiClient.instance.dio.post(
        '/api/v1/voice/create-web-call',
        data: {
          'context': {
            'trigger': 'citizen_voice_mobile',
            'city': 'Bhopal',
            'area': 'Oriental College, Patel Nagar',
            'platform': 'NeuroGrid Mobile',
          },
        },
      );

      final raw = response.data;
      debugPrint('[Retell] Raw backend response: $raw');

      if (raw == null) {
        throw Exception('Empty response from voice backend.');
      }

      // Backend wraps as: {status, data: {success, data: {access_token, call_id}}}
      // Unwrap up to 3 levels deep until we find access_token
      Map<String, dynamic> payload = raw is Map<String, dynamic>
          ? raw
          : <String, dynamic>{};

      for (int depth = 0; depth < 3; depth++) {
        final token = payload['access_token'] as String?;
        if (token != null && token.isNotEmpty) {
          debugPrint('[Retell] access_token found at depth $depth');
          return token;
        }
        // Try unwrapping one level via 'data'
        final next = payload['data'];
        if (next is Map<String, dynamic>) {
          payload = next;
        } else {
          break;
        }
      }

      // Still not found — log full payload for debugging
      debugPrint('[Retell] ERROR: access_token not found. Full payload: $raw');
      throw Exception(
          'No access_token in response. Backend payload: $raw\n'
          'Check RETELL_API_KEY is set correctly on Render.');
    } on DioException catch (e) {
      final body = e.response?.data?.toString() ?? e.message;
      debugPrint('[Retell] HTTP ${e.response?.statusCode}: $body');
      throw Exception('Voice backend error ${e.response?.statusCode}: $body');
    } catch (e) {
      debugPrint('[Retell] _fetchAccessToken error: $e');
      rethrow;
    }
  }

  void _handleWsMessage(dynamic raw) {
    Map<String, dynamic> msg;
    try {
      msg = jsonDecode(raw as String) as Map<String, dynamic>;
    } catch (_) {
      return;
    }

    final type = msg['type'] as String?;
    debugPrint('[Retell] ← $type');

    switch (type) {
      // SDP answer from Retell
      case 'answer':
        final sdp = msg['sdp'] as String;
        _pc?.setRemoteDescription(RTCSessionDescription(sdp, 'answer'));

      // ICE candidate from Retell
      case 'ice_candidate':
        final candidateMap = msg['candidate'] as Map<String, dynamic>?;
        if (candidateMap != null) {
          _pc?.addCandidate(RTCIceCandidate(
            candidateMap['candidate'] as String?,
            candidateMap['sdpMid'] as String?,
            candidateMap['sdpMLineIndex'] as int?,
          ));
        }

      // Call lifecycle
      case 'call_started':
        _elapsed = Duration.zero;
        _startDurationTick();
        _emit(_state.copyWith(
          callStatus: CallStatus.inCall,
          speakStatus: SpeakStatus.listening,
          callDuration: Duration.zero,
        ));

      case 'call_ended':
        _handleCallEnded();

      // Agent speaking state
      case 'agent_start_talking':
        _emit(_state.copyWith(speakStatus: SpeakStatus.speaking));

      case 'agent_stop_talking':
        _emit(_state.copyWith(speakStatus: SpeakStatus.listening));

      case 'error':
        final err = msg['error'] as String? ?? 'Unknown Retell error';
        _emitError(err);

      default:
        break;
    }
  }

  void _handleCallEnded() {
    _durationTick?.cancel();
    _tearDown();
    _emit(const VoiceState());
  }

  void _startDurationTick() {
    _durationTick?.cancel();
    _durationTick = Timer.periodic(const Duration(seconds: 1), (_) {
      _elapsed += const Duration(seconds: 1);
      _emit(_state.copyWith(callDuration: _elapsed));
    });
  }

  Future<void> _tearDown() async {
    _durationTick?.cancel();
    await _wsSub?.cancel();
    _wsSub = null;
    await _ws?.sink.close();
    _ws = null;
    _localStream?.getTracks().forEach((t) => t.stop());
    _localStream?.dispose();
    _localStream = null;
    await _pc?.close();
    _pc = null;
  }

  void _emit(VoiceState state) {
    _state = state;
    if (!_stateController.isClosed) {
      _stateController.add(state);
    }
  }

  void _emitError(String message) {
    _emit(
      _state.copyWith(
        callStatus: CallStatus.idle,
        speakStatus: SpeakStatus.idle,
        error: message,
      ),
    );
    _tearDown();
  }
}
