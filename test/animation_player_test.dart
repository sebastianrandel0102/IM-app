import 'package:bear_with_me/app/theme/app_theme.dart';
import 'package:bear_with_me/features/animation/presentation/bear_scene.dart';
import 'package:bear_with_me/features/animation/presentation/player_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  Future<void> open(WidgetTester tester, String type) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: buildTheme(),
          home: PlayerScreen(studio: true, typeName: type),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 50));
  }

  for (final type in ['warmHug', 'comfortHug', 'cuddleTime']) {
    testWidgets('$type supports physical hold, cancellation and replay', (
      tester,
    ) async {
      await open(tester, type);
      final scene = find.byType(BearScene);
      await tester.ensureVisible(scene);
      final gesture = await tester.startGesture(tester.getCenter(scene));
      await tester.pump(const Duration(milliseconds: 650));
      expect(tester.widget<BearScene>(scene).holding, isTrue);
      await tester.pump(const Duration(seconds: 18));
      expect(tester.widget<BearScene>(scene).holding, isTrue);
      await gesture.cancel();
      await tester.pump();
      expect(tester.widget<BearScene>(scene).holding, isFalse);
      final before = tester.widget<BearScene>(scene).key;
      final replay = find.widgetWithIcon(OutlinedButton, Icons.replay_rounded);
      await tester.ensureVisible(replay);
      await tester.tap(replay);
      await tester.pump();
      expect(tester.widget<BearScene>(scene).key, isNot(before));
      expect(tester.widget<BearScene>(scene).taps, 0);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      expect(tester.binding.transientCallbackCount, 0);
    });
  }

  testWidgets('return kiss waits for the first reaction and is debounced', (
    tester,
  ) async {
    await open(tester, 'cheekKiss');
    final control = find.text('Kiss back');
    await tester.ensureVisible(control);
    await tester.tap(control);
    await tester.pump();
    expect(tester.widget<BearScene>(find.byType(BearScene)).taps, 0);
    await tester.pump(const Duration(seconds: 6));
    await tester.tap(control);
    await tester.pump();
    await tester.tap(control);
    await tester.pump();
    expect(tester.widget<BearScene>(find.byType(BearScene)).taps, 1);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('tickle Stop cancels action and playback settles', (
    tester,
  ) async {
    await open(tester, 'playfulTickle');
    final stop = find.text('Stop');
    await tester.ensureVisible(stop);
    await tester.tap(stop);
    await tester.pump();
    expect(tester.widget<BearScene>(find.byType(BearScene)).stopped, isTrue);
    await tester.pump(const Duration(seconds: 4));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    expect(tester.binding.transientCallbackCount, 0);
  });

  testWidgets(
    'cuddle blanket and lamp controls wait for contact and replay resets them',
    (tester) async {
      await open(tester, 'cuddleTime');
      final blanket = find.widgetWithText(FilterChip, 'Cover with blanket');
      final lamp = find.widgetWithText(FilterChip, 'Turn off lamp');
      expect(tester.widget<FilterChip>(blanket).onSelected, isNull);
      await tester.pump(const Duration(seconds: 5));
      await tester.ensureVisible(blanket);
      await tester.tap(blanket);
      await tester.pump();
      expect(tester.widget<FilterChip>(blanket).selected, isTrue);
      expect(tester.widget<FilterChip>(lamp).selected, isFalse);
      await tester.tap(lamp);
      await tester.pump();
      expect(tester.widget<FilterChip>(lamp).selected, isTrue);
      final replay = find.widgetWithIcon(OutlinedButton, Icons.replay_rounded);
      await tester.ensureVisible(replay);
      await tester.tap(replay);
      await tester.pump();
      expect(tester.widget<FilterChip>(blanket).selected, isFalse);
      expect(tester.widget<FilterChip>(lamp).selected, isFalse);
      expect(tester.widget<FilterChip>(blanket).onSelected, isNull);
      await tester.pumpWidget(const SizedBox());
      expect(tester.binding.transientCallbackCount, 0);
    },
  );

  testWidgets('backgrounding releases a held hug before resume', (
    tester,
  ) async {
    await open(tester, 'warmHug');
    final scene = find.byType(BearScene);
    await tester.ensureVisible(scene);
    final pointer = await tester.startGesture(tester.getCenter(scene));
    await tester.pump(const Duration(milliseconds: 650));
    expect(tester.widget<BearScene>(scene).holding, isTrue);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    expect(tester.widget<BearScene>(scene).holding, isFalse);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await pointer.cancel();
    await tester.pumpWidget(const SizedBox());
    expect(tester.binding.transientCallbackCount, 0);
  });

  testWidgets('sleep swipe wakes the bears and walk buttons stay bounded', (
    tester,
  ) async {
    await open(tester, 'sleepTogether');
    await tester.drag(find.byType(BearScene), const Offset(100, 0));
    await tester.pump();
    expect(tester.widget<BearScene>(find.byType(BearScene)).stopped, isTrue);
    await tester.pumpWidget(const SizedBox());
    await open(tester, 'holdingHands');
    await tester.pump(const Duration(seconds: 5));
    final right = find.byTooltip('Walk right');
    await tester.ensureVisible(right);
    for (var i = 0; i < 8; i++) {
      await tester.tap(right);
      await tester.pump();
    }
    expect(tester.widget<BearScene>(find.byType(BearScene)).walk, 25);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
