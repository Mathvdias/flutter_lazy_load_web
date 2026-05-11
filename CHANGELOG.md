# Changelog

## 0.1.2

- Extract default error widget strings into a private `_Strings` constants class (`lib/src/strings.dart`), making future localisation or customisation straightforward.
- Shorten pubspec description to comply with pub.dev 60–180 character limit.
- Remove redundant `flutter/foundation.dart` import (already provided by `flutter/material.dart`).

## 0.1.1

- Add `lazy()` top-level function — use directly as a go_router (or any router)
  `builder:` argument, eliminating the anonymous closure boilerplate.
- Works without importing go_router; generic type `S` is inferred from the
  call-site.

## 0.1.0

- Initial release.
- `DeferredWidget` — wraps deferred library loading with loading/error states.
- `DeferredWidget.preload` — warms up a single chunk.
- `DeferredWidget.preloadAll` — warms up multiple chunks concurrently.
- `DeferredWidget.isLoaded` — queries the cache without triggering a load.
- `DeferredWidget.reset` — clears state for testing.
- `animationDuration` parameter for the `AnimatedSwitcher` cross-fade.
- Zero external dependencies.
