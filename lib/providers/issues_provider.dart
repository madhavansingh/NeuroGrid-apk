import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import '../services/civic_issues_service.dart';
import '../services/ws_service.dart';

// ── issuesProvider ────────────────────────────────────────────────────────────

class IssuesNotifier extends AsyncNotifier<List<CivicIssue>> {
  StreamSubscription<WsEvent>? _wsSub;

  @override
  Future<List<CivicIssue>> build() async {
    // Ensure WebSocket is connected
    WsService.instance.connect();

    // Listen for real-time issue events
    _wsSub?.cancel();
    _wsSub = WsService.instance.events.listen((event) {
      if (event.type == WsEventType.issueCreated) {
        _handleCreated(event.data);
      } else if (event.type == WsEventType.issueUpdated) {
        _handleUpdated(event.data);
      }
    });

    ref.onDispose(() => _wsSub?.cancel());

    return ApiService.instance.fetchIssues();
  }

  // ── WS handlers ──────────────────────────────────────────────────────────

  void _handleCreated(Map<String, dynamic> data) {
    try {
      final issue = CivicIssue.fromJson(data);
      final current = state.valueOrNull ?? [];
      if (current.any((i) => i.id == issue.id)) return;
      state = AsyncData([issue, ...current]);
    } catch (_) {}
  }

  void _handleUpdated(Map<String, dynamic> data) {
    try {
      final updated = CivicIssue.fromJson(data);
      final current = state.valueOrNull ?? [];
      final idx = current.indexWhere((i) => i.id == updated.id);
      if (idx == -1) {
        state = AsyncData([updated, ...current]);
      } else {
        final next = List<CivicIssue>.from(current);
        next[idx] = updated;
        state = AsyncData(next);
      }
    } catch (_) {}
  }

  // ── Public actions ────────────────────────────────────────────────────────

  /// Pull fresh list from backend.
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = AsyncData(await ApiService.instance.fetchIssues());
  }

  /// POST a new issue; optimistically prepends it to state.
  /// Throws on backend/network failure so the UI can show the real error.
  Future<CivicIssue?> submitIssue({
    required String title,
    required String description,
    required String issueType,
    String? imageUrl,
    double? latitude,
    double? longitude,
    String? locationName,
  }) async {
    // Let the exception propagate — the screen catches it and shows the message.
    final issue = await ApiService.instance.createIssue(
      title: title,
      description: description,
      issueType: issueType,
      imageUrl: imageUrl,
      latitude: latitude,
      longitude: longitude,
      locationName: locationName,
    );
    if (issue != null) {
      final current = state.valueOrNull ?? [];
      if (!current.any((i) => i.id == issue.id)) {
        state = AsyncData([issue, ...current]);
      }
    }
    return issue;
  }

  /// PATCH issue status; updates local state immediately (optimistic).
  Future<bool> updateStatus(String issueId, String newStatus) async {
    final success =
        await ApiService.instance.updateIssueStatus(issueId, newStatus);
    if (success) {
      final current = state.valueOrNull ?? [];
      final idx = current.indexWhere((i) => i.id == issueId);
      if (idx != -1) {
        final next = List<CivicIssue>.from(current);
        next[idx] = current[idx].copyWith(status: newStatus);
        state = AsyncData(next);
      }
    }
    return success;
  }
}

final issuesProvider =
    AsyncNotifierProvider<IssuesNotifier, List<CivicIssue>>(
  IssuesNotifier.new,
);
