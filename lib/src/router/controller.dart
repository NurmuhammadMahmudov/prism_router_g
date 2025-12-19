import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart' show kIsWeb, listEquals;
import 'package:flutter/widgets.dart';

import '../navigator/observer.dart';
import '../navigator/observer_impl.dart';
import '../navigator/prism_page.dart';
import '../navigator/types.dart';
import 'browser_history.dart';
import 'history_state_codec.dart';
import 'path_codec.dart';
import 'route_sync.dart';

class PrismController extends ChangeNotifier {
  PrismController({
    required List<PrismPage> initialPages,
    required PrismGuard guards,
    PrismRouteSync? routeSync,
  }) : _guards = guards,
       _routeSync = routeSync ?? PrismRouteSync(),
       _state = UnmodifiableListView(initialPages),
       _initialPages = UnmodifiableListView(initialPages) {
    _observer = PrismObserverNavigatorImpl(_state);
  }

  final PrismGuard _guards;
  final PrismRouteSync _routeSync;
  UnmodifiableListView<PrismPage> _initialPages;
  late UnmodifiableListView<PrismPage> _state;
  late final PrismObserverNavigatorImpl _observer;
  BuildContext? _guardContext;

  UnmodifiableListView<PrismPage> get state => _state;

  PrismStateObserver get observer => _observer;

  /// Returns true if we're at the initial state (same as initial pages).
  /// Compares name + arguments (keys are instance-specific and not stable).
  bool get isAtInitialState {
    if (_state.length != _initialPages.length) return false;
    for (var i = 0; i < _state.length; i++) {
      final currentPage = _state[i];
      final initialPage = _initialPages[i];
      if (currentPage.name != initialPage.name ||
          !_mapsEqual(currentPage.arguments, initialPage.arguments)) {
        return false;
      }
    }
    return true;
  }

  // ignore: use_setters_to_change_properties
  void attach(BuildContext context) {
    _guardContext = context;
  }

  /// Pops the current page from the navigation stack.
  ///
  /// Returns `true` if a page was popped, `false` if the stack has only one page.
  bool pop() {
    if (_state.length < 2) return false;
    transformStack((pages) => pages..removeLast());
    return true;
  }

  /// Pushes a new page onto the navigation stack.
  ///
  /// Prevents pushing the same route (same name + same arguments) if it's
  /// already at the top of the stack.
  void push(PrismPage page) {
    if (_state.isNotEmpty && _isSameRoute(_state.last, page)) {
      return;
    }
    transformStack((pages) => pages..add(page));
  }

  /// Replaces the top page with a new page.
  ///
  /// If the stack is empty, pushes the page instead.
  void pushReplacement(PrismPage page) {
    if (_state.isEmpty) {
      push(page);
      return;
    }
    // Don't replace if it's the same route
    if (_isSameRoute(_state.last, page)) {
      return;
    }
    transformStack(
      (pages) =>
          pages
            ..removeLast()
            ..add(page),
    );
  }

  /// Pushes a new page and removes all previous pages until the predicate is true.
  ///
  /// Equivalent to `pushAndRemoveUntil` in Flutter Navigator.
  void pushAndRemoveUntil(PrismPage page, bool Function(PrismPage) predicate) {
    final current = _state.toList();
    final index = current.lastIndexWhere(predicate);
    final newStack = index >= 0 ? current.sublist(0, index + 1) : <PrismPage>[];
    setStack(newStack..add(page));
  }

  /// Pushes a new page and removes all previous pages.
  ///
  /// Equivalent to `pushAndRemoveUntil` with always false predicate.
  /// This also updates the initial state to prevent back navigation.
  void pushAndRemoveAll(PrismPage page) {
    final requested = <PrismPage>[page];
    final target = _applyGuards(List<PrismPage>.from(requested));

    // Update initial pages to the new stack to prevent in-app back navigation.
    _initialPages = UnmodifiableListView(target);

    if (!kIsWeb) {
      _setState(target);
      return;
    }

    // On web we do a best-effort browser history reset. We first update the
    // in-app stack immediately (UI should change), but suppress Router URL
    // reporting while we manually manipulate browser history.
    //
    // Also lock immediately so an instant browser Back (before the async reset
    // finishes) can't revive older entries.
    _routeSync
      ..lockToCurrentSession(target)
      ..beginReset(target);
    _setState(target, force: true);

    // ignore: unawaited_futures
    _resetWebHistory(target);
  }

  int _readWebHistoryIndexOr(int fallback) {
    try {
      final decoded = decodePrismHistoryState(readBrowserHistoryState());
      if (decoded != null) return decoded.index;
    } on Object {
      // Ignore - fall back to in-memory tracking.
    }
    return fallback;
  }

  Future<void> _resetWebHistory(List<PrismPage> targetStack) async {
    final location = encodeLocation(targetStack);
    final normalizedLocation =
        location.startsWith('/') ? location : '/$location';

    try {
      // Create a fresh session for the reset target and overwrite *all* in-tab
      // entries created by Prism Router so browser back/forward cannot return to
      // old in-app routes.
      final currentIndex = _readWebHistoryIndexOr(_routeSync.currentIndex);
      _routeSync
        ..resetSession()
        ..currentIndex = 0
        ..lockToCurrentSession(targetStack);

      // `currentIndex` is the index of the current entry (0-based in practice on
      // web because the initial entry often stores index 0 via a replace).
      // To overwrite all Prism-created entries, we need to touch `index + 1`
      // entries (current + each previous).
      final totalEntriesToOverwrite = (currentIndex < 0 ? 0 : currentIndex) + 1;
      var movedBack = 0;

      for (var i = 0; i < totalEntriesToOverwrite; i++) {
        final state = encodePrismHistoryState(
          targetStack,
          sessionId: _routeSync.sessionId,
          index: 0,
        );
        reportRouteInformationUpdated(
          location: normalizedLocation,
          state: state,
          replace: true,
        );

        // Move to the previous history entry so we can overwrite it as well.
        if (i == totalEntriesToOverwrite - 1) break;
        movedBack++;
        goInHistory(-1);
        await Future<void>.delayed(const Duration(milliseconds: 50));
      }

      // Return to the most recent entry so browser forward is disabled (we're at
      // the end). All entries in between now point to the same location/state.
      if (movedBack > 0) {
        goInHistory(movedBack);
        await Future<void>.delayed(const Duration(milliseconds: 50));
      }
    } on Object {
      // Fallback: best-effort replace so URL matches even if history operations
      // fail on a particular platform/browser.
      try {
        _routeSync
          ..resetSession()
          ..lockToCurrentSession(targetStack)
          ..currentIndex = 0;
        final state0 = encodePrismHistoryState(
          targetStack,
          sessionId: _routeSync.sessionId,
          index: 0,
        );
        reportRouteInformationUpdated(
          location: normalizedLocation,
          state: state0,
          replace: true,
        );
      } on Object {
        // Ignore.
      }
    } finally {
      _routeSync.endReset();
    }
  }

  /// Sets the navigation stack to the given pages.
  ///
  /// This replaces the entire navigation stack with the provided pages.
  /// Prefer [pushAndRemoveAll] or [pushAndRemoveUntil] for common use cases.
  void setStack(List<PrismPage> pages) {
    if (pages.isEmpty) return;
    _setState(_applyGuards(List<PrismPage>.from(pages)));
  }

  /// Applies a custom transformation to the navigation stack.
  ///
  /// Use this for advanced navigation scenarios where you need fine-grained control.
  void transformStack(
    List<PrismPage> Function(List<PrismPage> current) transform,
  ) {
    final next = transform(_state.toList());
    if (next.isEmpty) return;
    final guarded = _applyGuards(List<PrismPage>.from(next));
    _setState(guarded);
  }

  void setFromRouter(List<PrismPage> pages) {
    // URL-based restoration typically doesn't carry arguments.
    // If a page at the same position has the same name, prefer the current
    // instance to preserve its arguments/state.
    final merged = <PrismPage>[];
    for (var i = 0; i < pages.length; i++) {
      final newPage = pages[i];
      if (i < _state.length && _state[i].name == newPage.name) {
        merged.add(_state[i]);
      } else {
        merged.add(newPage);
      }
    }
    final guarded = _applyGuards(List<PrismPage>.from(merged));
    _setState(guarded, force: true);
  }

  List<PrismPage> _applyGuards(List<PrismPage> next) {
    if (next.isEmpty) return next;
    final ctx = _guardContext;
    if (ctx == null || _guards.isEmpty) return next;
    return _guards.fold<List<PrismPage>>(next, (state, guard) {
      final guarded = guard(ctx, List<PrismPage>.from(state));
      return guarded.isEmpty ? state : guarded;
    });
  }

  void _setState(List<PrismPage> next, {bool force = false}) {
    final immutable = UnmodifiableListView<PrismPage>(next);
    // Compare by name and arguments to avoid unnecessary updates
    if (!force) {
      // Check if pages are actually different
      if (immutable.length == _state.length) {
        var isDifferent = false;
        for (var i = 0; i < immutable.length; i++) {
          final current = _state[i];
          final nextPage = immutable[i];
          // Compare by name, key, and arguments
          if (current.name != nextPage.name ||
              current.key != nextPage.key ||
              !_mapsEqual(current.arguments, nextPage.arguments)) {
            isDifferent = true;
            break;
          }
        }
        if (!isDifferent) return;
      } else {
        // Different length, definitely different
        if (listEquals(immutable, _state)) return;
      }
    }
    _state = immutable;
    _observer.changeState((_) => _state);

    // Keep the Router sync layer informed about the current stack / initial state
    // so it can make better decisions on web (e.g. blocking browser back after
    // `pushAndRemoveAll`).
    _routeSync
      ..currentStack = _state
      ..isAtInitialState = isAtInitialState;

    notifyListeners();
  }

  // Helper to compare maps
  bool _mapsEqual(Map<String, Object?> a, Map<String, Object?> b) {
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (!b.containsKey(key) || a[key] != b[key]) return false;
    }
    return true;
  }

  bool _isSameRoute(PrismPage a, PrismPage b) =>
      a.name == b.name && _mapsEqual(a.arguments, b.arguments);
}
