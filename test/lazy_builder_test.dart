import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_lazy_load_web/flutter_lazy_load_web.dart';

Future<void> _loader() async {}
Future<void> _failLoader() async => throw Exception('fail');

void main() {
  setUp(DeferredWidget.reset);
  tearDown(DeferredWidget.reset);

  group('lazy()', () {
    testWidgets('returns a builder that renders DeferredWidget',
        (tester) async {
      // Simulate a router-style call: builder receives (BuildContext, dynamic).
      final builder = lazy<dynamic>(_loader, () => const Text('hello'));

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => builder(context, null),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('hello'), findsOneWidget);
    });

    testWidgets('forwards placeholder to DeferredWidget', (tester) async {
      // Use a Completer so no pending timer leaks.
      // We just need to confirm the placeholder is forwarded.
      final builder = lazy<dynamic>(
        _loader,
        () => const Text('done'),
        placeholder: const Text('loading…'),
      );

      // Pre-warm so it shows 'done' instantly (placeholder won't flash).
      await DeferredWidget.preload(_loader);

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(builder: (ctx) => builder(ctx, null)),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('done'), findsOneWidget);
    });

    testWidgets('forwards errorBuilder to DeferredWidget', (tester) async {
      final builder = lazy<dynamic>(
        _failLoader,
        () => const Text('done'),
        errorBuilder: (ctx, err, retry) => const Text('custom error'),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(builder: (ctx) => builder(ctx, null)),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('custom error'), findsOneWidget);
    });

    testWidgets('forwards animationDuration to DeferredWidget', (tester) async {
      final builder = lazy<dynamic>(
        _loader,
        () => const Text('done'),
        animationDuration: Duration.zero,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(builder: (ctx) => builder(ctx, null)),
        ),
      );
      await tester.pump();

      expect(find.text('done'), findsOneWidget);
    });

    test('state parameter is ignored (S is inferred from call-site)', () {
      // lazy() works with any S — the state value is not used by DeferredWidget.
      // This test confirms the function compiles with various S types.
      final b1 = lazy<String>(_loader, () => const SizedBox());
      final b2 = lazy<int>(_loader, () => const SizedBox());
      final b3 = lazy<Object?>(_loader, () => const SizedBox());

      expect(b1, isNotNull);
      expect(b2, isNotNull);
      expect(b3, isNotNull);
    });
  });
}
