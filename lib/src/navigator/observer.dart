import 'package:flutter/foundation.dart';

import 'types.dart';

/// Prism state observer
abstract interface class PrismStateObserver
    implements ValueListenable<PrismNavigationState> {
  /// Max history length.
  static const int maxHistoryLength = 10000;

  /// History.
  List<PrismHistoryEntry> get history;

  /// Set history
  void setHistory(Iterable<PrismHistoryEntry> history);
}

@immutable
final class PrismHistoryEntry implements Comparable<PrismHistoryEntry> {
  PrismHistoryEntry({required this.state, DateTime? timestamp})
    : timestamp = timestamp ?? DateTime.now();

  /// Navigation state
  final PrismNavigationState state;

  /// Timestamp of the entry
  final DateTime timestamp;

  @override
  int compareTo(covariant PrismHistoryEntry other) =>
      timestamp.compareTo(other.timestamp);

  @override
  late final int hashCode = state.hashCode ^ timestamp.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PrismHistoryEntry &&
          state == other.state &&
          timestamp == other.timestamp;
}
