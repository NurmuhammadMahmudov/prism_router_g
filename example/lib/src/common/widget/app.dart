import 'package:flutter/material.dart';
import 'package:prism_router/prism_router.dart';

import '../../../app_router.dart';

/// {@template app}
/// App widget.
/// {@endtemplate}
class App extends StatefulWidget {
  /// {@macro app}
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  final GlobalKey<State<StatefulWidget>> _preserveKey =
      GlobalKey<State<StatefulWidget>>();

  late final RouterConfig<Object> _routerConfig;

  @override
  void initState() {
    super.initState();
    final guards = <PrismNavigationGuard>[
      // Ensure stack is never empty.
      (context, state) => state.isEmpty ? <PrismPage>[HomePage()] : state,
    ];

    _routerConfig = buildPrismRouterConfig(
      webHistoryMode: PrismWebHistoryMode.replace,
      guards: guards,
    );
  }

  @override
  Widget build(BuildContext context) => MaterialApp.router(
    key: _preserveKey,
    title: 'Declarative Navigation',
    debugShowCheckedModeBanner: false,
    routerConfig: _routerConfig,
  );
}
