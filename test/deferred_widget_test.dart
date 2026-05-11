import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_lazy_load_web/flutter_lazy_load_web.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Future<void> _successLoader() async {}
Future<void> _failingLoader() async => throw Exception('network error');

Widget _testApp(Widget child) => MaterialApp(home: child);

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  setUp(DeferredWidget.reset);
  tearDown(DeferredWidget.reset);

  group('DeferredWidget', () {
    testWidgets('shows loading indicator while future is pending',
        (tester) async {
      // Use a Completer so no pending timer is left after the test.
      final completer = Completer<void>();
      LibraryLoader slowLoader = () => completer.future;

      await tester.pumpWidget(_testApp(
        DeferredWidget(slowLoader, () => const Text('loaded')),
      ));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('loaded'), findsNothing);

      completer.complete(); // clean up so no pending future leaks
    });

    testWidgets('shows child widget after successful load', (tester) async {
      await tester.pumpWidget(_testApp(
        DeferredWidget(_successLoader, () => const Text('loaded')),
      ));

      await tester.pumpAndSettle();

      expect(find.text('loaded'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('shows default error widget on failure', (tester) async {
      await tester.pumpWidget(_testApp(
        DeferredWidget(_failingLoader, () => const Text('loaded')),
      ));

      await tester.pumpAndSettle();

      expect(find.text('Failed to load module'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('uses custom placeholder', (tester) async {
      final completer = Completer<void>();
      LibraryLoader slowLoader = () => completer.future;

      await tester.pumpWidget(_testApp(
        DeferredWidget(
          slowLoader,
          () => const Text('loaded'),
          placeholder: const Text('custom loading'),
        ),
      ));

      expect(find.text('custom loading'), findsOneWidget);

      completer.complete();
    });

    testWidgets('uses custom errorBuilder', (tester) async {
      await tester.pumpWidget(_testApp(
        DeferredWidget(
          _failingLoader,
          () => const Text('loaded'),
          errorBuilder: (context, error, retry) =>
              TextButton(onPressed: retry, child: const Text('custom retry')),
        ),
      ));

      await tester.pumpAndSettle();

      expect(find.text('custom retry'), findsOneWidget);
    });

    testWidgets('retry calls loader again after failure', (tester) async {
      var callCount = 0;
      LibraryLoader countingLoader = () async {
        callCount++;
        throw Exception('fail');
      };

      await tester.pumpWidget(_testApp(
        DeferredWidget(countingLoader, () => const Text('loaded')),
      ));

      await tester.pumpAndSettle();

      expect(callCount, 1);
      expect(find.text('Retry'), findsOneWidget);

      // After failure the cache entry is cleared, so Retry triggers a new load.
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(callCount, 2);
    });

    testWidgets('animationDuration zero skips animation', (tester) async {
      await tester.pumpWidget(_testApp(
        DeferredWidget(
          _successLoader,
          () => const Text('loaded'),
          animationDuration: Duration.zero,
        ),
      ));

      await tester.pump();
      expect(find.text('loaded'), findsOneWidget);
    });

    testWidgets('renders synchronously when library is already cached',
        (tester) async {
      // Pre-warm the cache before the widget is built.
      await DeferredWidget.preload(_successLoader);

      await tester.pumpWidget(_testApp(
        DeferredWidget(_successLoader, () => const Text('instant')),
      ));

      // No async work needed — the child should be present on first pump.
      await tester.pump();
      expect(find.text('instant'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('didUpdateWidget triggers reload when loader changes',
        (tester) async {
      Future<void> loaderA() async {}
      Future<void> loaderB() async {}

      await tester.pumpWidget(_testApp(
        DeferredWidget(loaderA, () => const Text('screen A')),
      ));
      await tester.pumpAndSettle();
      expect(find.text('screen A'), findsOneWidget);

      // Swap to a different loader — didUpdateWidget must be called.
      await tester.pumpWidget(_testApp(
        DeferredWidget(loaderB, () => const Text('screen B')),
      ));
      await tester.pumpAndSettle();
      expect(find.text('screen B'), findsOneWidget);
    });
  });

  group('DeferredWidget.preload', () {
    test('isLoaded returns false before preload', () {
      expect(DeferredWidget.isLoaded(_successLoader), isFalse);
    });

    test('isLoaded returns true after preload completes', () async {
      await DeferredWidget.preload(_successLoader);
      expect(DeferredWidget.isLoaded(_successLoader), isTrue);
    });

    test('calling preload twice returns the same future', () {
      final f1 = DeferredWidget.preload(_successLoader);
      final f2 = DeferredWidget.preload(_successLoader);
      expect(identical(f1, f2), isTrue);
    });

    test('preloadAll resolves all loaders', () async {
      Future<void> loaderA() async {}
      Future<void> loaderB() async {}

      await DeferredWidget.preloadAll([loaderA, loaderB]);

      expect(DeferredWidget.isLoaded(loaderA), isTrue);
      expect(DeferredWidget.isLoaded(loaderB), isTrue);
    });
  });

  group('DeferredWidget.reset', () {
    test('clears loaded set', () async {
      await DeferredWidget.preload(_successLoader);
      expect(DeferredWidget.isLoaded(_successLoader), isTrue);

      DeferredWidget.reset();

      expect(DeferredWidget.isLoaded(_successLoader), isFalse);
    });
  });
}
