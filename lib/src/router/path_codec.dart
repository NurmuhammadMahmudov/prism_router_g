import '../navigator/prism_page.dart';

class EncodedRouteSegment {
  EncodedRouteSegment(this.name, this.arguments);

  final String name;
  final Map<String, Object?> arguments;
}

String encodeLocation(List<PrismPage> pages) {
  if (pages.isEmpty) return '/';
  // Only encode page names in the URL. Arguments are *not* serialized into the
  // location to keep paths clean:
  //   /home/profile/details
  // instead of
  //   /home/profile/details~<base64-args>
  //
  // This means arguments are not restored on hard refresh, but the route
  // hierarchy (which screen you're on) is always preserved.
  final segments = pages.map((page) => page.name).join('/');
  return '/$segments';
}

List<EncodedRouteSegment> decodeUri(Uri uri) {
  // Support both direct-path URLs:
  //   /home/profile/details
  // and hash-based URLs:
  //   http://localhost:1234/#/home/profile/details
  //
  // In the latter case, [uri.pathSegments] is empty and the actual segments
  // live inside [uri.fragment].
  var segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();

  // If path is empty, check fragment (hash routing)
  if (segments.isEmpty && uri.fragment.isNotEmpty) {
    // Fragment can be: "/home/profile" or "home/profile" or "#/home/profile"
    var fragment = uri.fragment;

    // Remove leading '#' if present
    if (fragment.startsWith('#')) {
      fragment = fragment.substring(1);
    }

    // Ensure it starts with '/'
    if (!fragment.startsWith('/')) {
      fragment = '/$fragment';
    }

    // Parse fragment as URI to extract path segments
    try {
      final fragUri = Uri.parse(fragment);
      segments = fragUri.pathSegments.where((s) => s.isNotEmpty).toList();
    } on Object {
      // If parsing fails, try splitting by '/'
      segments = fragment.split('/').where((s) => s.isNotEmpty).toList();
    }
  }

  segments =
      segments
          .map((segment) => segment.trim())
          .where((segment) => segment.isNotEmpty && segment != '#')
          .toList();

  if (segments.isEmpty) return const [];
  return segments
      .map((name) => EncodedRouteSegment(name, const <String, Object?>{}))
      .toList();
}
