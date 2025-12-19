import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../navigator/prism_page.dart';
import '../navigator/types.dart';
import 'back_button_dispatcher.dart';
import 'controller.dart';
import 'path_codec.dart';
import 'route_information_parser.dart';
import 'route_sync.dart';
import 'router_delegate.dart';

/// Controls how Prism Router syncs navigation with browser history on Flutter web.
///
/// - [entries] (default): creates a new browser history entry for each in-app
///   navigation (Back/Forward work like typical SPA routing).
/// - [replace]: updates the URL/state using `replaceState` only (no new history
///   entries are added). This keeps the browser Back/Forward buttons effectively
///   disabled for in-app navigation.
enum PrismWebHistoryMode { entries, replace }

class PrismRouter {
  const PrismRouter._();

  static RouterConfig<Object> router({
    required List<PrismPage> initialStack,
    List<PrismRouteDefinition>? routes,
    List<PrismPage>? pages,
    PrismGuard guards = const [],
    List<NavigatorObserver> observers = const [],
    TransitionDelegate<Object> transitionDelegate =
        const DefaultTransitionDelegate<Object>(),
    String? restorationScopeId,
    PrismWebHistoryMode webHistoryMode = PrismWebHistoryMode.entries,
  }) {
    assert(initialStack.isNotEmpty, 'initialStack cannot be empty');
    final routeSync = PrismRouteSync();
    final controller = PrismController(
      initialPages: initialStack,
      guards: guards,
      routeSync: routeSync,
    );
    // Auto-generate routes from pages or initialStack if not provided
    final routeMap =
        routes != null
            ? {for (final route in routes) route.name: route}
            : {
              // Use pages list if provided, otherwise use initialStack
              for (final page in (pages ?? initialStack))
                page.name: page.routeDefinition,
            };
    final delegate = PrismRouterDelegate(
      controller: controller,
      observers: observers,
      transitionDelegate: transitionDelegate,
      restorationScopeId: restorationScopeId,
    );
    final parser = PrismRouteInformationParser(
      routeBuilders: routeMap,
      initialPages: initialStack,
      routeSync: routeSync,
      webHistoryMode: webHistoryMode,
    );
    // initialRouteInformation is used as fallback if browser URL is empty
    // Parser will parse actual browser URL if it exists
    final initialLocation = encodeLocation(initialStack);
    final initialRouteInformation =
        kIsWeb
            // On web, read the actual browser URL so refresh preserves stacks.
            ? RouteInformation(uri: Uri.base)
            : RouteInformation(uri: Uri.parse(initialLocation));
    final provider = PlatformRouteInformationProvider(
      initialRouteInformation: initialRouteInformation,
    );
    return RouterConfig<Object>(
      routerDelegate: delegate,
      routeInformationParser: parser,
      routeInformationProvider: provider,
      backButtonDispatcher: PrismBackButtonDispatcher(controller),
    );
  }
}
