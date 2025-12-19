import 'package:flutter/material.dart';
import 'package:prism_router/prism_router.dart';
import 'package:prism_router_annotations/prism_router_annotations.dart';

import 'src/feature/details/details_screen.dart';
import 'src/feature/home/home_screen.dart';
import 'src/feature/profile/profile_screen.dart';
import 'src/feature/settings/settings_screen.dart';

part 'app_router.g.dart';

/// Router generation entrypoint.
///
/// Run:
/// - `flutter pub run build_runner build`
/// to generate `app_router.g.dart`.
@PrismRouterConfig()
class AppRouter {}


