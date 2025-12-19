import 'package:flutter/material.dart';
import 'package:prism_router/prism_router.dart';
import 'package:prism_router_annotations/prism_router_annotations.dart';

import '../../../app_router.dart';

/// {@template profile_screen}
/// Demonstrates pushing another page and removing itself via `pop`.
/// {@endtemplate}
@PrismRoute()
class ProfileScreen extends StatelessWidget {
  /// {@macro profile_screen}
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Profile'),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: context.pop,
      ),
    ),
    body: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'This screen lives on the stack next to Home & Settings.',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            icon: const Icon(Icons.description),
            label: const Text('Open details for user #007'),
            onPressed:
                () => context.push(
                  DetailsPage(userId: '007', note: 'Opened from profile'),
                ),
          ),
        ],
      ),
    ),
  );
}
