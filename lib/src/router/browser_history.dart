import 'browser_history_stub.dart'
    if (dart.library.html) 'browser_history_web.dart' as impl;

Object? readBrowserHistoryState() => impl.readBrowserHistoryState();

void goInHistory(int steps) => impl.goInHistory(steps);

void reportRouteInformationUpdated({
  required String location,
  required Object? state,
  required bool replace,
}) => impl.reportRouteInformationUpdated(
  location: location,
  state: state,
  replace: replace,
);


