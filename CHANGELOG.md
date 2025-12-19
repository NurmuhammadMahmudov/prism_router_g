## 0.1.0

### 🎉 Major Features

* **Complete Browser History Clearing**: `pushAndRemoveAll()` now properly clears all browser history on web, not just the current entry. Uses `history.go()` to navigate back to the first entry, then replaces it with the new URL. This ensures that browser back button won't navigate to old pages.

* **Migrated to Modern Web APIs**: Replaced deprecated `dart:html` with `package:web` and modern web APIs for better compatibility and future-proofing.

* **Improved URL Handling**: Enhanced `restoreRouteInformation` to prevent creating duplicate history entries when URL already matches the desired state.

* **Better State Comparison**: Added robust state comparison logic to prevent unnecessary `notifyListeners` calls and improve performance.

### ✨ Enhancements

* **Argument Preservation**: `setFromRouter` now preserves arguments from current state if incoming page has empty arguments but same name.

* **Duplicate Prevention**: Added validation to prevent pushing the same page twice or replacing with the same page.

* **Initial State Detection**: Improved `isAtInitialState` to compare both `name` and `key` for exact matches.

* **Back Button Handling**: Enhanced back button handling to properly check `isAtInitialState` before allowing pop operations.

### 🐛 Bug Fixes

* Fixed `Assertion failed: !keyReservation.contains(key)` error by using `identityHashCode(this)` for unique page keys.

* Fixed browser history not being fully cleared on web when using `pushAndRemoveAll()`.

* Fixed URL path issues on web (`/home#/home` and `##/home` double hash problems).

* Fixed arguments being lost during navigation and navigation repeating issues.

* Fixed back button being active on initial state when it shouldn't be.

* Fixed router creating new history entries after `location.replace()` on web.

### 📝 Documentation

* **BREAKING**: Renamed `resetTo()` to `setStack()` for better clarity
* **BREAKING**: Renamed `change()` to `transformStack()` for better clarity
* Removed deprecated methods: `reset()` and `replaceTop()`
* Removed duplicate code in context extensions - simplified `push()` method
* Improved code quality and documentation
* Enhanced README with comprehensive navigation guide and web history clearing explanation
* Updated examples to use new method names
* Better method naming for improved developer experience

### 🔧 Technical Changes

* Updated `web_history_web.dart` to use `package:web` instead of `dart:html`
* Improved `clearAndSetBrowserHistory` implementation to properly clear all history entries
* Added `_mapsEqual` helper function for robust map comparison
* Enhanced `_setState` with better comparison logic using `listEquals` and `_mapsEqual`
* Updated `setNewRoutePath` in `PrismRouterDelegate` to prevent unnecessary state updates

### 📦 Dependencies

* Added `web: ^0.5.0` dependency for modern web support

---

## 0.0.1

### 🎉 Initial Release

* Initial public release of the **Prism Router** package
* First stable version of the `PrismRouter.router` API for Navigator 2.0
* Includes route definitions, guards, browser history integration, and context extensions
* Simple context extension methods: `context.push()`, `context.pop()`, `context.pushReplacement()`, etc.
* Navigation state management with `PrismController`
* Type-safe page definitions using sealed classes
* Navigation guards for access control and validation
* Navigation history tracking with observer pattern
* Custom page transitions support
* Deep linking support through Navigator 2.0
* Browser history integration on Flutter web (forward/back/refresh)

### Core Features

* Declarative navigation with immutable state
* Type-safe page definitions
* Simple context extension methods
* Navigation guards
* State observation
* Custom transitions
* Back button handling
* Web support with URL synchronization
