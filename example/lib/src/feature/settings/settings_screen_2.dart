import 'package:flutter/material.dart';
import 'package:prism_router/prism_router.dart';
import 'package:prism_router_annotations/prism_router_annotations.dart';

/// {@template settings_screen_2}
/// SettingsScreen2 widget.
/// {@endtemplate}
@PrismRoute(tags: {'settings2'}, transition: PrismTransition.fade)
class SettingsScreen2 extends StatelessWidget {
  /// {@macro settings_screen_2}
  const SettingsScreen2({required this.data, super.key});

  final String data;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.cyan,
    appBar: AppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: context.pop,
      ),
      title: const Text('Settings 2'),
    ),
    body: SafeArea(child: Center(child: Text('data: $data'))),
  );
}


