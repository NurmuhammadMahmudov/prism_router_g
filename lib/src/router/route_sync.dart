// Internal synchronization state between the Router (URL/history) layer and the
// in-app navigation controller.
//
// This is intentionally not exported from `package:prism_router/prism_router.dart`.
import '../navigator/prism_page.dart';

final class PrismRouteSync {
  PrismRouteSync()
      : _sessionId = _generateSessionId(),
        _currentIndex = 0;

  String _sessionId;
  int _currentIndex;

  /// Current in-app stack (best-effort). This is updated by the controller.
  List<PrismPage>? currentStack;

  /// Whether the controller is currently at its initial state.
  /// (Stored here so the parser can make web-specific decisions.)
  bool isAtInitialState = false;

  /// Web-only: after `pushAndRemoveAll`, we lock the router to the new session.
  /// If the browser back button navigates to an older history entry/session,
  /// the parser will bounce back to this locked stack instead of restoring it.
  String? lockedSessionId;
  List<PrismPage>? lockedPages;

  /// When true, the [RouteInformationParser.restoreRouteInformation] should
  /// return `null` so Router does not report URL changes to the platform.
  ///
  /// This is used for web-only manual history operations (e.g. `pushAndRemoveAll`)
  /// where we call `SystemNavigator.routeInformationUpdated` ourselves.
  bool suppressReporting = false;

  /// When true, the parser should keep returning [resetTargetPages] to pin the UI
  /// while we are manipulating browser history (web-only).
  bool isResetting = false;

  /// The stack to pin while [isResetting] is true.
  List<PrismPage>? resetTargetPages;

  /// A session identifier used to group a sequence of in-app history entries.
  String get sessionId => _sessionId;

  /// Current history index within the current [sessionId].
  int get currentIndex => _currentIndex;

  set currentIndex(int value) => _currentIndex = value < 0 ? 0 : value;

  /// Reset to a new session and index 0 (used by `pushAndRemoveAll` on web).
  void resetSession() {
    _sessionId = _generateSessionId();
    _currentIndex = 0;
  }

  void lockToCurrentSession(List<PrismPage> pages) {
    lockedSessionId = sessionId;
    lockedPages = pages;
  }

  void beginReset(List<PrismPage> targetPages) {
    suppressReporting = true;
    isResetting = true;
    resetTargetPages = targetPages;
  }

  void endReset() {
    suppressReporting = false;
    isResetting = false;
    resetTargetPages = null;
  }

  /// Adopt session/index from an existing browser history entry.
  void syncFromHistory({required String sessionId, required int index}) {
    final locked = lockedSessionId;
    if (locked != null && sessionId != locked) {
      // Web-only: when locked (after `pushAndRemoveAll`) we do not allow the
      // router to adopt an older session from browser history.
      return;
    }
    _sessionId = sessionId;
    currentIndex = index;
  }

  static String _generateSessionId() =>
      '${DateTime.now().microsecondsSinceEpoch}-${Object().hashCode}';
}


