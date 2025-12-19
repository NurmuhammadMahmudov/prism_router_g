import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prism_router/prism_router.dart';
import 'package:prism_router/src/router/controller.dart';
import 'package:prism_router/src/router/scope.dart';

void main() {
  group('PrismController', () {
    test('push allows same name with different arguments', () {
      final controller = PrismController(
        initialPages: [const _HomePage()],
        guards: const [],
      );

      final state =
          (controller
                ..push(const _DetailsPage(userId: '1'))
                ..push(const _DetailsPage(userId: '2')))
              .state;

      expect(state.length, 3);
      expect(state.last.name, 'details');
      expect(state.last.arguments['userId'], '2');
    });

    test('push prevents pushing the same route (name + arguments) twice', () {
      final controller = PrismController(
        initialPages: [const _HomePage()],
        guards: const [],
      );

      final state =
          (controller
                ..push(const _DetailsPage(userId: '2'))
                ..push(const _DetailsPage(userId: '2')))
              .state;

      expect(state.length, 2);
      expect(state.last.arguments['userId'], '2');
    });

    test(
      'pushReplacement allows replacing same name with different arguments',
      () {
        final controller = PrismController(
          initialPages: [const _HomePage()],
          guards: const [],
        );

        final state =
            (controller
                  ..push(const _DetailsPage(userId: '1'))
                  ..pushReplacement(const _DetailsPage(userId: '2')))
                .state;

        expect(state.length, 2);
        expect(state.last.name, 'details');
        expect(state.last.arguments['userId'], '2');
      },
    );

    test('pushAndRemoveUntil keeps all pages up to the predicate match', () {
      final controller = PrismController(
        initialPages: [const _NamedPage('a')],
        guards: const [],
      );

      final state =
          (controller
                ..push(const _NamedPage('b'))
                ..push(const _NamedPage('c'))
                ..push(const _NamedPage('d'))
                ..pushAndRemoveUntil(
                  const _NamedPage('e'),
                  (p) => p.name == 'b',
                ))
              .state;

      expect(state.map((p) => p.name).toList(), ['a', 'b', 'e']);
    });

    test('setFromRouter preserves current page instance when name matches', () {
      final controller = PrismController(
        initialPages: [const _HomePage()],
        guards: const [],
      );

      // Router provides pages rebuilt from URL (arguments usually missing),
      // but we keep the in-memory page instance when the name matches.
      final state =
          (controller
                ..push(const _DetailsPage(userId: '123'))
                ..setFromRouter([
                  const _HomePage(),
                  const _DetailsPage(userId: ''),
                ]))
              .state;

      // We keep the existing details instance because the name matches.
      expect(state.length, 2);
      expect(state.last.name, 'details');
      expect(state.last.arguments['userId'], '123');
    });

    testWidgets('setFromRouter applies guards after controller is attached', (
      tester,
    ) async {
      final controller = PrismController(
        initialPages: [const _HomePage()],
        guards: [
          (context, state) {
            if (state.any((p) => p.name == 'blocked')) {
              return [const _HomePage()];
            }
            return state;
          },
        ],
      );

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: PrismScope(controller: controller, child: const SizedBox()),
        ),
      );

      controller.setFromRouter([const _HomePage(), const _BlockedPage()]);
      await tester.pump();

      expect(controller.state.map((p) => p.name).toList(), ['home']);
    });
  });
}

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
  const _DetailsPage({required this.userId})
    : super(
        name: 'details',
        child: const SizedBox.shrink(),
        arguments: const <String, Object?>{},
        tags: null,
      );

  final String userId;

  @override
  Map<String, Object?> get arguments => <String, Object?>{'userId': userId};

  @override
  PrismPage pageBuilder(Map<String, Object?> arguments) =>
      _DetailsPage(userId: (arguments['userId'] as String?) ?? '');
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

final class _BlockedPage extends PrismPage {
  const _BlockedPage()
    : super(
        name: 'blocked',
        child: const SizedBox.shrink(),
        arguments: const <String, Object?>{},
        tags: null,
      );

  @override
  PrismPage pageBuilder(Map<String, Object?> arguments) => const _BlockedPage();
}
