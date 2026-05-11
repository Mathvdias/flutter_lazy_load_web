/// A Flutter widget that wraps Dart deferred (lazy) library loading for web
/// apps, dramatically reducing initial JS bundle size.
///
/// ## Quick start
///
/// 1. Add the package to `pubspec.yaml`:
///    ```yaml
///    dependencies:
///      flutter_lazy_load_web: ^0.1.0
///    ```
///
/// 2. Change your screen imports to deferred imports:
///    ```dart
///    import 'screens/home_screen.dart' deferred as home;
///    ```
///
/// 3. Wrap your route builder with [DeferredWidget]:
///    ```dart
///    GoRoute(
///      path: '/home',
///      builder: (context, state) => DeferredWidget(
///        home.loadLibrary,
///        () => home.HomeScreen(),
///      ),
///    );
///    ```
library flutter_lazy_load_web;

export 'src/deferred_widget.dart'
    show DeferredWidget, LibraryLoader, DeferredWidgetBuilder;
export 'src/deferred_route.dart'
    show DeferredRoute, DeferredRouteListX;
