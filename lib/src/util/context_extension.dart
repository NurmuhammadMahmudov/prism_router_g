import 'package:flutter/material.dart';

import '../navigator/prism_page.dart';
import '../router/controller.dart';
import '../router/scope.dart';

extension PrismContextExtension on BuildContext {
  /// Gets the Prism controller for navigation.
  PrismController get prism => PrismScope.of(this, listen: false);

  /// Checks if a page can be popped from the navigation stack.
  /// Returns false if at initial state to prevent back navigation.
  bool get canPop {
    if (!Navigator.canPop(this)) return false;
    // Also check if we're at initial state
    return !prism.isAtInitialState;
  }

  /// Pops the current page from the navigation stack.
  void pop() => prism.pop();

  /// Pushes a new page onto the navigation stack.
  ///
  /// Prevents pushing the same page if it's already at the top of the stack.
  void push(PrismPage page) => prism.push(page);

  /// Replaces the top page with a new page.
  void pushReplacement(PrismPage page) => prism.pushReplacement(page);

  /// Pushes a new page and removes all previous pages until the predicate is true.
  void pushAndRemoveUntil(PrismPage page, bool Function(PrismPage) predicate) =>
      prism.pushAndRemoveUntil(page, predicate);

  /// Pushes a new page and removes all previous pages.
  void pushAndRemoveAll(PrismPage page) => prism.pushAndRemoveAll(page);

  /// Sets the navigation stack to the given pages.
  ///
  /// This replaces the entire navigation stack with the provided pages.
  void setStack(List<PrismPage> pages) => prism.setStack(pages);

  /// Applies a custom transformation to the navigation stack.
  ///
  /// Use this for advanced navigation scenarios where you need fine-grained control.
  void transformStack(
    List<PrismPage> Function(List<PrismPage> current) transform,
  ) => prism.transformStack(transform);
}
