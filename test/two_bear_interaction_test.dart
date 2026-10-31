import 'dart:math' as math;

import 'package:bear_with_me/features/affection/domain/affection_type.dart';
import 'package:bear_with_me/features/animation/presentation/bear_choreography.dart';
import 'package:bear_with_me/features/animation/presentation/bear_vector_rig.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const hugs = [
    AffectionType.warmHug,
    AffectionType.comfortHug,
    AffectionType.cuddleTime,
    AffectionType.spinningHug,
  ];
  for (final action in hugs) {
    test(
      '${action.name}: rendered front and rear paws maintain contact through breathing and orbit',
      () {
        for (final reduced in [false, true]) {
          for (final variant in ['gentle', 'shy', 'playful']) {
            for (var i = 0; i <= 160; i++) {
              final t = .46 + i / 160 * .32;
              final f = BearChoreography.sample(
                action: action,
                t: t,
                seconds: i * .13,
                reduced: reduced,
                variant: variant,
              );
              for (final p in [f.left, f.right]) {
                for (final near in [true, false]) {
                  final requested = p.anchor(
                    near ? BearAnchor.leftPaw : BearAnchor.rightPaw,
                  );
                  expect(
                    (BearVectorRig.paw(p, near: near) - requested).distance,
                    lessThan(.01),
                    reason:
                        '$action $t ${near ? 'front' : 'rear'} arm cannot reach partner',
                  );
                }
              }
              if (action != AffectionType.spinningHug) {
                expect(
                  (f.left.anchor(BearAnchor.hug).dx -
                          f.right.anchor(BearAnchor.hug).dx)
                      .abs(),
                  lessThan(.01),
                );
              }
            }
          }
        }
      },
    );
  }

  test('comfort starts seated and sad; cuddle starts with both seated; warm stays standing', () {
    final comfort = BearChoreography.sample(
      action: AffectionType.comfortHug,
      t: .04,
    );
    expect(comfort.right.sit, 1);
    expect(comfort.right.smile, -1);
    expect(comfort.left.sit, 0);
    final cuddle = BearChoreography.sample(
      action: AffectionType.cuddleTime,
      t: .04,
    );
    expect(cuddle.left.sit, 1);
    expect(cuddle.right.sit, 1);
    final warm = BearChoreography.sample(action: AffectionType.warmHug, t: .64);
    expect(warm.left.sit + warm.right.sit, 0);
    final cuddleHold = BearChoreography.sample(
      action: AffectionType.cuddleTime,
      t: .73,
    );
    final resting = BearChoreography.sample(
      action: AffectionType.comfortHug,
      t: .73,
    );
    expect(resting.right.smile, 1);
    expect(
      (cuddleHold.right.anchor(BearAnchor.leftPaw) -
              resting.right.anchor(BearAnchor.leftPaw))
          .distance,
      greaterThan(20),
    );
    expect(
      resting.contacts
          .singleWhere((c) => c.kind == BearContactKind.shoulderRest)
          .error,
      lessThan(.01),
    );
  });

  test('sleep has replacement lying geometry, planted feet and joined rendered paws', () {
    for (var i = 0; i <= 100; i++) {
      final f = BearChoreography.sample(
        action: AffectionType.sleepTogether,
        t: i / 100,
        seconds: i * .31,
      );
      for (final p in [f.left, f.right]) {
        expect(p.recline, 1);
        expect(p.lie, 0);
        expect(p.anchor(BearAnchor.leftFoot).dy, closeTo(265, .01));
        expect(p.anchor(BearAnchor.rightFoot).dy, closeTo(265, .01));
      }
      if (i >= 50) {
        expect(
          (BearVectorRig.paw(f.left) - BearVectorRig.paw(f.right)).distance,
          lessThan(.01),
        );
      }
    }
  });

  test(
    'contact controls are independent, gated, eased and reset on interruption',
    () {
      final p = BearPlayback(action: AffectionType.cuddleTime);
      addTearDown(p.dispose);
      void configure(Set<BearSceneControl> controls, {AffectionType? action}) =>
          p.configure(
            nextAction: action ?? p.action,
            nextVariant: p.variant,
            nextReduced: false,
            nextHolding: false,
            nextStopped: false,
            nextTaps: 0,
            nextWalk: 0,
            nextControls: controls,
          );
      configure({BearSceneControl.blanket});
      p.advance(1);
      expect(p.interaction.blanket, 0);
      p.advance(4);
      final before = p.frame.left.root;
      configure({BearSceneControl.blanket});
      expect(p.frame.left.root, before);
      p.advance(.1);
      expect(p.interaction.blanket, inExclusiveRange(0, 1));
      expect(p.frame.dim, 0);
      p.advance(1);
      configure({BearSceneControl.blanket, BearSceneControl.lamp});
      p.advance(1);
      expect(p.frame.blanket, greaterThan(.99));
      expect(p.frame.dim, greaterThan(.24));
      configure({}, action: AffectionType.warmHug);
      expect(p.controls, isEmpty);
      expect(p.interaction.blanket + p.interaction.lamp, 0);
    },
  );

  test(
    'head anchors use the same rigid mirrored transform under scale and pose',
    () {
      final p = BearPose()
        ..root = const Offset(180, 265)
        ..facing = -1
        ..head = .12
        ..body = -.04
        ..sit = 1
        ..squash = .98;
      final before = p.anchor(BearAnchor.headCenter);
      const shift = Offset(11, -7);
      p.shiftHead(shift);
      expect(
        (p.anchor(BearAnchor.headCenter) - before - shift).distance,
        lessThan(1e-9),
      );
      final mirror = p.mirrored();
      for (final anchor in BearAnchor.values) {
        final a = p.anchor(anchor), b = mirror.anchor(anchor);
        expect(b.dx, closeTo(400 - a.dx, 1e-8));
        expect(b.dy, closeTo(a.dy, 1e-8));
      }
      expect(p.head, closeTo(.12, 1e-9));
    },
  );

  test('pose library contains all 24 finite reusable poses', () {
    expect(BearInteractionPose.values, hasLength(24));
    for (final pose in BearInteractionPose.values) {
      final p = BearPoseLibrary.create(pose);
      for (final anchor in BearAnchor.values) {
        final at = p.anchor(anchor);
        expect(at.dx.isFinite && at.dy.isFinite, isTrue);
      }
      expect(p.lie.abs(), lessThan(math.pi / 4));
    }
  });
}
