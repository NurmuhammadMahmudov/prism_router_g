import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:prism_router/prism_router.dart';
import 'package:prism_router_annotations/prism_router_annotations.dart';

import '../../../app_router.dart';

PrismStateObserver? prismStateObserver;

/// {@template home_screen}
/// HomeScreen widget.
/// {@endtemplate}
@PrismRoute(initial: true)
class HomeScreen extends StatefulWidget {
  /// {@macro home_screen}
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  void updateUI() {
    setState(() {});
    log(prismStateObserver?.value.join() ?? '');
  }

  @override
  void initState() {
    super.initState();
    prismStateObserver = context.prism.observer;
    prismStateObserver?.addListener(updateUI);
  }

  @override
  void dispose() {
    prismStateObserver?.removeListener(updateUI);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stack = context.prism.state; // Access navigation state
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reset to home',
            onPressed: () => context.setStack([HomePage()]),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Current stack',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children:
                  stack
                      .map((page) => Chip(label: Text('/${page.name}')))
                      .toList(),
            ),
            const SizedBox(height: 32),
            _NavigationTile(
              icon: Icons.settings,
              title: 'Open settings',
              subtitle: 'Pushes a custom routed page with transition override',
              onTap:
                  () => context.push(
                    SettingsPage(
                      data: 'Updated @ ${DateTime.now().toIso8601String()}',
                    ),
                  ),
            ),
            _NavigationTile(
              icon: Icons.person,
              title: 'Push profile',
              subtitle: 'Simple page that can open details',
              onTap: () => context.push(ProfilePage()),
            ),
            _NavigationTile(
              icon: Icons.description,
              title: 'Push details',
              subtitle: 'Pass data arguments & show tag-based back handling',
              onTap:
                  () => context.push(
                    DetailsPage(
                      userId: '42',
                      note: 'Opened directly from home',
                    ),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavigationTile extends StatelessWidget {
  const _NavigationTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.symmetric(vertical: 8),
    child: ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    ),
  );
}
