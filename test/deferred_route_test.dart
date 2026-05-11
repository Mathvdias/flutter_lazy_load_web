import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_lazy_load_web/flutter_lazy_load_web.dart';

Future<void> _loader() async {}

void main() {
  setUp(DeferredWidget.reset);
  tearDown(DeferredWidget.reset);

  group('DeferredRoute', () {
    test('exposes path', () {
      final r = DeferredRoute('/foo', _loader, () => const SizedBox());
      expect(r.path, '/foo');
    });

    test('isLoaded returns false before preload', () {
      final r = DeferredRoute('/foo', _loader, () => const SizedBox());
      expect(r.isLoaded, isFalse);
    });

    test('isLoaded returns true after preload', () async {
      final r = DeferredRoute('/foo', _loader, () => const SizedBox());
      await r.preload();
      expect(r.isLoaded, isTrue);
    });

    testWidgets('toWidget returns DeferredWidget', (tester) async {
      final r = DeferredRoute('/foo', _loader, () => const Text('hi'));

      await tester.pumpWidget(
        MaterialApp(home: r.toWidget()),
      );
      await tester.pumpAndSettle();

      expect(find.text('hi'), findsOneWidget);
    });
  });

  group('DeferredRouteListX.preloadAll', () {
    test('preloads all routes concurrently', () async {
      Future<void> loaderA() async {}
      Future<void> loaderB() async {}

      final routes = [
        DeferredRoute('/a', loaderA, () => const SizedBox()),
        DeferredRoute('/b', loaderB, () => const SizedBox()),
      ];

      await routes.preloadAll();

      expect(routes[0].isLoaded, isTrue);
      expect(routes[1].isLoaded, isTrue);
    });
  });
}
