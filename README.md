# Prism Router

A declarative navigation package for Flutter that provides a clean, type-safe approach to managing navigation state using the Navigator 2.0 API.

## Overview

Prism Router simplifies Flutter's Navigator 2.0 implementation by providing:

- **Declarative Navigation**: Manage navigation state as a list of pages
- **Type-Safe Pages**: Define custom page types with compile-time safety
- **Simple API**: Easy-to-use context extensions like `context.push()`, `context.pop()`
- **Navigation Guards**: Apply rules to control navigation flow
- **State Observation**: Track navigation history and state changes
- **Custom Transitions**: Define custom page transitions per route
- **Back Button Handling**: Custom back button behavior support
- **Web Support**: URL sync (hash routing) + browser back/forward support, with argument restore via browser history state

## Features

- ✅ Declarative navigation with immutable state
- ✅ Type-safe page definitions using sealed classes
- ✅ Simple context extension methods (`context.push()`, `context.pop()`, etc.)
- ✅ Navigation guards for access control and validation
- ✅ Navigation history tracking with observer pattern
- ✅ Custom page transitions support
- ✅ Deep linking support through Navigator 2.0
- ✅ Browser history integration on Flutter web (forward/back/refresh)
- ✅ Web URL sync (hash routing) for deep linking + refresh
- ✅ Preserves page `arguments` across browser back/forward (and refresh when possible) via browser history state (JSON-encodable only)

## Getting Started

### Installation

Add Prism Router to your `pubspec.yaml`:

```yaml
dependencies:
  prism_router: ^0.1.0
```

Then run:

```bash
flutter pub get
```

## Complete Setup Guide

### Step 1: Define Your Pages

Create custom page types by extending `PrismPage`. Each page represents a route in your app.

```dart
import 'package:prism_router/prism_router.dart';
import 'package:flutter/material.dart';

// Base class for all app pages
@immutable
sealed class AppPage extends PrismPage {
  const AppPage({
    required super.name,
    required super.child,
    super.arguments,
    super.tags,
    super.key,
  });

  @override
  String toString() => '/$name${arguments.isEmpty ? '' : '~$arguments'}';
}

// Simple page without parameters
final class HomePage extends AppPage {
  const HomePage() : super(child: const HomeScreen(), name: 'home');

  @override
  PrismPage pageBuilder(Map<String, Object?> _) => const HomePage();
}

// Page with required parameters
final class SettingsPage extends AppPage {
  SettingsPage({required this.data})
      : super(
          child: SettingsScreen(data: data),
          name: 'settings',
          tags: {'settings'}, // Tags for filtering/identification
          arguments: {'data': data}, // Arguments for web refresh support
        );

  final String data;

  @override
  PrismPage pageBuilder(Map<String, Object?> arguments) {
    // Pattern matching - type-safe, no cast needed!
    if (arguments case {'data': String data}) {
      return SettingsPage(data: data);
    }
    // Fallback if pattern doesn't match
    return SettingsPage(data: arguments['data'] as String? ?? '');
  }
}

// Page with multiple parameters
final class DetailsPage extends AppPage {
  DetailsPage({required this.userId, required this.note})
      : super(
          name: 'details',
          child: DetailsScreen(userId: userId, note: note),
          tags: {'details'},
          arguments: {'userId': userId, 'note': note},
        );

  final String userId;
  final String note;

  @override
  PrismPage pageBuilder(Map<String, Object?> arguments) {
    if (arguments case {
      'userId': String userId,
      'note': String note,
    }) {
      return DetailsPage(userId: userId, note: note);
    }
    return DetailsPage(
      userId: arguments['userId'] as String? ?? '',
      note: arguments['note'] as String? ?? '',
    );
  }
}
```

**Important Notes:**
- Use `sealed class` for type safety and exhaustive pattern matching
- Always implement `pageBuilder()` for pages with parameters (needed for web refresh)
- Pass data through `arguments` map for in-memory passing (not serialized into the URL by default)
- Use `tags` to identify pages for filtering or guards

### Step 2: Create Your Screens

Create the actual screen widgets that will be displayed:

```dart
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Home')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () => context.push(SettingsPage(data: 'Hello')),
                child: const Text('Go to Settings'),
              ),
            ],
          ),
        ),
      );
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({required this.data, super.key});

  final String data;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Settings'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: context.pop,
          ),
        ),
        body: Center(child: Text('Data: $data')),
      );
}
```

### Step 3: Set Up Router

Configure the router in your app:

```dart
import 'package:prism_router/prism_router.dart';
import 'package:flutter/material.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  late final RouterConfig<Object> _router;

  @override
  void initState() {
    super.initState();
    
    // Define all pages that can be rebuilt from URL (for web support)
    final appPages = [
      const HomePage(),
      SettingsPage(data: ''),
      DetailsPage(userId: '', note: ''),
    ];

    // Define navigation guards
    final guards = <PrismGuard>[
      // Ensure stack is never empty
      (context, state) => state.isEmpty ? [const HomePage()] : state,
      
      // Example: Authentication guard
      // (context, state) {
      //   final isAuthenticated = AuthService.isAuthenticated();
      //   if (!isAuthenticated && state.any((p) => p.tags.contains('protected'))) {
      //     return [const LoginPage()];
      //   }
      //   return state;
      // },
    ];

    _router = PrismRouter.router(
      pages: appPages, // Required for web refresh support
      initialStack: [const HomePage()], // Initial navigation stack
      guards: guards, // Navigation guards
    );
  }

  @override
  Widget build(BuildContext context) => MaterialApp.router(
        title: 'Prism Router Example',
        routerConfig: _router,
      );
}
```

**Key Points:**
- `pages`: List of all pages that can be rebuilt from URL (needed for web refresh)
- `initialStack`: The initial navigation stack when app starts
- `guards`: Functions that intercept and modify navigation state
- Always provide `pages` parameter for web support

---

## Optional: Auto-route-like code generation (annotations)

If you don’t want to manually write `PrismPage` wrappers and `pageBuilder()` for
each screen, Prism Router supports an **optional annotation + codegen workflow**
via two extra packages in this repo:

- `prism_router_annotations`
- `prism_router_generator`

### 1) Add dependencies

```yaml
dependencies:
  prism_router: ^0.1.0
  prism_router_annotations: ^0.1.0

dev_dependencies:
  build_runner: ^2.4.13
  prism_router_generator: ^0.1.0
```

### 2) Create a router entrypoint file

Create `lib/app_router.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:prism_router/prism_router.dart';
import 'package:prism_router_annotations/prism_router_annotations.dart';

import 'feature/home/home_screen.dart';
import 'feature/profile/profile_screen.dart';
import 'feature/settings/settings_screen.dart';
import 'feature/details/details_screen.dart';

part 'app_router.g.dart';

@PrismRouterConfig()
class AppRouter {}
```

**Tip (optional): auto-import screens**

Because `app_router.g.dart` is generated as a Dart `part`, it can’t declare its
own imports. If you don’t want to keep adding screen imports manually, you can
instead add a **single** generated import (created by codegen):

```dart
import 'app_router.imports.g.dart';
```

### 3) Annotate your screens

```dart
import 'package:prism_router_annotations/prism_router_annotations.dart';

@PrismRoute(initial: true)
class HomeScreen extends StatelessWidget { /* ... */ }

@PrismRoute(tags: {'settings'}, transition: PrismTransition.zoom)
class SettingsScreen extends StatelessWidget { /* ... */ }
```

### 4) Run codegen

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

This generates:
- `HomePage`, `SettingsPage`, ... (as `PrismPage` wrappers)
- `appRoutes` (`List<PrismRouteDefinition>`)
- `initialStack` (`List<PrismPage>`)
- `buildPrismRouterConfig(...)` (`RouterConfig<Object>`)

### 5) Use the generated router config

```dart
MaterialApp.router(
  routerConfig: buildPrismRouterConfig(
    webHistoryMode: PrismWebHistoryMode.replace,
  ),
);
```

### Current limitations

- Only **named constructor parameters** are supported on annotated screens.
- `@PrismRoute.path` must be a **single segment** (e.g. `/home`), because Prism
  Router composes URLs from a stack: `/#/home/profile/details`.

## Navigation Methods - Complete Guide

Prism Router provides simple and powerful context extension methods for navigation. Here's a complete guide to each method:

### 1. `context.push(PrismPage page)`

**Purpose:** Push a new page onto the navigation stack.

**When to use:** When you want to navigate to a new screen while keeping the current screen in the stack (user can go back).

**Example:**
```dart
// Navigate to settings page
context.push(SettingsPage(data: 'Hello from home'));

// Navigate to details page
context.push(DetailsPage(userId: '123', note: 'User details'));
```

**Behavior:**
- Adds the page to the top of the stack
- Previous pages remain in the stack
- User can go back using back button or `context.pop()`
- Prevents pushing the same page twice (if already at top)

**Use Cases:**
- Navigating to detail screens
- Opening settings or profile pages
- Any navigation where you want back button functionality

---

### 2. `context.pop()`

**Purpose:** Remove the current page from the navigation stack (go back).

**When to use:** When you want to go back to the previous screen.

**Example:**
```dart
// Simple pop
context.pop();

// Conditional pop
if (context.canPop) {
  context.pop();
}

// In AppBar back button
AppBar(
  leading: IconButton(
    icon: const Icon(Icons.arrow_back),
    onPressed: context.pop,
  ),
)
```

**Behavior:**
- Removes the top page from the stack
- Returns to the previous page
- Does nothing if only one page in stack

**Use Cases:**
- Back button functionality
- Cancel actions
- Closing modals or detail screens

---

### 3. `context.canPop`

**Purpose:** Check if a page can be popped (if there's a page to go back to).

**When to use:** Before calling `pop()` to avoid errors, or to conditionally show/hide back button.

**Example:**
```dart
// Conditional back button
if (context.canPop) {
  IconButton(
    icon: const Icon(Icons.arrow_back),
    onPressed: context.pop,
  ),
}

// Safe pop
if (context.canPop) {
  context.pop();
}
```

---

### 4. `context.pushReplacement(PrismPage page)`

**Purpose:** Replace the current page with a new page (remove current, add new).

**When to use:** When you want to replace the current screen and don't want user to go back to it.

**Example:**
```dart
// After login, replace login page with home
context.pushReplacement(const HomePage());

// After form submission, replace form with success page
context.pushReplacement(SuccessPage(message: 'Form submitted'));
```

**Behavior:**
- Removes the current top page
- Adds the new page at the top
- User cannot go back to the replaced page
- If stack is empty, it pushes instead
- Prevents replacing with the same page

**Use Cases:**
- Login/authentication flows
- Form submission flows
- Onboarding flows
- Any scenario where you don't want back navigation

---

### 5. `context.pushAndRemoveAll(PrismPage page)` ⭐

**Purpose:** Push a new page and remove ALL previous pages from the stack (reset the in-app stack).

**When to use:** When you want to start fresh with a new page and clear in-app navigation history.

**Example:**
```dart
// After logout, clear everything and go to login
context.pushAndRemoveAll(const LoginPage());

// After completing onboarding, clear and go to home
context.pushAndRemoveAll(const HomePage());

// From details screen, go directly to home (clears all history)
context.pushAndRemoveAll(const HomePage());
```

**Behavior:**
- Removes all pages from the stack
- Adds the new page as the only page
- User cannot go back (no previous pages)
- **On web:** Updates the URL (hash routing) to match the new stack
- Equivalent to `setStack([page])`

**Web Behavior:**
- Uses Router URL integration to keep the browser URL in sync (hash routing)
- Browser back/forward behavior depends on the tab/session history and URL strategy

**Use Cases:**
- Logout functionality
- Completing onboarding
- Resetting app state
- Deep link navigation
- Resetting navigation state

---

### 6. `context.pushAndRemoveUntil(PrismPage page, bool Function(PrismPage) predicate)`

**Purpose:** Push a new page and remove previous pages until a condition is met.

**When to use:** When you want to keep some pages in the stack but remove others.

**Example:**
```dart
// Remove all pages until home page is found
context.pushAndRemoveUntil(
  const ProfilePage(),
  (page) => page.name == 'home',
);
// Result: [HomePage, ProfilePage]

// Remove all pages until a page with 'auth' tag is found
context.pushAndRemoveUntil(
  const DashboardPage(),
  (page) => page.tags.contains('auth'),
);

// Remove all pages until home or settings
context.pushAndRemoveUntil(
  const DetailsPage(userId: '123', note: ''),
  (page) => page.name == 'home' || page.name == 'settings',
);
```

**Behavior:**
- Searches backwards through the stack
- Keeps pages until predicate returns `true`
- Adds the new page at the top
- If predicate never returns true, removes all pages

**Use Cases:**
- Navigating to a page but keeping home in stack
- Authentication flows (keep login, remove other pages)
- Complex navigation scenarios

---

### 7. `context.setStack(List<PrismPage> pages)`

**Purpose:** Replace the entire navigation stack with a new set of pages.

**When to use:** When you need complete control over the navigation stack.

**Example:**
```dart
// Set stack to specific pages
context.setStack([
  const HomePage(),
  const SettingsPage(data: ''),
  const DetailsPage(userId: '123', note: ''),
]);

// Reset to just home
context.setStack([const HomePage()]);

// Set complex navigation flow
context.setStack([
  const HomePage(),
  const CategoryPage(categoryId: '1'),
  const ProductPage(productId: '42'),
]);
```

**Behavior:**
- Completely replaces the current stack
- Sets the stack to exactly the provided pages
- Guards are still applied to the new stack

**Use Cases:**
- Deep linking
- Complex navigation flows
- Programmatic navigation
- Resetting navigation state

---

### 8. `context.transformStack(List<PrismPage> Function(List<PrismPage>) transform)`

**Purpose:** Apply a custom transformation to the navigation stack.

**When to use:** For advanced navigation scenarios where you need fine-grained control.

**Example:**
```dart
// Remove all settings pages
context.transformStack((stack) {
  return stack.where((page) => page.name != 'settings').toList();
});

// Remove pages with specific tag
context.transformStack((stack) {
  return stack.where((page) => !page.tags.contains('temporary')).toList();
});

// Insert a page at specific position
context.transformStack((stack) {
  final newStack = List<PrismPage>.from(stack);
  newStack.insert(1, const MiddlePage());
  return newStack;
});
```

**Behavior:**
- Applies your custom function to the current stack
- Your function receives the current stack and returns the new stack
- Guards are applied to the result
- Empty stack is not allowed (will be ignored)

**Use Cases:**
- Removing specific pages
- Filtering pages by tags
- Reordering pages
- Complex navigation logic
- Custom navigation patterns

---

### 9. `context.prism` - Direct Controller Access

**Purpose:** Access the PrismController directly for advanced operations.

**When to use:** When you need access to controller properties or methods not exposed via extensions.

**Example:**
```dart
// Get current navigation stack
final stack = context.prism.state;
print('Current stack: ${stack.map((p) => p.name).join(" -> ")}');

// Check if at initial state
if (context.prism.isAtInitialState) {
  print('At initial state');
}

// Access observer
final observer = context.prism.observer;
observer.addListener(() {
  print('Navigation changed: ${observer.value}');
});
```

**Available Properties:**
- `state`: Current navigation stack (`List<PrismPage>`)
- `observer`: Navigation state observer (`PrismStateObserver`)
- `isAtInitialState`: Whether stack matches initial pages

---

## Navigation State Management

### Accessing Current Stack

```dart
// Get current navigation stack
final stack = context.prism.state;

// Display stack in UI
Widget build(BuildContext context) {
  final stack = context.prism.state;
  return Column(
    children: [
      Text('Current stack:'),
      ...stack.map((page) => Text('/${page.name}')),
    ],
  );
}

// Check stack length
if (context.prism.state.length > 1) {
  // Multiple pages in stack
}
```

### Observing Navigation Changes

```dart
class MyScreen extends StatefulWidget {
  @override
  State<MyScreen> createState() => _MyScreenState();
}

class _MyScreenState extends State<MyScreen> {
  late final PrismStateObserver _observer;

  @override
  void initState() {
    super.initState();
    _observer = context.prism.observer;
    _observer.addListener(_onNavigationChanged);
  }

  void _onNavigationChanged() {
    print('Navigation changed: ${_observer.value}');
    // Update UI based on navigation changes
    setState(() {});
  }

  @override
  void dispose() {
    _observer.removeListener(_onNavigationChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentPage = context.prism.state.last;
    return Text('Current page: ${currentPage.name}');
  }
}
```

---

## Navigation Guards

Guards are functions that intercept and modify navigation state changes. They run before any navigation happens.

### Basic Guard Example

```dart
final guards = <PrismGuard>[
  // Ensure stack is never empty
  (context, state) => state.isEmpty ? [const HomePage()] : state,
];
```

### Authentication Guard

```dart
final guards = <PrismGuard>[
  (context, state) {
    final isAuthenticated = AuthService.isAuthenticated();
    
    // If not authenticated and trying to access protected page
    if (!isAuthenticated && state.any((page) => page.tags.contains('protected'))) {
      return [const LoginPage()];
    }
    
    // If authenticated and on login page, redirect to home
    if (isAuthenticated && state.last.name == 'login') {
      return [const HomePage()];
    }
    
    return state;
  },
];
```

### Role-Based Guard

```dart
final guards = <PrismGuard>[
  (context, state) {
    final userRole = UserService.getCurrentRole();
    
    // Check if user has access to admin pages
    if (state.any((page) => page.tags.contains('admin'))) {
      if (userRole != 'admin') {
        return [const UnauthorizedPage()];
      }
    }
    
    return state;
  },
];
```

### Multiple Guards

Guards run in order, each receiving the result of the previous guard:

```dart
final guards = <PrismGuard>[
  // First: Ensure stack is not empty
  (context, state) => state.isEmpty ? [const HomePage()] : state,
  
  // Second: Check authentication
  (context, state) {
    if (!AuthService.isAuthenticated() && 
        state.any((p) => p.tags.contains('protected'))) {
      return [const LoginPage()];
    }
    return state;
  },
  
  // Third: Check permissions
  (context, state) {
    if (state.any((p) => p.tags.contains('premium')) && 
        !SubscriptionService.isPremium()) {
      return [const UpgradePage()];
    }
    return state;
  },
];
```

---

## Custom Page Transitions

You can define custom transitions for each page:

```dart
final class SettingsPage extends AppPage {
  SettingsPage({required String data})
      : super(child: SettingsScreen(data: data), name: 'settings');

  @override
  Route<void> createRoute(BuildContext context) => 
      CustomMaterialRoute(page: this);
}

class CustomMaterialRoute extends PageRoute<void> {
  CustomMaterialRoute({required AppPage page}) : super(settings: page);

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    // Fade transition
    return FadeTransition(
      opacity: animation,
      child: child,
    );
    
    // Or slide transition
    // return SlideTransition(
    //   position: Tween<Offset>(
    //     begin: const Offset(1.0, 0.0),
    //     end: Offset.zero,
    //   ).animate(animation),
    //   child: child,
    // );
  }

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) => child;

  @override
  bool get maintainState => true;

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  Duration get transitionDuration => const Duration(milliseconds: 300);
}
```

---

## Web Support

Prism Router automatically syncs navigation state with browser URL, enabling:

- Browser back/forward buttons
- Page refresh (restores navigation stack)
- Direct URL navigation
- Shareable URLs
- Hash-based routing (safe default without server rewrite rules)

### Setup for Web

```dart
_router = PrismRouter.router(
  pages: [
    const HomePage(),
    SettingsPage(data: ''),
    DetailsPage(userId: '', note: ''),
  ],
  initialStack: [const HomePage()],
  guards: guards,
);
```

**Important:**
- Always provide `pages` parameter for web support
- Implement `pageBuilder()` in all pages with parameters
- Pass data through `arguments` map (not serialized into the URL; on web it can be restored from browser history state when possible)

### URL Structure

- Simple page: `/home`
- Nested stack: `/home/profile/details`

**Note about arguments:** Prism Router keeps URLs clean and **does not serialize `arguments` into the URL**. On Flutter web, it stores **JSON‑encodable** arguments in **browser history state** (`RouteInformation.state`) so browser **back/forward** (and **refresh**, when the browser preserves `history.state`) can restore arguments. Non‑JSON values are dropped.

### Browser History Clearing (Web)

`pushAndRemoveAll()` always clears the **in-app navigation stack** (Navigator pages). On Flutter web, Prism Router also performs a **best‑effort session history reset** so a single browser **Back** does not return to previously visited in‑app routes (it rewinds to the start of the current Prism session and truncates forward history).

**Example:**
```dart
// Reset the in-app stack to home
context.pushAndRemoveAll(const HomePage());
```

---

## Best Practices

### 1. Use Sealed Classes for Type Safety

```dart
@immutable
sealed class AppPage extends PrismPage {
  // ... base implementation
}
```

### 2. Always Implement `pageBuilder()` for Pages with Parameters

```dart
@override
PrismPage pageBuilder(Map<String, Object?> arguments) {
  if (arguments case {'data': String data}) {
    return SettingsPage(data: data);
  }
  return SettingsPage(data: '');
}
```

### 3. Use Tags for Page Identification

```dart
SettingsPage({required this.data})
    : super(
        name: 'settings',
        tags: {'settings', 'preferences'}, // Use tags for filtering
        // ...
      );
```

### 4. Prefer Simple Methods Over Complex Transformations

```dart
// ✅ Good: Simple and clear
context.push(const HomePage());

// ❌ Avoid: Overly complex
context.transformStack((stack) {
  // Complex logic...
});
```

### 5. Use Guards for Cross-Cutting Concerns

```dart
// ✅ Good: Authentication in guards
final guards = [
  (context, state) {
    if (!isAuthenticated && state.any((p) => p.tags.contains('protected'))) {
      return [const LoginPage()];
    }
    return state;
  },
];

// ❌ Avoid: Checking in every screen
```

### 6. Handle Navigation State Changes Properly

```dart
// ✅ Good: Listen to observer
_observer.addListener(() {
  setState(() {}); // Update UI
});

// ❌ Avoid: Direct state access without listening
```

---

## Common Patterns

### Pattern 1: Login Flow

```dart
// After successful login
context.pushAndRemoveAll(const HomePage());

// Or replace login with home
context.pushReplacement(const HomePage());
```

### Pattern 2: Detail Screen Navigation

```dart
// Navigate to detail
context.push(DetailsPage(userId: userId, note: note));

// Back button automatically works
```

### Pattern 3: Bottom Navigation with Stack

```dart
// Keep home in stack, navigate to profile
context.pushAndRemoveUntil(
  const ProfilePage(),
  (page) => page.name == 'home',
);
```

### Pattern 4: Deep Link Handling

```dart
// Set complete stack from deep link
context.setStack([
  const HomePage(),
  const CategoryPage(categoryId: '1'),
  const ProductPage(productId: '42'),
]);
```

### Pattern 5: Conditional Navigation

```dart
if (user.isLoggedIn) {
  context.push(const DashboardPage());
} else {
  context.push(const LoginPage());
}
```

### Pattern 6: Logout with History Clearing

```dart
// Logout and clear all navigation history
// On web, the URL will be updated to match the new stack
context.pushAndRemoveAll(const LoginPage());
```

---

## Troubleshooting

### Issue: Navigation not working

**Solution:** Make sure you're using `context.push()` inside a widget that has access to the router context.

### Issue: Web refresh not working

**Solution:** 
1. Provide `pages` parameter in `PrismRouter.router()`
2. Implement `pageBuilder()` in all pages with parameters
3. Pass data through `arguments` map

### Issue: Back button not working

**Solution:** Use `context.pop()` or let Flutter handle it automatically with `AppBar`.

### Issue: Guards blocking navigation

**Solution:** Check your guard logic - guards should return a valid state, not empty list.

### Issue: Same page pushed twice

**Solution:** This is prevented automatically. If you need to push the same page, use `pushReplacement()` or `setStack()`.

### Issue: Browser history not clearing on web

**Solution:** `pushAndRemoveAll()` clears the in-app stack. On web, browser back/forward behavior depends on the tab/session history and URL strategy; Prism Router focuses on consistent Router-based URL synchronization.

---

## API Reference

### PrismRouter

```dart
PrismRouter.router({
  required List<PrismPage> initialStack,
  List<PrismPage>? pages,
  List<PrismRouteDefinition>? routes,
  PrismGuard guards = const [],
  List<NavigatorObserver> observers = const [],
  TransitionDelegate<Object> transitionDelegate = const DefaultTransitionDelegate<Object>(),
  String? restorationScopeId,
})
```

### PrismController (via `context.prism`)

- `state`: Current navigation stack (`List<PrismPage>`)
- `observer`: Navigation state observer (`PrismStateObserver`)
- `isAtInitialState`: Whether stack matches initial pages
- `push(PrismPage)`: Push a page
- `pop()`: Pop current page
- `pushReplacement(PrismPage)`: Replace top page
- `pushAndRemoveUntil(PrismPage, predicate)`: Push and remove until
- `pushAndRemoveAll(PrismPage)`: Push and remove all (reset in-app stack)
- `setStack(List<PrismPage>)`: Set the navigation stack
- `transformStack(transform)`: Custom transformation

### Context Extensions

| Method | Description |
|--------|-------------|
| `context.push(PrismPage)` | Push a new page onto the stack |
| `context.pop()` | Pop the current page |
| `context.canPop` | Check if a page can be popped |
| `context.pushReplacement(PrismPage)` | Replace the top page |
| `context.pushAndRemoveAll(PrismPage)` | Push and remove all previous pages (reset in-app stack) |
| `context.pushAndRemoveUntil(PrismPage, predicate)` | Push and remove until condition |
| `context.setStack(List<PrismPage>)` | Set the navigation stack to specific pages |
| `context.transformStack(transform)` | Apply custom transformation to the stack |
| `context.prism` | Access the PrismController directly |

---

## Complete Example

Check out the [example](example/) directory for a complete working application demonstrating all features.

The example includes:
- Home screen with navigation options
- Settings page with custom transitions
- Profile page
- Details page with arguments
- Stack reset demonstration
- Navigation state observation

---

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## Issues

File issues and feature requests at the [GitHub issue tracker](https://github.com/nurmuhammad0126/prism_router/issues).

## License

This package is licensed under the terms specified in the LICENSE file.

## Author

Created and maintained by [Miracle-Blue](https://github.com/Miracle-Blue).
