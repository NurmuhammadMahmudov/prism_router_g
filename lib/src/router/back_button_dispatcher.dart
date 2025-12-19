import 'package:flutter/material.dart';

import 'controller.dart';

/// Custom back button dispatcher that properly handles initial state.
class PrismBackButtonDispatcher extends RootBackButtonDispatcher {
  PrismBackButtonDispatcher(this.controller);

  final PrismController controller;

  @override
  Future<bool> didPopRoute() async {
    // If we're at initial state, can't pop - back button should be disabled
    if (controller.isAtInitialState) {
      return false;
    }
    // Call controller.pop() which will notify the router delegate
    final didPop = controller.pop();
    return didPop;
  }
}
