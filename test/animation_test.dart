import 'package:bear_with_me/features/affection/domain/affection_type.dart';
import 'package:bear_with_me/features/animation/presentation/bear_choreography.dart';
import 'package:bear_with_me/features/animation/presentation/bear_scene.dart';
import 'package:bear_with_me/features/animation/presentation/bear_vector_rig.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void configure(
  BearPlayback p, {
  bool hold = false,
  bool stop = false,
  bool reduced = false,
  int taps = 0,
  double walk = 0,
}) => p.configure(
  nextAction: p.action,
  nextVariant: p.variant,
  nextReduced: reduced,
  nextHolding: hold,
  nextStopped: stop,
  nextTaps: taps,
  nextWalk: walk,
);

void main() {
  for (final action in AffectionType.values) {
    test(
      '${action.name}: full timeline has finite, continuous bounded poses',
      () {
        for (final reduced in [false, true]) {
          BearFrame? previous;
          final duration =
              BearChoreography.duration(action, 'gentle').inMilliseconds / 1000;
          final samples = (duration * 120).ceil();
          for (var i = 0; i <= samples; i++) {
            final frame = BearChoreography.sample(
              action: action,
              t: i / samples,
              seconds: i / 120,
              reduced: reduced,
            );
            for (var actor = 0; actor < 2; actor++) {
              final p = actor == 0 ? frame.left : frame.right;
              final before = actor == 0 ? previous?.left : previous?.right;
              expect(
                p.squash,
                inInclusiveRange(.94, 1.06),
                reason: action.name,
              );
              for (final anchor in BearAnchor.values) {
                final at = p.anchor(anchor);
                expect(at.dx.isFinite && at.dy.isFinite, isTrue);
                expect(
                  at.dx,
                  inInclusiveRange(0, 400),
                  reason: '${action.name} $i $anchor',
                );
                expect(
                  at.dy,
                  inInclusiveRange(0, 340),
                  reason: '${action.name} $i $anchor',
                );
                if (before != null) {
                  expect(
                    (at - before.anchor(anchor)).distance,
                    lessThan(7),
                    reason: '${action.name} frame $i $anchor jumps',
                  );
                }
              }
              for (final near in [true, false]) {
                final shoulder = p.bodyPoint(Offset(near ? 23 : -23, -80));
                expect(
                  (BearVectorRig.paw(p, near: near) - shoulder).distance,
                  lessThanOrEqualTo(64.001),
                );
              }
            }
            previous = frame;
          }
        }
      },
    );
  }

  for (final action in [
    AffectionType.warmHug,
    AffectionType.comfortHug,
    AffectionType.cuddleTime,
  ]) {
    test('${action.name}: hold breathes, release completes once', () {
      var completed = 0, contacts = 0;
      final p = BearPlayback(
        action: action,
        onComplete: () => completed++,
        onContact: () => contacts++,
      );
      addTearDown(p.dispose);
      configure(p, hold: true);
      for (var i = 0; i < 1500; i++) {
        p.advance(1 / 60);
      }
      expect(p.stage, BearStage.hold);
      expect(completed, 0);
      expect(contacts, 1);
      final breath = p.frame.left.breath;
      p.advance(.5);
      expect(p.frame.left.breath, isNot(closeTo(breath, .001)));
      configure(p);
      p.advance(20);
      p.advance(20);
      expect(completed, 1);
      expect(p.stage, BearStage.complete);
      configure(p, hold: true);
      expect(p.completed, isFalse);
      p.advance(10);
      expect(completed, 1);
    });
  }

  test(
    'shared paw contact is accurate and remains joined throughout walking',
    () {
      for (final type in [AffectionType.holdingHands, AffectionType.highFive]) {
        final f = BearChoreography.sample(action: type, t: .50, walk: 22);
        expect(
          (BearVectorRig.paw(f.left) - BearVectorRig.paw(f.right)).distance,
          lessThan(.01),
        );
      }
      final p = BearPlayback(action: AffectionType.holdingHands);
      addTearDown(p.dispose);
      p.advance(8);
      configure(p, walk: 25);
      expect(p.walk, 0);
      for (var i = 0; i < 180; i++) {
        p.advance(1 / 60);
        expect(
          (BearVectorRig.paw(p.frame.left) - BearVectorRig.paw(p.frame.right))
              .distance,
          lessThan(.1),
        );
      }
      expect(p.walk, closeTo(25, .01));
      expect(p.locomotion, lessThan(.01));
    },
  );

  test('kiss and face touch target the actual rendered anchors', () {
    for (final type in [
      AffectionType.cheekKiss,
      AffectionType.foreheadKiss,
      AffectionType.goodnightKiss,
    ]) {
      final f = BearChoreography.sample(action: type, t: .50);
      final anchor = type == AffectionType.cheekKiss
          ? BearAnchor.cheek
          : BearAnchor.forehead;
      expect(
        (f.left.anchor(BearAnchor.nose) - f.right.anchor(anchor)).distance,
        lessThan(1),
        reason: type.name,
      );
    }
    for (final (type, anchor) in [
      (AffectionType.headPat, BearAnchor.forehead),
      (AffectionType.noseBoop, BearAnchor.nose),
    ]) {
      final f = BearChoreography.sample(action: type, t: .50, reduced: true);
      expect(
        (BearVectorRig.paw(f.left) - f.right.anchor(anchor)).distance,
        lessThan(1),
        reason: type.name,
      );
    }
  });

  test('reverse affection swaps acting roles without reversing time', () {
    for (final (type, taps) in [
      (AffectionType.cheekKiss, 1),
      (AffectionType.noseBoop, 3),
    ]) {
      final forward = BearChoreography.sample(action: type, t: .5);
      final back = BearChoreography.sample(action: type, t: .5, taps: taps);
      expect(back.right.turn, forward.left.turn);
      expect(back.right.root.dx, closeTo(400 - forward.left.root.dx, .01));
      expect(back.left.root.dx, lessThan(back.right.root.dx));
    }
  });

  test('reduced motion removes loops, spins and impact effects, preserving contact', () {
    for (final action in AffectionType.values) {
      final a = BearChoreography.sample(
        action: action,
        t: .55,
        seconds: 2,
        reduced: true,
      );
      final b = BearChoreography.sample(
        action: action,
        t: .55,
        seconds: 9,
        reduced: true,
      );
      expect(a.left.root, b.left.root);
      expect(a.right.root, b.right.root);
      expect(a.left.breath, 0);
      expect(a.right.breath, 0);
      expect(a.spin, 0);
    }
  });

  test(
    'all actions accept reactions and complete in every existing variant',
    () {
      for (final action in AffectionType.values) {
        for (final variant in ['gentle', 'shy', 'playful']) {
          var completions = 0;
          final p = BearPlayback(
            action: action,
            variant: variant,
            onComplete: () => completions++,
          );
          p.advance(
            p.duration.inMicroseconds / 1e6 * (p.definition!.inputAt + .02),
          );
          if (p.definition!.supportsHold) {
            configure(p, hold: true);
            p.advance(p.duration.inMicroseconds / 1e6);
            expect(p.stage, BearStage.hold);
            expect(completions, 0);
            configure(p);
          } else {
            expect(p.canReact, isTrue, reason: '${action.name} $variant');
            configure(p, taps: 1);
            expect(p.taps, 1, reason: '${action.name} $variant');
          }
          for (var i = 0; i < 180; i++) {
            p.advance(.1);
          }
          expect(completions, 1, reason: '${action.name} $variant');
          expect(p.frame.left.eyes.isFinite, isTrue);
          p.dispose();
        }
      }
    },
  );

  test(
    'head silhouettes remain inside the stage, including turn and ride bounds',
    () {
      for (final action in AffectionType.values) {
        for (final walk in [-25.0, 25.0]) {
          for (var i = 0; i <= 120; i++) {
            final f = BearChoreography.sample(
              action: action,
              t: i / 120,
              seconds: i / 15,
              walk: walk,
            );
            for (final p in [f.left, f.right]) {
              for (final local in [
                const Offset(-58, -62),
                const Offset(64, -62),
                const Offset(73, 0),
                const Offset(39, 66),
                const Offset(-65, 40),
              ]) {
                var point = p.headPoint(local);
                expect(
                  point.dx,
                  inInclusiveRange(0, 400),
                  reason: '${action.name} $i $walk',
                );
                expect(
                  point.dy,
                  inInclusiveRange(0, 340),
                  reason: '${action.name} $i $walk',
                );
              }
            }
          }
        }
      }
    },
  );

  test('touch responses bloom, catch, move closer and keep a gift open', () {
    final tear = BearChoreography.sample(
      action: AffectionType.wipeAwayTears,
      t: .1,
      taps: 1,
      input: 1,
    );
    expect(tear.tear, 0);
    expect(tear.right.smile, greaterThan(.9));
    final flower = BearChoreography.sample(
      action: AffectionType.flowerSurprise,
      t: 1,
      taps: 1,
      input: 1,
    );
    expect(flower.bloom, 1);
    final kiss = BearChoreography.sample(
      action: AffectionType.blowingKisses,
      t: 1,
      taps: 1,
      input: .4,
    );
    expect(kiss.reveal, greaterThan(.8));
    final box = BearChoreography.sample(
      action: AffectionType.surpriseBox,
      t: 1,
      taps: 1,
      input: 0,
    );
    expect(box.reveal, 1);
    for (final action in [
      AffectionType.sleepTogether,
      AffectionType.underOneUmbrella,
    ]) {
      final before = BearChoreography.sample(action: action, t: 1);
      final after = BearChoreography.sample(
        action: action,
        t: 1,
        taps: 1,
        input: 1,
      );
      expect(after.left.root.dx, greaterThan(before.left.root.dx));
      expect(after.right.root.dx, lessThan(before.right.root.dx));
    }
  });

  test('wake after completed sleep still blends and finishes recovery', () {
    final p = BearPlayback(action: AffectionType.sleepTogether);
    addTearDown(p.dispose);
    p.advance(12);
    expect(p.completed, isTrue);
    final resting = p.frame.left.lie;
    configure(p, stop: true);
    expect(p.completed, isFalse);
    expect(p.frame.left.lie, resting);
    p.advance(.3);
    expect(p.frame.left.lie, 0);
    p.advance(6);
    expect(p.settled, isTrue);
  });

  testWidgets('reduced motion player completes then stops requesting frames', (
    tester,
  ) async {
    var completions = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 300,
          height: 250,
          child: BearScene(
            action: AffectionType.noseBoop,
            reducedMotion: true,
            onComplete: () => completions++,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 6));
    expect(completions, 1);
    expect(tester.binding.transientCallbackCount, 0);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'reused static thumbnails show the new gesture without a running ticker',
    (tester) async {
      Widget scene(AffectionType type) => MaterialApp(
        home: SizedBox(
          width: 300,
          height: 250,
          child: BearScene(
            key: const ValueKey('thumbnail'),
            action: type,
            reducedMotion: true,
          ),
        ),
      );
      await tester.pumpWidget(scene(AffectionType.warmHug));
      await tester.pumpWidget(scene(AffectionType.foreheadKiss));
      final paint = tester.widget<CustomPaint>(
        find.descendant(
          of: find.byType(BearScene),
          matching: find.byType(CustomPaint),
        ),
      );
      final painter = paint.painter! as BearScenePainter;
      expect(painter.playback!.frame.left.turn, greaterThan(.9));
      expect(tester.binding.transientCallbackCount, 0);
      await tester.pumpWidget(const SizedBox());
    },
  );

  test('tap retarget and stop blend continuously from the current pose', () {
    final p = BearPlayback(action: AffectionType.cheekKiss);
    addTearDown(p.dispose);
    p.advance(4);
    final before = p.frame.left.anchor(BearAnchor.nose);
    configure(p, taps: 1);
    expect(
      (p.frame.left.anchor(BearAnchor.nose) - before).distance,
      lessThan(.01),
    );
    p.advance(.3);
    final prior = p.frame.right.root;
    configure(p, taps: 1, stop: true);
    expect((p.frame.right.root - prior).distance, lessThan(.01));
    p.advance(.3);
    expect(p.frame.right.root, const Offset(268, 278));
  });

  testWidgets(
    'scene pauses in background and under TickerMode, completes after resume',
    (tester) async {
      var completions = 0;
      final key = GlobalKey();
      Widget scene(bool enabled) => MaterialApp(
        home: TickerMode(
          enabled: enabled,
          child: SizedBox(
            width: 400,
            height: 340,
            child: BearScene(
              key: key,
              action: AffectionType.noseBoop,
              onComplete: () => completions++,
            ),
          ),
        ),
      );
      await tester.pumpWidget(scene(true));
      await tester.pump(const Duration(seconds: 1));
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump(const Duration(seconds: 20));
      expect(completions, 0);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      await tester.pumpWidget(scene(false));
      await tester.pump(const Duration(seconds: 20));
      expect(completions, 0);
      await tester.pumpWidget(scene(true));
      await tester.pump();
      await tester.pump(const Duration(seconds: 5));
      expect(completions, 1);
      await tester.pump(const Duration(seconds: 20));
      expect(completions, 1);
      await tester.pumpWidget(const SizedBox());
      expect(tester.binding.transientCallbackCount, 0);
    },
  );

  testWidgets(
    'all 24 gestures render at small phone size in both color roles',
    (tester) async {
      for (final type in AffectionType.values) {
        for (final role in BearCharacter.values) {
          await tester.pumpWidget(
            MaterialApp(
              home: Center(
                child: SizedBox(
                  width: 240,
                  height: 220,
                  child: BearScene(
                    key: ValueKey('${type.name}-${role.name}'),
                    action: type,
                    sender: role,
                    reducedMotion: true,
                  ),
                ),
              ),
            ),
          );
          expect(
            tester.takeException(),
            isNull,
            reason: '${type.name} ${role.name}',
          );
        }
      }
      await tester.pumpWidget(const SizedBox());
      expect(tester.binding.transientCallbackCount, 0);
    },
  );
}
