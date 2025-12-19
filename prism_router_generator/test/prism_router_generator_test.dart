import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:prism_router_generator/prism_router_generator.dart';
import 'package:test/test.dart';

void main() {
  test('generates args parsing for required String parameter', () async {
    const input = r'''
library app_router;

import 'package:prism_router_annotations/prism_router_annotations.dart';

part 'app_router.g.dart';

@PrismRouterConfig()
class AppRouter {}

@PrismRoute(initial: true)
class HomeScreen {
  HomeScreen();
}

@PrismRoute(path: '/settings')
class SettingsScreen {
  SettingsScreen({required this.data});
  final String data;
}
''';

    await testBuilder(
      prismRouterBuilder(const BuilderOptions({})),
      <String, String>{'prism_router_generator|lib/app_router.dart': input},
      reader: await PackageAssetReader.currentIsolate(),
      outputs: <String, Matcher>{
        'prism_router_generator|lib/app_router.prism_router.g.part':
            decodedMatches(
          allOf(
            contains('final class SettingsPage extends PrismPage'),
            contains(
              'static PrismPage fromArgs(Map<String, Object?> arguments)',
            ),
            contains("if (arguments case {'data': String data})"),
            contains("(arguments['data'] as String?) ?? ''"),
          ),
        ),
      },
    );
  });
}


