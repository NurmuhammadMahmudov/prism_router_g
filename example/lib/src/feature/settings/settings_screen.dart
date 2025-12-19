import 'package:flutter/material.dart';
import 'package:prism_router/prism_router.dart';
import 'package:prism_router_annotations/prism_router_annotations.dart';

/// {@template settings_screen}
/// SettingsScreen widget.
/// {@endtemplate}
@PrismRoute(tags: {'settings'}, transition: PrismTransition.zoom)
class SettingsScreen extends StatelessWidget {
  /// {@macro settings_screen}
  const SettingsScreen({required this.data, super.key});

  final String data;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.cyan,
    appBar: AppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: context.pop,
      ),
      title: const Text('Settings'),
    ),
    body: SafeArea(child: Center(child: Text('data: $data'))),
  );
}
