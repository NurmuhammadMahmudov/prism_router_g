import 'package:flutter/foundation.dart' show shortHash;
import 'package:flutter/material.dart';

import 'types.dart';

@immutable
abstract base class PrismPage extends Page<void> {
  const PrismPage({
    required String super.name,
    required this.child,
    required Map<String, Object?>? super.arguments,
    Set<String>? tags,
    super.key,
  }) : _tags = tags;

  final Widget child;
  final Set<String>? _tags;

  /// Tags for page identification and filtering.
  ///
  /// Tags can be provided in constructor as:
  /// - A single String: `tags: 'settings'`
  /// - A Set of Strings: `tags: {'settings', 'preferences'}`
  /// - If not provided, returns `null` (use `tagsOrName` for default behavior)
  ///
  /// Override this getter if you need custom tags computed dynamically.
  ///
  /// Example with constructor (single tag):
  /// ```dart
  /// SettingsPage({required this.data})
  ///     : super(
  ///         name: 'settings',
  ///         tags: 'settings',  // Single tag
  ///         ...
  ///       );
  /// ```
  ///
  /// Example with constructor (multiple tags):
  /// ```dart
  /// SettingsPage({required this.data})
  ///     : super(
  ///         name: 'settings',
  ///         tags: {'settings', 'preferences'},  // Multiple tags
  ///         ...
  ///       );
  /// ```
  ///
  /// Example with override:
  /// ```dart
  /// @override
  /// Set<String>? get tags => {'settings', 'preferences'};
  /// ```
  Set<String> get tags {
    if (_tags == null) return {name};
    final tags = _tags;
    return tags;
  }

  /// Builds a page instance from arguments.
  ///
  /// Default implementation returns a page with no arguments.
  /// Override this method in subclasses to handle custom arguments.
  ///
  /// Example with Map (recommended - type-safe and backward compatible):
  /// ```dart
  /// @override
  /// PrismPage pageBuilder(Map<String, Object?> arguments) =>
  ///     SettingsPage(data: arguments['data'] as String? ?? '');
  /// ```
  ///
  /// Example with Record pattern matching (type-safe):
  /// ```dart
  /// @override
  /// PrismPage pageBuilder(Map<String, Object?> arguments) {
  ///   // Pattern matching - type-safe, no cast needed!
  ///   if (arguments case {'data': String data}) {
  ///     return SettingsPage(data: data);
  ///   }
  ///   return SettingsPage(data: '');
  /// }
  /// ```
  PrismPage pageBuilder(Map<String, Object?> arguments) =>
      _createDefaultInstance(arguments);
  // Default: try to create page with no arguments
  // This works for pages without required parameters
  // Subclasses should override if they need arguments

  /// Creates a default instance of this page.
  ///
  /// Default implementation tries to create page with no arguments.
  /// Override this if the default constructor requires parameters.
  PrismPage _createDefaultInstance(Map<String, Object?> arguments) {
    // Try to use arguments if they match the page's expected arguments
    // For pages without required parameters, this will work
    // For pages with required parameters, subclasses must override pageBuilder
    if (arguments.isEmpty) {
      // Try to create with default constructor (no arguments)
      // This works for const constructors without required parameters
      return _tryCreateDefault();
    }
    // If arguments are provided but page doesn't handle them,
    // subclasses should override pageBuilder
    throw UnimplementedError(
      'pageBuilder must be overridden for pages with required parameters. '
      'Override pageBuilder() in $runtimeType to handle arguments: $arguments',
    );
  }

  /// Tries to create a default instance.
  /// Override in subclasses if default constructor works.
  PrismPage _tryCreateDefault() {
    throw UnimplementedError(
      'pageBuilder must be overridden. '
      'Override pageBuilder() in $runtimeType',
    );
  }

  /// Returns a route definition for this page.
  ///
  /// This can be used to automatically generate routes from pages.
  /// Override if you need custom route behavior.
  PrismRouteDefinition get routeDefinition =>
      PrismRouteDefinition(name: name, builder: pageBuilder);

  @override
  Route<void> createRoute(BuildContext context) =>
      MaterialPageRoute(builder: (context) => child, settings: this);

  @override
  String get name => super.name ?? 'Unknown';

  @override
  LocalKey get key {
    // If a key is explicitly provided, use it
    if (super.key != null) {
      return super.key!;
    }
    // Generate a unique key based on name, arguments, and instance identity
    // identityHashCode is stable for the same instance, ensuring the key
    // remains consistent while being unique per instance
    // This prevents Navigator key conflicts when the same page type with
    // same arguments is pushed multiple times
    final argsHash = super.arguments != null ? shortHash(super.arguments!) : '';
    // Use identityHashCode which is stable for the same object instance
    // This ensures each page instance gets a unique key
    return ValueKey('$name#$argsHash#${identityHashCode(this)}');
  }

  @override
  Map<String, Object?> get arguments => switch (super.arguments) {
    Map<String, Object?> args when args.isNotEmpty => args,
    _ => const <String, Object?>{},
  };

  @override
  int get hashCode => Object.hashAll([key, name]);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PrismPage && key == other.key && name == other.name;
}
