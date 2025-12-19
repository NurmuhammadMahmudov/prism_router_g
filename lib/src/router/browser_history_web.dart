import 'dart:async';
import 'dart:js_interop';
import 'package:flutter/services.dart';
import 'package:web/web.dart' as web;

Object? readBrowserHistoryState() {
  final state = web.window.history.state;
  if (state == null) return null;
  // `History.state` is frequently a JS object on Flutter web (e.g. it wraps the
  // user-provided state under a `state` field). Convert JS JSON-like values to
  // Dart equivalents so our codecs can decode them reliably.
  try {
    return state.dartify();
  } on Object {
    // Fallback: return as-is (codecs may still handle primitive strings).
    return state;
  }
}

void goInHistory(int steps) => web.window.history.go(steps);

void reportRouteInformationUpdated({
  required String location,
  required Object? state,
  required bool replace,
}) {
  // Ensure we always use a normalized leading slash.
  final normalized = location.startsWith('/') ? location : '/$location';
  unawaited(
    SystemNavigator.routeInformationUpdated(
      uri: Uri.parse(normalized),
      state: state,
      replace: replace,
    ),
  );
}
