import 'package:flutter/material.dart';
import 'deferred_widget.dart';

/// Returns a builder function that lazily loads [loader] and renders the widget
/// produced by [create].
///
/// The return type is `Widget Function(BuildContext, S)` where `S` is inferred
/// from the call-site. When assigned to go_router's `builder:` parameter, Dart
/// infers `S = GoRouterState` automatically — no go_router import needed here.
///
/// ## Usage
///
/// ```dart
/// import 'screens/dashboard_screen.dart' deferred as dashboard;
///
/// GoRoute(
///   path: '/dashboard',
///   builder: lazy(dashboard.loadLibrary, dashboard.DashboardScreen.new),
/// ),
/// ```
///
/// Compare with the equivalent verbose form:
///
/// ```dart
/// // Before
/// GoRoute(
///   path: '/dashboard',
///   builder: (context, state) => DeferredWidget(
///     dashboard.loadLibrary,
///     () => const dashboard.DashboardScreen(),
///   ),
/// ),
///
/// // After
/// GoRoute(
///   path: '/dashboard',
///   builder: lazy(dashboard.loadLibrary, dashboard.DashboardScreen.new),
/// ),
/// ```
///
/// ### With custom placeholder and error UI
///
/// ```dart
/// GoRoute(
///   path: '/dashboard',
///   builder: lazy(
///     dashboard.loadLibrary,
///     dashboard.DashboardScreen.new,
///     placeholder: const ShimmerCard(),
///     errorBuilder: (ctx, err, retry) => RetryBanner(onRetry: retry),
///   ),
/// ),
/// ```
Widget Function(BuildContext context, S state) lazy<S>(
  LibraryLoader loader,
  DeferredWidgetBuilder create, {
  Widget? placeholder,
  Widget Function(BuildContext context, Object error, VoidCallback retry)?
      errorBuilder,
  Duration animationDuration = const Duration(milliseconds: 300),
}) =>
    (context, _) => DeferredWidget(
          loader,
          create,
          placeholder: placeholder,
          errorBuilder: errorBuilder,
          animationDuration: animationDuration,
        );
