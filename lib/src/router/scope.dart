import 'package:flutter/widgets.dart';

import 'controller.dart';

class PrismScope extends StatefulWidget {
  const PrismScope({required this.controller, required this.child, super.key});

  final PrismController controller;
  final Widget child;

  static PrismController of(BuildContext context, {bool listen = true}) {
    final scope =
        listen
            ? context.dependOnInheritedWidgetOfExactType<_InheritedPrismScope>()
            : context.getInheritedWidgetOfExactType<_InheritedPrismScope>();
    assert(scope != null, 'No PrismScope found in context.');
    return scope!.controller;
  }

  @override
  State<PrismScope> createState() => _PrismScopeState();
}

class _PrismScopeState extends State<PrismScope> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    widget.controller.attach(context);
  }

  @override
  Widget build(BuildContext context) =>
      _InheritedPrismScope(controller: widget.controller, child: widget.child);
}

class _InheritedPrismScope extends InheritedWidget {
  const _InheritedPrismScope({required this.controller, required super.child});

  final PrismController controller;

  @override
  bool updateShouldNotify(covariant _InheritedPrismScope oldWidget) =>
      !identical(controller, oldWidget.controller);
}
