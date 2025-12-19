import 'dart:math';

import '../navigator/prism_page.dart';

/// Shared, internal coordination state between the router, parser and controller.
///
/// This is used on Flutter web to:
/// - persist per-entry arguments via `RouteInformation.state`
/// - keep a lightweight "history index" (depth) so we can best-effort reset
///   browser history for `pushAndRemoveAll`.
final class PrismHistorySync {
  PrismHistorySync() : sessionId = _createSessionId();

  /// A unique session id for the current app run.
  final String sessionId;

  /// Current history depth within this session (best-effort).
  ///
  /// This is updated from `RouteInformation.state` on back/forward, and
  /// incremented when the router reports a new entry.
  int currentIndex = 0;

  /// When true, the parser should avoid reporting route information to the
  /// platform while we are doing manual browser history operations.
  bool suppressReporting = false;

  /// When true, the parser should keep returning [resetTargetPages] to avoid UI
  /// flicker while browser history is being manipulated.
  bool isResetting = false;

  /// Pages to pin during a history reset.
  List<PrismPage>? resetTargetPages;
}

String _createSessionId() {
  final now = DateTime.now().microsecondsSinceEpoch;
  final rand = Random().nextInt(1 << 32);
  return '$now-$rand';
}


