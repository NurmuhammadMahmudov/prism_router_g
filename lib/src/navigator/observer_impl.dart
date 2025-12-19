import 'dart:collection';

import 'package:flutter/foundation.dart';

import 'observer.dart';
import 'types.dart';

/// Internal [PrismStateObserver] implementation used by the router/controller.
///
/// This type is intentionally not exported from `package:prism_router/prism_router.dart`.
final class PrismObserverNavigatorImpl
    with ChangeNotifier
    implements PrismStateObserver {
  PrismObserverNavigatorImpl(
    PrismNavigationState initialState, [
    List<PrismHistoryEntry>? history,
  ]) : _value = initialState,
       _history = history?.toSet().toList() ?? [] {
    // Add the initial state to the history.
    if (_history.isEmpty || _history.last.state != initialState) {
      _history.add(
        PrismHistoryEntry(state: initialState, timestamp: DateTime.now()),
      );
    }
    _history.sort();
  }

  PrismNavigationState _value;
  final List<PrismHistoryEntry> _history;

  @override
  List<PrismHistoryEntry> get history =>
      UnmodifiableListView<PrismHistoryEntry>(_history);

  @override
  void setHistory(Iterable<PrismHistoryEntry> history) {
    _history
      ..clear()
      ..addAll(history)
      ..sort();
  }

  @override
  PrismNavigationState get value => _value;

  bool changeState(
    PrismNavigationState Function(PrismNavigationState state) fn,
  ) {
    final prev = _value;
    final next = fn(prev);
    if (identical(next, prev)) return false;
    _value = next;

    final historyEntry = PrismHistoryEntry(
      state: next,
      timestamp: DateTime.now(),
    );
    _history.add(historyEntry);
    if (_history.length > PrismStateObserver.maxHistoryLength) {
      _history.removeAt(0);
    }

    notifyListeners();
    return true;
  }
}
