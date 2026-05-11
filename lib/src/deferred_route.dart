import 'package:flutter/material.dart';
import 'deferred_widget.dart';

/// A declarative configuration for a single lazily-loaded route.
///
/// Define all your deferred routes in one place (like DI bindings), then
/// convert each to your router's widget via [toWidget].
///
/// ## Usage with go_router
///
/// ```dart
/// // routes.dart — declare once, like DI bindings
/// import 'screens/dashboard.dart' deferred as dashboard;
/// import 'screens/settings.dart'  deferred as settings;
/// import 'screens/profile.dart'   deferred as profile;
///
/// final appRoutes = [
///   DeferredRoute('/dashboard', dashboard.loadLibrary, dashboard.DashboardScreen.new),
///   DeferredRoute('/settings',  settings.loadLibrary,  settings.SettingsScreen.new),
///   DeferredRoute('/profile',   profile.loadLibrary,   profile.ProfileScreen.new),
/// ];
///
/// // router.dart — consume
/// GoRouter(
///   routes: appRoutes.map((r) => GoRoute(
///     path: r.path,
///     builder: (_, __) => r.toWidget(),
///   )).toList(),
/// );
/// ```
///
/// ## Constructor tear-off shorthand
///
/// ```dart
/// DeferredRoute('/profile', profile.loadLibrary, profile.ProfileScreen.new)
/// //                                                               ^^^
/// //                        Dart's constructor tear-off — identical to:
/// //                        () => profile.ProfileScreen()
/// ```
class DeferredRoute {
  const DeferredRoute(
    this.path,
    this.loader,
    this.create, {
    this.placeholder,
    this.errorBuilder,
    this.animationDuration = const Duration(milliseconds: 300),
  });

  /// The URL path for this route (e.g. `'/dashboard'`).
  final String path;

  /// The `loadLibrary` tear-off from the deferred import.
  final LibraryLoader loader;

  /// Widget factory called once the library chunk is loaded.
  ///
  /// Tip: use Dart's constructor tear-off (`MyScreen.new`) instead of a
  /// closure (`() => const MyScreen()`) for a more concise declaration.
  final DeferredWidgetBuilder create;

  /// Optional placeholder shown while the chunk is downloading.
  final Widget? placeholder;

  /// Optional error builder shown if the chunk fails to download.
  final Widget Function(BuildContext context, Object error, VoidCallback retry)?
      errorBuilder;

  /// Cross-fade duration between loading/loaded states. Defaults to 300 ms.
  final Duration animationDuration;

  /// Creates the [DeferredWidget] for this route.
  ///
  /// Call this inside your router's `builder` callback:
  /// ```dart
  /// GoRoute(
  ///   path: myRoute.path,
  ///   builder: (_, __) => myRoute.toWidget(),
  /// )
  /// ```
  DeferredWidget toWidget() => DeferredWidget(
        loader,
        create,
        placeholder: placeholder,
        errorBuilder: errorBuilder,
        animationDuration: animationDuration,
      );

  /// Preloads this route's JS chunk without waiting for the user to navigate.
  ///
  /// ```dart
  /// @override
  /// void initState() {
  ///   super.initState();
  ///   dashboardRoute.preload(); // warm up in background
  /// }
  /// ```
  Future<void> preload() => DeferredWidget.preload(loader);

  /// Returns `true` if this route's chunk is already cached.
  bool get isLoaded => DeferredWidget.isLoaded(loader);
}

/// Convenience extension so you can preload a list of [DeferredRoute]s at once.
///
/// ```dart
/// await appRoutes.preloadAll();
/// ```
extension DeferredRouteListX on List<DeferredRoute> {
  /// Preloads all routes in this list concurrently.
  Future<void> preloadAll() =>
      DeferredWidget.preloadAll(map((r) => r.loader).toList());
}
