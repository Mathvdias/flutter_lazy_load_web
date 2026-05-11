# Changelog

## 0.1.0

- Initial release.
- `DeferredWidget` — wraps deferred library loading with loading/error states.
- `DeferredWidget.preload` — warms up a single chunk.
- `DeferredWidget.preloadAll` — warms up multiple chunks concurrently.
- `DeferredWidget.isLoaded` — queries the cache without triggering a load.
- `DeferredWidget.reset` — clears state for testing.
- `animationDuration` parameter for the `AnimatedSwitcher` cross-fade.
- Zero external dependencies.
