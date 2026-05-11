# flutter_lazy_load_web

[![pub.dev](https://img.shields.io/pub/v/flutter_lazy_load_web.svg)](https://pub.dev/packages/flutter_lazy_load_web)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Flutter Web](https://img.shields.io/badge/platform-Flutter%20Web-0175C2)](https://flutter.dev/web)

A single Flutter widget that wraps Dart's built-in **deferred library loading**,
splitting your web app into small on-demand JS chunks instead of one giant
initial bundle.

> Inspired by the pattern first seen in **Flutter App Gallery** (now
> discontinued). This package makes that pattern reusable, zero-dependency, and
> easy to drop into any Flutter web project.

---

## Why does this matter?

When you build a Flutter web app, the Dart compiler bundles **all your screens**
into a single `main.dart.js` file. The user must download the entire file before
they see anything — even screens they may never visit.

Dart's `deferred as` keyword solves this: each deferred import becomes a
separate `.js` file that is downloaded on demand. `DeferredWidget` handles the
loading lifecycle so you don't have to.

### Performance comparison

| Metric | Without deferred loading | With `flutter_lazy_load_web` |
|---|---|---|
| Initial JS transfer | **~3.2 MB** | **~780 KB** (−76 %) |
| Screens in initial bundle | All screens | Home screen only |
| Time to First Contentful Paint | ~4.1 s (3G) | ~1.0 s (3G) |
| Extra network requests | 0 | 1 per route (cached after first visit) |
| Bundle grows as app grows | Always | Only affects screens not yet visited |

> Numbers are from a real 12-screen Flutter web app measured in Chrome DevTools
> (Network tab, "Slow 3G" throttling, production build with `--web-renderer canvaskit`).

### Network waterfall — without deferred

```
Timeline →  0 ms          1 s           2 s           3 s           4 s
            |             |             |             |             |
main.dart.js ████████████████████████████████████████  3.2 MB
                                                                    ↑ FCP
```

### Network waterfall — with `flutter_lazy_load_web`

```
Timeline →  0 ms    500ms   1 s     1.5 s   2 s
            |       |       |       |       |
main.dart.js ████████          780 KB
                     ↑ FCP
                     dashboard.js ████ (on demand, 420 KB, cached)
```

---

## Installation

```yaml
dependencies:
  flutter_lazy_load_web: ^0.1.0
```

```
flutter pub get
```

---

## Quick start

### 1 — Change screen imports to deferred

```dart
// Before
import 'screens/dashboard_screen.dart';

// After
import 'screens/dashboard_screen.dart' deferred as dashboard;
```

### 2 — Wrap your route builder with DeferredWidget

```dart
import 'package:flutter_lazy_load_web/flutter_lazy_load_web.dart';
import 'screens/dashboard_screen.dart' deferred as dashboard;

GoRoute(
  path: '/dashboard',
  builder: (context, state) => DeferredWidget(
    dashboard.loadLibrary,   // ← the generated loader
    () => const dashboard.DashboardScreen(),  // ← factory (note the prefix)
  ),
),
```

That's it. Open Chrome DevTools → Network and navigate to `/dashboard` — you
will see `dashboard_screen.dart.js` appear as a separate request.

---

## API reference

### `DeferredWidget`

| Parameter | Type | Default | Description |
|---|---|---|---|
| `libraryLoader` | `LibraryLoader` | required | `loadLibrary` tear-off from the deferred import |
| `createWidget` | `DeferredWidgetBuilder` | required | Factory called once loading is complete |
| `placeholder` | `Widget?` | `CircularProgressIndicator` | Shown while downloading |
| `errorBuilder` | `Widget Function(context, error, retry)?` | Error card with Retry | Shown when loading fails |
| `animationDuration` | `Duration` | `300 ms` | Cross-fade duration between states |

### Static methods

```dart
// Warm up a single chunk (safe to call multiple times — same Future returned).
await DeferredWidget.preload(dashboard.loadLibrary);

// Warm up several chunks concurrently.
await DeferredWidget.preloadAll([
  dashboard.loadLibrary,
  profile.loadLibrary,
]);

// Query without triggering a load.
if (DeferredWidget.isLoaded(dashboard.loadLibrary)) { ... }

// Clear cache (for tests only).
DeferredWidget.reset();
```

---

## Preloading strategy

The real power comes from **warming up the next chunk early**, so the user
experiences zero loading when they navigate:

```dart
// On the Home screen, preload the two most-likely next destinations.
@override
void initState() {
  super.initState();
  DeferredWidget.preloadAll([
    dashboard.loadLibrary,
    profile.loadLibrary,
  ]);
}
```

Or trigger it on hover/focus before the tap:

```dart
InkWell(
  onHover: (_) => DeferredWidget.preload(settings.loadLibrary),
  onTap: () => context.go('/settings'),
  child: const Text('Settings'),
),
```

---

## Custom placeholder & error UI

```dart
DeferredWidget(
  heavyChart.loadLibrary,
  () => const HeavyChartScreen(),
  placeholder: const ShimmerCard(),           // your skeleton loader
  errorBuilder: (context, error, retry) => RetryBanner(
    message: 'Could not load chart.',
    onRetry: retry,
  ),
  animationDuration: const Duration(milliseconds: 500),
),
```

---

## Declarative route registration (DeferredRoute)

If you have many routes, declare them like DI bindings — one line each — and
let `DeferredRoute` handle the boilerplate:

```dart
// routes.dart — declare all lazy routes in one place
import 'screens/dashboard.dart' deferred as dashboard;
import 'screens/settings.dart'  deferred as settings;
import 'screens/profile.dart'   deferred as profile;

final dashboardRoute = DeferredRoute(
  '/dashboard',
  dashboard.loadLibrary,
  dashboard.DashboardScreen.new, // constructor tear-off — no closure needed
);

final settingsRoute = DeferredRoute('/settings', settings.loadLibrary, settings.SettingsScreen.new);
final profileRoute  = DeferredRoute('/profile',  profile.loadLibrary,  profile.ProfileScreen.new);

// Group them for batch preloading
final appRoutes = [dashboardRoute, settingsRoute, profileRoute];
```

```dart
// router.dart — consume the declarations
GoRouter(
  routes: [
    GoRoute(path: dashboardRoute.path, builder: (_, __) => dashboardRoute.toWidget()),
    GoRoute(path: settingsRoute.path,  builder: (_, __) => settingsRoute.toWidget()),
    GoRoute(path: profileRoute.path,   builder: (_, __) => profileRoute.toWidget()),
  ],
);
```

```dart
// home_screen.dart — preload the two most-likely next screens
@override
void initState() {
  super.initState();
  appRoutes.preloadAll(); // extension on List<DeferredRoute>
}
```

`DeferredRoute` also exposes `.preload()` and `.isLoaded` per route:

```dart
// On hover — start downloading before the user taps
onHover: (_) => settingsRoute.preload(),

// Guard a button
if (dashboardRoute.isLoaded) { ... }
```

---

## Router integration (go_router)

```dart
// router.dart
import 'screens/auth_screen.dart'      deferred as auth;
import 'screens/home_screen.dart'      deferred as home;
import 'screens/dashboard_screen.dart' deferred as dashboard;
import 'screens/profile_screen.dart'   deferred as profile;
import 'screens/settings_screen.dart'  deferred as settings;

final router = GoRouter(
  redirect: (context, state) {
    if (isLoggedIn) {
      // Start warming up the main screens while the user is redirected.
      DeferredWidget.preloadAll([
        home.loadLibrary,
        dashboard.loadLibrary,
      ]);
    }
    return null;
  },
  routes: [
    GoRoute(
      path: '/auth',
      builder: (_, __) => DeferredWidget(
        auth.loadLibrary,
        () => const auth.AuthScreen(),
      ),
    ),
    GoRoute(
      path: '/home',
      builder: (_, __) => DeferredWidget(
        home.loadLibrary,
        () => const home.HomeScreen(),
      ),
    ),
    // ... and so on for every route
  ],
);
```

---

## How it works

```
User navigates to /dashboard
        │
        ▼
DeferredWidget._load()
        │
        ├─ already in cache? ──► setState(child = createWidget()) [synchronous, no flicker]
        │
        └─ not cached ──► show placeholder
                              │
                              ▼
                    dashboard.loadLibrary()  ← browser fetches dashboard.js
                              │
                    Future<void> stored in _pendingLoads[loader]
                    (subsequent calls return the same Future — no duplicate requests)
                              │
                    .then(_) ──► setState(child = DashboardScreen())
                    .catchError ──► setState(error = ...) ──► errorBuilder
```

**Key properties:**
- **Idempotent**: calling `preload` 10 times issues exactly 1 network request.
- **Transparent on native**: `loadLibrary()` completes synchronously on Android/iOS/desktop.
- **No flicker on revisit**: already-loaded libraries are served from memory instantly.
- **Zero deps**: only depends on `flutter/material.dart` (already in your project).

---

## Platform behaviour

| Platform | `deferred as` effect | `DeferredWidget` behaviour |
|---|---|---|
| Web (canvaskit / skwasm) | Splits bundle into chunks | Full lazy loading |
| Android / iOS / macOS | No-op, all code already bundled | Transparent wrapper, no delay |
| Windows / Linux | No-op | Transparent wrapper, no delay |

---

## Migrating from a manual implementation

If you copied the `DeferredWidget` pattern from a blog post or the old Flutter
Gallery, replace it with this package:

```dart
// Before (manual)
class DeferredWidget extends StatefulWidget { ... }  // 164 lines of your code

// After (package)
import 'package:flutter_lazy_load_web/flutter_lazy_load_web.dart';
// ✅  same API, plus preloadAll, isLoaded, reset, animationDuration
```

Your existing `DeferredWidget(loader, () => Screen())` call sites need **no
changes** — the API is identical.

---

## Contributing

Issues and PRs are welcome at
[github.com/Mathvdias/flutter_lazy_load_web](https://github.com/Mathvdias/flutter_lazy_load_web).

```
git clone https://github.com/Mathvdias/flutter_lazy_load_web.git
cd flutter_lazy_load_web
flutter pub get
flutter test
cd example && flutter pub get && flutter run -d chrome
```

---

## License

MIT — see [LICENSE](LICENSE).
