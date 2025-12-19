import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prism_router/prism_router.dart';
import 'package:prism_router/src/router/history_state_codec.dart';
import 'package:prism_router/src/router/route_information_parser.dart';
import 'package:prism_router/src/router/route_sync.dart';

void main() {
  group('RouteInformation.state (history) integration', () {
    test('encode/decode preserves arguments when names match', () async {
      final sync = PrismRouteSync();
      final parser = PrismRouteInformationParser(
        routeBuilders: <String, PrismRouteDefinition>{
          'home': const PrismRouteDefinition(name: 'home', builder: _homeBuilder),
          'details': const PrismRouteDefinition(
            name: 'details',
            builder: _detailsBuilder,
          ),
        },
        initialPages: const [_HomePage()],
        routeSync: sync,
      );

      final configuration = <PrismPage>[
        const _HomePage(),
        const _DetailsPage(userId: '007', note: 'from test'),
      ];

      final info = parser.restoreRouteInformation(configuration);
      expect(info, isNotNull);
      expect(info!.state, isA<String>());

      final restored = await parser.parseRouteInformation(
        RouteInformation(uri: info.uri, state: info.state),
      );

      expect(restored.length, 2);
      expect(restored.first.name, 'home');
      final details = restored.last as _DetailsPage;
      expect(details.userId, '007');
      expect(details.note, 'from test');
    });

    test('decode ignores mismatched state and falls back to empty arguments', () async {
      final sync = PrismRouteSync();
      final parser = PrismRouteInformationParser(
        routeBuilders: <String, PrismRouteDefinition>{
          'home': const PrismRouteDefinition(name: 'home', builder: _homeBuilder),
          'details': const PrismRouteDefinition(
            name: 'details',
            builder: _detailsBuilder,
          ),
        },
        initialPages: const [_HomePage()],
        routeSync: sync,
      );

      // State contains stack [home/settings], but URL is /home/details.
      final wrongState = encodePrismHistoryState(
        const [_HomePage(), _NamedPage('settings')],
        sessionId: sync.sessionId,
        index: 1,
      );

      final restored = await parser.parseRouteInformation(
        RouteInformation(uri: Uri.parse('/home/details'), state: wrongState),
      );

      final details = restored.last as _DetailsPage;
      expect(details.userId, '');
      expect(details.note, '');
    });

    test('codec drops non-JSON-encodable argument values', () {
      final state = encodePrismHistoryState(
        const [_BadArgsPage()],
        sessionId: 's',
        index: 0,
      );

      final decoded = decodePrismHistoryState(state);
      expect(decoded, isNotNull);
      expect(decoded!.segments.single.arguments['ok'], 'value');
      expect(decoded.segments.single.arguments.containsKey('bad'), isFalse);
    });
  });
}

PrismPage _homeBuilder(Map<String, Object?> _) => const _HomePage();

PrismPage _detailsBuilder(Map<String, Object?> args) => _DetailsPage(
  userId: (args['userId'] as String?) ?? '',
  note: (args['note'] as String?) ?? '',
);

final class _HomePage extends PrismPage {
  const _HomePage()
      : super(
          name: 'home',
          child: const SizedBox.shrink(),
          arguments: const <String, Object?>{},
          tags: null,
        );

  @override
  PrismPage pageBuilder(Map<String, Object?> arguments) => const _HomePage();
}

final class _DetailsPage extends PrismPage {
  const _DetailsPage({required this.userId, required this.note})
      : super(
          name: 'details',
          child: const SizedBox.shrink(),
          arguments: const <String, Object?>{},
          tags: null,
        );

  final String userId;
  final String note;

  @override
  Map<String, Object?> get arguments => <String, Object?>{
        'userId': userId,
        'note': note,
      };

  @override
  PrismPage pageBuilder(Map<String, Object?> arguments) => _DetailsPage(
        userId: (arguments['userId'] as String?) ?? '',
        note: (arguments['note'] as String?) ?? '',
      );
}

final class _NamedPage extends PrismPage {
  const _NamedPage(this._name)
      : super(
          name: _name,
          child: const SizedBox.shrink(),
          arguments: const <String, Object?>{},
          tags: null,
        );

  final String _name;

  @override
  PrismPage pageBuilder(Map<String, Object?> arguments) => _NamedPage(_name);
}

final class _BadArgsPage extends PrismPage {
  const _BadArgsPage()
      : super(
          name: 'x',
          child: const SizedBox.shrink(),
          arguments: const <String, Object?>{},
          tags: null,
        );

  @override
  Map<String, Object?> get arguments => const <String, Object?>{
        'ok': 'value',
        'bad': Object(),
      };

  @override
  PrismPage pageBuilder(Map<String, Object?> arguments) => const _BadArgsPage();
}


