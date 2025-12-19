import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../navigator/prism_page.dart';
import '../navigator/types.dart';
import 'browser_history.dart';
import 'history_state_codec.dart';
import 'path_codec.dart';
import 'route_sync.dart';
import 'router.dart';

class PrismRouteInformationParser
    extends RouteInformationParser<List<PrismPage>> {
  const PrismRouteInformationParser({
    required this.routeBuilders,
    required this.initialPages,
    required this.routeSync,
    this.webHistoryMode = PrismWebHistoryMode.entries,
  });

  final Map<String, PrismRouteDefinition> routeBuilders;
  final List<PrismPage> initialPages;
  final PrismRouteSync routeSync;
  final PrismWebHistoryMode webHistoryMode;

  @override
  Future<List<PrismPage>> parseRouteInformation(
    RouteInformation routeInformation,
  ) async {
    // During a web history reset (e.g. `pushAndRemoveAll`) we intentionally pin
    // the UI to the target stack to avoid flicker while the browser history is
    // being rewound.
    if (kIsWeb && routeSync.isResetting) {
      final pinned = routeSync.resetTargetPages;
      if (pinned != null && pinned.isNotEmpty) return pinned;
    }

    var uri = routeInformation.uri;

    // On web, always use hash routing to avoid server path conflicts
    // Completely ignore server paths and only use fragments
    if (kIsWeb) {
      // Always read from browser URL fragment, ignore server paths
      try {
        // ignore: avoid_web_libraries_in_flutter
        final location = Uri.base;
        final hash = location.fragment;

        if (hash.isNotEmpty) {
          // Use fragment from browser URL (hash routing)
          var fragment = hash;
          // Remove leading # if present (fragment already contains it)
          if (fragment.startsWith('#')) {
            fragment = fragment.substring(1);
          }
          // Ensure it starts with '/'
          if (!fragment.startsWith('/')) {
            fragment = '/$fragment';
          }
          uri = Uri(path: '/', fragment: fragment);
        } else {
          // No hash in URL, use initial pages
          // This ensures we always use hash routing, never server paths
          return initialPages;
        }
      } on Object {
        // Ignore errors when reading browser hash, fall back to initial pages
        return initialPages;
      }
    }

    final encodedSegments = decodeUri(uri);

    if (encodedSegments.isEmpty) {
      return initialPages;
    }

    // Try restoring arguments from RouteInformation.state (web history state).
    // On web refresh, the provider state can be null, so we also fall back to
    // reading `window.history.state` when available (via conditional import).
    final historyState =
        routeInformation.state ?? (kIsWeb ? readBrowserHistoryState() : null);
    final decoded = decodePrismHistoryState(historyState);
    final restoredSegments =
        decoded != null && _namesMatch(encodedSegments, decoded.segments)
            ? decoded.segments
            : null;

    // Web-only: if we've "locked" navigation after a `pushAndRemoveAll`, don't
    // allow browser back/forward to restore older history entries (or any route
    // different from the locked stack while at initial state). Instead, bounce
    // back to the locked stack by replacing the current entry.
    if (kIsWeb) {
      final lockedPages = routeSync.lockedPages;
      final lockedSessionId = routeSync.lockedSessionId;
      if (routeSync.isAtInitialState &&
          lockedPages != null &&
          lockedPages.isNotEmpty) {
        final lockedLocation = encodeLocation(lockedPages);
        final normalizedLockedLocation =
            lockedLocation.startsWith('/') ? lockedLocation : '/$lockedLocation';
        final requestedPath = '/${encodedSegments.map((s) => s.name).join('/')}';

        final isDifferentPath = requestedPath != normalizedLockedLocation;
        final isOldSession = decoded != null &&
            lockedSessionId != null &&
            decoded.sessionId != lockedSessionId;

        if (isDifferentPath || isOldSession) {
          final state = encodePrismHistoryState(
            lockedPages,
            sessionId: lockedSessionId ?? routeSync.sessionId,
            index: 0,
          );
          reportRouteInformationUpdated(
            location: normalizedLockedLocation,
            state: state,
            replace: true,
          );
          return lockedPages;
        }
      }
    }

    if (decoded != null && restoredSegments != null) {
      routeSync.syncFromHistory(sessionId: decoded.sessionId, index: decoded.index);
    }

    final pages = <PrismPage>[];
    for (var i = 0; i < encodedSegments.length; i++) {
      final segment = encodedSegments[i];
      final definition = routeBuilders[segment.name];
      if (definition == null) {
        // If any route is not found, fall back to initial pages
        return initialPages;
      }
      final args =
          restoredSegments != null ? restoredSegments[i].arguments : segment.arguments;
      pages.add(definition.builder(args));
    }

    return pages;
  }

  @override
  RouteInformation? restoreRouteInformation(List<PrismPage> configuration) {
    // When doing manual web history operations, the controller will update the
    // browser URL/state itself. Prevent the Router from also reporting changes.
    if (kIsWeb && routeSync.suppressReporting) return null;

    final location = encodeLocation(configuration);
    final normalizedLocation =
        location.startsWith('/') ? location : '/$location';

    if (kIsWeb) {
      // If URL already matches, avoid creating a new browser history entry.
      try {
        // ignore: avoid_web_libraries_in_flutter
        final currentUrl = Uri.base;
        final currentHash = currentUrl.fragment;
        
        // Normalize current hash for comparison (remove leading #, ensure leading /)
        var normalizedHash = currentHash;
        if (normalizedHash.startsWith('#')) {
          normalizedHash = normalizedHash.substring(1);
        }
        if (!normalizedHash.startsWith('/')) {
          normalizedHash = '/$normalizedHash';
        }
        
        // If URL already matches exactly, return null to prevent router from updating.
        if (normalizedHash == normalizedLocation) {
          // Update the browser entry state if needed (arguments restoration).
          final desiredState = encodePrismHistoryState(
            configuration,
            sessionId: routeSync.sessionId,
            index: routeSync.currentIndex,
          );
          final currentState = readBrowserHistoryState();
          if (currentState is! String || currentState != desiredState) {
            reportRouteInformationUpdated(
              location: normalizedLocation,
              state: desiredState,
              replace: true,
            );
          }
          return null;
        }
      } on Object {
        // Ignore errors when reading browser URL, proceed with normal update
      }

      // Web-only: in replace mode, sync URL/state without adding history entries.
      if (webHistoryMode == PrismWebHistoryMode.replace) {
        // Keep the history index stable since we're not adding entries.
        routeSync.currentIndex = 0;
        final state = encodePrismHistoryState(
          configuration,
          sessionId: routeSync.sessionId,
          index: 0,
        );
        reportRouteInformationUpdated(
          location: normalizedLocation,
          state: state,
          replace: true,
        );
        return null;
      }

      final nextIndex = routeSync.currentIndex + 1;
      final state = encodePrismHistoryState(
        configuration,
        sessionId: routeSync.sessionId,
        index: nextIndex,
      );
      routeSync.currentIndex = nextIndex;

      // NOTE: Using deprecated 'location' parameter is necessary for web reload
      // functionality with hash routing in many setups.
      // ignore: deprecated_member_use
      return RouteInformation(location: normalizedLocation, state: state);
    }

    final nextIndex = routeSync.currentIndex + 1;
    final state = encodePrismHistoryState(
      configuration,
      sessionId: routeSync.sessionId,
      index: nextIndex,
    );
    routeSync.currentIndex = nextIndex;
    return RouteInformation(uri: Uri.parse(normalizedLocation), state: state);
  }
}

bool _namesMatch(List<EncodedRouteSegment> a, List<EncodedRouteSegment> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i].name != b[i].name) return false;
  }
  return true;
}
