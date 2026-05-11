import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_lazy_load_web/flutter_lazy_load_web.dart';

import 'screens/home_shell.dart';

// ---------------------------------------------------------------------------
// Deferred imports — each becomes its own JS chunk.
// ---------------------------------------------------------------------------
import 'screens/dashboard_screen.dart' deferred as dashboard;
import 'screens/settings_screen.dart'  deferred as settings;
import 'screens/profile_screen.dart'   deferred as profile;

// ---------------------------------------------------------------------------
// Route declarations — one line per route, like DI bindings.
// Note the constructor tear-off (`Screen.new`) — no extra closure needed.
// ---------------------------------------------------------------------------
final _dashboardRoute = DeferredRoute(
  '/dashboard',
  dashboard.loadLibrary,
  dashboard.DashboardScreen.new,
);

final _settingsRoute = DeferredRoute(
  '/settings',
  settings.loadLibrary,
  settings.SettingsScreen.new,
);

final _profileRoute = DeferredRoute(
  '/profile',
  profile.loadLibrary,
  profile.ProfileScreen.new,
);

// All lazy routes as a list — enables .preloadAll() extension.
final _lazyRoutes = [_dashboardRoute, _settingsRoute, _profileRoute];

// ---------------------------------------------------------------------------
// Router — consume the declarations.
// ---------------------------------------------------------------------------
final router = GoRouter(
  initialLocation: '/home',
  routes: [
    ShellRoute(
      builder: (context, state, child) => HomeShell(child: child),
      routes: [
        GoRoute(
          path: '/home',
          builder: (context, state) => _WelcomePage(),
        ),
        GoRoute(
          path: _dashboardRoute.path,
          builder: (_, __) => _dashboardRoute.toWidget(),
        ),
        GoRoute(
          path: _settingsRoute.path,
          builder: (_, __) => _settingsRoute.toWidget(),
        ),
        GoRoute(
          path: _profileRoute.path,
          builder: (_, __) => _profileRoute.toWidget(),
        ),
      ],
    ),
  ],
);

// ---------------------------------------------------------------------------
// Home screen — preloads the two most-likely next destinations.
// ---------------------------------------------------------------------------
class _WelcomePage extends StatefulWidget {
  @override
  State<_WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<_WelcomePage> {
  @override
  void initState() {
    super.initState();
    // Warm up dashboard + profile chunks while the user reads this page.
    _lazyRoutes.preloadAll();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.rocket_launch, size: 64),
              const SizedBox(height: 24),
              Text(
                'flutter_lazy_load_web',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 12),
              Text(
                'Navigate to Dashboard, Settings or Profile.\n'
                'Open DevTools → Network to see each screen\n'
                'load as a separate JS chunk.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () => context.go('/dashboard'),
                icon: const Icon(Icons.bar_chart),
                label: const Text('Go to Dashboard'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
