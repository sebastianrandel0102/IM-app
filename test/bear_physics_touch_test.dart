import 'package:bear_with_me/features/affection/domain/affection_type.dart';
import 'package:bear_with_me/features/animation/presentation/bear_choreography.dart';
import 'package:bear_with_me/features/animation/presentation/bear_physics.dart';
import 'package:bear_with_me/features/animation/presentation/bear_scene.dart';
import 'package:bear_with_me/features/animation/presentation/bear_touch.dart';
import 'package:bear_with_me/features/animation/presentation/bear_vector_rig.dart';
import 'package:bear_with_me/features/settings/data/settings_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('every authored paw stays reachable throughout all 24 gestures', () {
    for (final action in AffectionType.values) {
      for (final variant in ['gentle', 'shy', 'playful']) {
        for (final reduced in [false, true]) {
          for (var i = 0; i <= 120; i++) {
            final f = BearChoreography.sample(
              action: action,
              t: i / 120,
              seconds: i / 15,
              variant: variant,
              reduced: reduced,
            );
            for (final actor in [f.left, f.right]) {
              for (final near in [true, false]) {
                final requested = actor.anchor(
                  near ? BearAnchor.leftPaw : BearAnchor.rightPaw,
                );
                expect(
                  (requested - BearVectorRig.paw(actor, near: near)).distance,
                  lessThan(.01),
                  reason: '${action.name} $variant $reduced at ${i / 120}',
                );
              }
            }
          }
        }
      }
    }
  });
  test('fixed-step touch response agrees at 30, 60, 120 and 144 Hz', () {
    final results = <BearSecondaryMotion>[];
    for (final hz in [30, 60, 120, 144]) {
      final p = BearSecondaryMotion()..left.react(BearReaction.jump);
      for (var i = 0; i < hz * 2; i++) {
        p.advance(1 / hz);
      }
      results.add(p);
    }
    for (final p in results.skip(1)) {
      expect(
        p.left.lift.position,
        closeTo(results.first.left.lift.position, 1e-10),
      );
      expect(
        p.left.ear.position,
        closeTo(results.first.left.ear.position, 1e-10),
      );
      expect(
        p.left.compression.velocity,
        closeTo(results.first.left.compression.velocity, 1e-10),
      );
    }
  });

  test(
    'every reaction settles; catch-up is bounded and pause releases held paws',
    () {
      for (final reaction in BearReaction.values) {
        final p = BearSecondaryMotion()..left.react(reaction);
        p.advance(500);
        expect(p.lastStepCount, BearSecondaryMotion.maxSteps);
        p.suspend();
        expect(p.left.holdingPaw, isFalse);
        for (var i = 0; i < 360; i++) {
          p.advance(1 / 60);
          expect(p.left.head.position.isFinite, isTrue);
          expect(p.left.compression.position.abs(), lessThanOrEqualTo(.04));
        }
        expect(p.settled, isTrue, reason: reaction.name);
        p.advance(double.nan);
        expect(p.lastStepCount, 0);
      }
    },
  );

  test('touch feedback respects zero intensity and reduced motion', () {
    for (final reduced in [false, true]) {
      final p = BearPlayback(reduced: reduced)..intensity = 0;
      addTearDown(p.dispose);
      final root = p.frame.left.root;
      p.react(true, BearReaction.jump);
      p.advance(.1);
      expect(p.frame.left.root, root);
      expect(p.frame.left.squash, 1);
      expect(p.frame.left.head, 0);
      expect(p.frame.left.blush, greaterThan(.15));
    }
  });

  test('moving nose, cheeks, paws, head and back hit the posed actor', () {
    for (final left in [true, false]) {
      final f = BearChoreography.sample(action: null, t: 0);
      final p = left ? f.left : f.right;
      p.head = .11;
      p.body = -.02;
      p.squash = .98;
      for (final (point, zone) in [
        (p.anchor(BearAnchor.nose), BearTouchZone.nose),
        (p.anchor(BearAnchor.leftCheek), BearTouchZone.cheek),
        (BearVectorRig.paw(p), BearTouchZone.paw),
        (p.headPoint(const Offset(-20, -15)), BearTouchZone.head),
        (p.bodyPoint(const Offset(-39, -40)), BearTouchZone.back),
      ]) {
        final target = BearTouchGeometry.hit(f, point);
        expect(target?.left, left, reason: '$zone actor');
        expect(target?.zone, zone);
      }
    }
    final p = BearTouchGeometry.scenePoint(
      const Offset(100, 30),
      const Size(600, 340),
    );
    expect(p, const Offset(0, 30));
    expect(
      BearTouchGeometry.scenePoint(const Offset(10, 30), const Size(600, 340)),
      isNull,
    );
    expect(
      BearTouchGeometry.hit(
        BearChoreography.sample(t: 0),
        const Offset(30, 20),
      ),
      isNull,
    );
  });

  test('short or cross-actor strokes cannot trigger a reaction twice', () {
    const hit = BearTouchHit(true, BearTouchZone.head);
    final stroke = BearStroke(hit, const Offset(10, 10));
    expect(stroke.move(hit, const Offset(13, 10)), isNull);
    expect(
      stroke.move(
        const BearTouchHit(false, BearTouchZone.head),
        const Offset(50, 10),
      ),
      isNull,
    );
    expect(stroke.move(hit, const Offset(30, 10)), isNull);
    final valid = BearStroke(hit, const Offset(10, 10));
    expect(valid.move(hit, const Offset(30, 10)), BearReaction.pet);
    expect(valid.move(hit, const Offset(60, 10)), isNull);
  });

  test('holding either paw preserves its contact point and releases without snapping', () {
    for (final left in [true, false]) {
      for (final near in [true, false]) {
        final p = BearPlayback();
        addTearDown(p.dispose);
        final actor = left ? p.frame.left : p.frame.right;
        final contact = BearVectorRig.paw(actor, near: near);
        p.holdPaw(left, near: near);
        for (var i = 0; i < 180; i++) {
          p.advance(1 / 60);
          final current = left ? p.frame.left : p.frame.right;
          expect(
            (BearVectorRig.paw(current, near: near) - contact).distance,
            lessThan(.01),
          );
        }
        p.releaseTouch();
        final released = left ? p.frame.left : p.frame.right;
        expect(
          (BearVectorRig.paw(released, near: near) - contact).distance,
          lessThan(.01),
        );
        for (var i = 0; i < 240; i++) {
          p.advance(1 / 60);
        }
        expect(p.secondary.settled, isTrue);
      }
    }
  });

  test('live spring contact remains reachable in all six priority scenes', () {
    for (final action in [
      AffectionType.warmHug,
      AffectionType.comfortHug,
      AffectionType.spinningHug,
      AffectionType.cuddleTime,
      AffectionType.sleepTogether,
      AffectionType.goodnightKiss,
    ]) {
      final p = BearPlayback(action: action);
      addTearDown(p.dispose);
      for (var i = 0; i < 650; i++) {
        p.advance(1 / 60);
        if (p.progress < .46 || p.progress > .78) {
          continue;
        }
        if (action == AffectionType.goodnightKiss && p.progress <= .56) {
          expect(
            (p.frame.left.anchor(BearAnchor.nose) -
                    p.frame.right.anchor(BearAnchor.forehead))
                .distance,
            lessThan(.01),
          );
        }
        for (final actor in [p.frame.left, p.frame.right]) {
          for (final near in [true, false]) {
            final requested = actor.anchor(
              near ? BearAnchor.leftPaw : BearAnchor.rightPaw,
            );
            expect(
              (requested - BearVectorRig.paw(actor, near: near)).distance,
              lessThan(.01),
              reason: '${action.name} ${p.progress}',
            );
          }
        }
      }
    }
  });

  test(
    'old settings retain defaults; intensity is validated and persisted',
    () {
      expect(AppSettings.fromJson({}).animationIntensity, 1);
      expect(
        AppSettings.fromJson({'animationIntensity': 'bad'}).animationIntensity,
        1,
      );
      expect(
        AppSettings.fromJson({'animationIntensity': -5}).animationIntensity,
        0,
      );
      expect(
        AppSettings.fromJson({'animationIntensity': double.nan})
            .animationIntensity,
        1,
      );
      final settings = AppSettings.fromJson(
        const AppSettings().copyWith(animationIntensity: .25).toJson(),
      );
      expect(settings.animationIntensity, .25);
      expect(settings.sound, isFalse);
    },
  );

  testWidgets('sleep touch keeps the existing tap and wake swipe available', (
    tester,
  ) async {
    var taps = 0, swipes = 0;
    final reactions = <BearReaction>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: SizedBox(
            width: 400,
            height: 340,
            child: GestureDetector(
              onHorizontalDragEnd: (_) => swipes++,
              child: BearScene(
                action: AffectionType.sleepTogether,
                interactive: true,
                onLocalTap: () => taps++,
                onLocalReaction: reactions.add,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 6));
    final origin = tester.getTopLeft(find.byType(BearScene));
    final pose = BearChoreography.sample(
      action: AffectionType.sleepTogether,
      t: .6,
    ).right;
    await tester.tapAt(origin + pose.anchor(BearAnchor.headCenter));
    await tester.pump(const Duration(milliseconds: 350));
    expect(taps, 1);
    expect(reactions, [BearReaction.sleepy]);
    await tester.drag(find.byType(BearScene), const Offset(100, 0));
    await tester.pump(const Duration(milliseconds: 350));
    expect(swipes, 1);
    final p = BearPlayback(action: AffectionType.sleepTogether)..advance(6);
    addTearDown(p.dispose);
    expect(p.frame.right.eyes, 0);
    p.react(false, BearReaction.sleepy);
    p.advance(.1);
    expect(p.frame.right.eyes, greaterThan(0));
    await tester.pumpWidget(const SizedBox.shrink());
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'single tap, double tap, background tap and paw hold remain separate',
    (tester) async {
      final reactions = <BearReaction>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: SizedBox(
              width: 400,
              height: 340,
              child: BearScene(
                interactive: true,
                onLocalReaction: reactions.add,
              ),
            ),
          ),
        ),
      );
      final origin = tester.getTopLeft(find.byType(BearScene));
      final pose = BearChoreography.sample(t: 0).left;
      final head = origin + pose.headPoint(const Offset(-20, -15));
      await tester.tapAt(head);
      await tester.pump(const Duration(milliseconds: 350));
      expect(reactions, [BearReaction.curious]);
      reactions.clear();
      await tester.tapAt(head);
      await tester.pump(const Duration(milliseconds: 70));
      await tester.tapAt(head);
      await tester.pump(const Duration(milliseconds: 350));
      expect(reactions, [BearReaction.jump]);
      reactions.clear();
      await tester.tapAt(origin + const Offset(30, 30));
      await tester.pump(const Duration(milliseconds: 350));
      expect(reactions, isEmpty);
      final gesture = await tester.startGesture(
        origin + pose.anchor(BearAnchor.leftPaw),
      );
      await tester.pump(const Duration(milliseconds: 650));
      expect(reactions, [BearReaction.pawHold]);
      await gesture.up();
      await tester.pumpWidget(const SizedBox.shrink());
      expect(tester.takeException(), isNull);
    },
  );
}
