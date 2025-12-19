import 'dart:convert';

import '../navigator/prism_page.dart';
import 'path_codec.dart';

/// Internal encoded history state stored in [RouteInformation.state] (web) to
/// restore page arguments when navigating with browser back/forward.
///
/// The payload is a JSON string with a version field for forward compatibility:
/// `{ "v": 1, "s": "<session>", "i": <index>, "stack": [{ "n": "home", "a": {...} }, ...] }`
final class PrismHistoryState {
  const PrismHistoryState({
    required this.sessionId,
    required this.index,
    required this.segments,
  });

  final String sessionId;
  final int index;
  final List<EncodedRouteSegment> segments;
}

String encodePrismHistoryState(
  List<PrismPage> stack, {
  required String sessionId,
  required int index,
}) {
  final payload = <String, Object?>{
    'v': 1,
    's': sessionId,
    'i': index,
    'stack': [
      for (final page in stack)
        <String, Object?>{
          'n': page.name,
          'a': _sanitizeArgs(page.arguments),
        },
    ],
  };
  return jsonEncode(payload);
}

PrismHistoryState? decodePrismHistoryState(Object? state) {
  if (state == null) return null;

  Object? decoded;
  if (state is String) {
    try {
      decoded = jsonDecode(state);
    } on Object {
      return null;
    }
  } else {
    decoded = state;
  }

  if (decoded is! Map) return null;

  // Flutter web may wrap the user-provided `RouteInformation.state` inside a
  // larger history object (e.g. `{serialCount: 3, state: "<payload>"}`).
  // If we see such a wrapper, try decoding the nested `state` field.
  if (decoded['v'] == null &&
      decoded['s'] == null &&
      decoded['i'] == null &&
      decoded['stack'] == null &&
      decoded.containsKey('state')) {
    return decodePrismHistoryState(decoded['state']);
  }

  final version = decoded['v'];
  final session = decoded['s'];
  final index = decoded['i'];
  final stack = decoded['stack'];

  if (version != 1 || session is! String || index is! int || stack is! List) {
    return null;
  }

  final segments = <EncodedRouteSegment>[];
  for (final item in stack) {
    if (item is! Map) return null;
    final name = item['n'];
    if (name is! String) return null;
    final argsRaw = item['a'];
    final args = _safeArgs(argsRaw);
    segments.add(EncodedRouteSegment(name, args));
  }

  return PrismHistoryState(sessionId: session, index: index, segments: segments);
}

Map<String, Object?> _safeArgs(Object? raw) {
  if (raw is! Map) return const <String, Object?>{};
  final out = <String, Object?>{};
  for (final entry in raw.entries) {
    final k = entry.key;
    if (k is! String) continue;
    out[k] = entry.value;
  }
  return out;
}

const Object _unsupported = Object();

Map<String, Object?> _sanitizeArgs(Map<String, Object?> args) {
  final out = <String, Object?>{};
  for (final entry in args.entries) {
    final encoded = _toJsonEncodable(entry.value);
    if (!identical(encoded, _unsupported)) {
      out[entry.key] = encoded;
    }
  }
  return out;
}

Object? _toJsonEncodable(Object? value) {
  if (value == null || value is num || value is bool || value is String) {
    return value;
  }

  if (value is List) {
    final out = <Object?>[];
    for (final element in value) {
      final encoded = _toJsonEncodable(element);
      if (!identical(encoded, _unsupported)) {
        out.add(encoded);
      }
    }
    return out;
  }

  if (value is Map) {
    final out = <String, Object?>{};
    for (final entry in value.entries) {
      final k = entry.key;
      if (k is! String) continue;
      final encoded = _toJsonEncodable(entry.value);
      if (!identical(encoded, _unsupported)) {
        out[k] = encoded;
      }
    }
    return out;
  }

  return _unsupported;
}


