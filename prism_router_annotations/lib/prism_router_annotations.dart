library prism_router_annotations;

import 'package:meta/meta.dart';

/// Built-in transition types that can be requested by [PrismRoute].
enum PrismTransition { material, zoom, fade, slide }

/// Marks a Widget class as a routable screen for Prism Router code generation.
///
/// The generator will create a `PrismPage` wrapper and route builders so the
/// app can restore stacks from URL segments and (on web) restore arguments from
/// browser history state.
@immutable
class PrismRoute {
  const PrismRoute({
    this.path,
    this.initial = false,
    this.tags = const <String>{},
    this.transition = PrismTransition.material,
  });

  /// Route path for this screen.
  ///
  /// For Prism Router, this is expected to be a **single segment** like `/home`
  /// (or `home`). The segment becomes the page `name` used in the URL stack:
  /// `/#/home/profile`.
  final String? path;

  /// Marks this route as part of the initial stack.
  ///
  /// If multiple routes are marked initial, the generator will pick the first
  /// one in stable order.
  final bool initial;

  /// Optional tags attached to the generated page.
  final Set<String> tags;

  /// Optional page transition used by the generated page's `createRoute`.
  final PrismTransition transition;
}

/// Entry-point annotation for generating a router config file (routes + stack).
///
/// Put this annotation on an otherwise empty class next to a `part '<file>.g.dart';`
/// directive. The generator will emit:
/// - `appRoutes`: List<PrismRouteDefinition>
/// - `initialStack`: List<PrismPage>
/// - `buildPrismRouterConfig(...)`: RouterConfig<Object>
@immutable
class PrismRouterConfig {
  const PrismRouterConfig();
}


