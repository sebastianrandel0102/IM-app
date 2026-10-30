import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bear_with_me/app/app.dart';
import 'package:bear_with_me/app/configuration/bootstrap.dart';
import 'package:bear_with_me/app/theme/app_theme.dart';
import 'package:bear_with_me/features/home/presentation/home_screen.dart';
import 'package:bear_with_me/features/animation/presentation/player_screen.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  for (final width in [360.0, 430.0, 1200.0]) {
    testWidgets('local world lays out without overflow at $width', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: buildTheme(),
            home: const Scaffold(body: HomeScreen(studio: true)),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Home is a little closer.'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }
  testWidgets(
    'unconfigured app guards private routes and opens labeled local preview',
    (tester) async {
      final container = ProviderContainer(
        overrides: [
          bootstrapProvider.overrideWithValue(const Bootstrap(ready: false)),
        ],
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const BearWithMeApp(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));
      container.read(routerProvider).go('/inbox');
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Start our story'), findsOneWidget);
      container.read(routerProvider).go('/studio');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.textContaining('LOCAL PREVIEW'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets('hug has accessible hold and release controls', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: buildTheme(),
          home: const PlayerScreen(studio: true, typeName: 'warmHug'),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
    final button = find.text('Stay in this hug');
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pump();
    expect(find.text('Let go gently'), findsOneWidget);
    await tester.tap(find.text('Let go gently'));
    await tester.pump();
    expect(find.text('Stay in this hug'), findsOneWidget);
    expect(find.text('Keep this little memory'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
