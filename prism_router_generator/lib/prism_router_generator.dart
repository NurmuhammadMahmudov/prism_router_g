library prism_router_generator;

import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

import 'src/prism_router_generator.dart';

/// Build runner entrypoint.
Builder prismRouterBuilder(BuilderOptions options) =>
    SharedPartBuilder([PrismRouterGenerator()], 'prism_router');

/// Generates `<router>.imports.g.dart` files (barrel exports for screens).
Builder prismRouterImportsBuilder(BuilderOptions options) =>
    LibraryBuilder(PrismRouterImportsGenerator(), generatedExtension: '.imports.g.dart');


