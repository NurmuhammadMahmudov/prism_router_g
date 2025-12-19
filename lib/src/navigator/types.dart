import 'package:flutter/widgets.dart';

import 'prism_page.dart';

/// Type definition for the navigation state.
typedef PrismNavigationState = List<PrismPage>;

/// A single navigation guard.
///
/// Guards receive the current [state] and may return a modified stack.
typedef PrismNavigationGuard =
    PrismNavigationState Function(BuildContext context, PrismNavigationState state);

/// A list of navigation guards applied in order.
typedef PrismGuard = List<PrismNavigationGuard>;

/// Definition for a restorable route.
class PrismRouteDefinition {
  const PrismRouteDefinition({required this.name, required this.builder});

  /// Unique route name. Usually matches [PrismPage.name].
  final String name;

  /// Builds a page when restoring navigation state. Receives the arguments map
  /// that was provided when the page was first pushed.
  final PrismPage Function(Map<String, Object?> arguments) builder;
}
