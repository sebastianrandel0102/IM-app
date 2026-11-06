import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:bear_with_me/features/touch_echo/domain/touch_intent.dart';
import 'package:bear_with_me/features/touch_echo/domain/touch_classifier.dart';
import 'package:bear_with_me/features/touch_echo/presentation/touch_input_controller.dart';
import 'package:bear_with_me/features/touch_echo/presentation/touch_geometry.dart';
import 'package:bear_with_me/features/touch_echo/presentation/touch_playback.dart';
import 'package:bear_with_me/features/animation/presentation/bear_choreography.dart';
import 'package:bear_with_me/features/animation/presentation/bear_physics.dart';
import 'package:bear_with_me/features/animation/presentation/bear_vector_rig.dart';

List<TouchSample> path(List<Offset> points, int ms) => [
  for (var i = 0; i < points.length; i++)
    TouchSample(
      points[i],
      Duration(milliseconds: (ms * i / (points.length - 1)).round()),
    ),
];
List<Offset> line(Offset a, Offset b) =>
    List.generate(24, (i) => Offset.lerp(a, b, i / 23)!);
TouchIntent intent(TouchKind k, {TouchStyle style = TouchStyle.gentle}) =>
    TouchIntent(
      kind: k,
      style: style,
      intensity: .4,
      durationMs: 1800,
      seed: 123,
    );
void main() {
  test(
    'head pet, boop, paw hold positive recognition and swipe/tremor rejection',
    () {
      expect(
        TouchClassifier.classify(
          path(line(const Offset(1, 1), const Offset(1.5, 1.1)), 1100),
          TouchZone.head,
        ).intent?.kind,
        TouchKind.headPet,
      );
      expect(
        TouchClassifier.classify(
          path(line(const Offset(1, 1), const Offset(1.5, 1.1)), 80),
          TouchZone.head,
        ).intent,
        isNull,
      );
      expect(
        TouchClassifier.classify(
          path([const Offset(1, 1), const Offset(1.01, 1)], 90),
          TouchZone.nose,
        ).intent?.kind,
        TouchKind.noseBoop,
      );
      expect(
        TouchClassifier.classify(
          path([const Offset(1, 1), const Offset(1.01, 1)], 900),
          TouchZone.paw,
        ).intent?.kind,
        TouchKind.pawHold,
      );
      expect(
        TouchClassifier.classify(
          path([const Offset(1, 1), const Offset(1.01, 1)], 90),
          TouchZone.paw,
        ).intent,
        isNull,
      );
      expect(
        TouchClassifier.classify(
          path(List.generate(30, (i) => Offset(1 + i % 2 * .001, 1)), 900),
          TouchZone.belly,
        ).intent,
        isNull,
      );
    },
  );
  test('all remaining recognizers are distinct and circles support both directions', () {
    expect(
      TouchClassifier.classify(
        path(line(const Offset(1, 1), const Offset(1.4, 1.1)), 900),
        TouchZone.cheek,
      ).intent?.kind,
      TouchKind.cheekCaress,
    );
    expect(
      TouchClassifier.classify(
        path(line(const Offset(1, 1), const Offset(1.4, 1.1)), 1000),
        TouchZone.back,
      ).intent?.kind,
      TouchKind.backComfort,
    );
    expect(
      TouchClassifier.classify(
        path([const Offset(1, 1), const Offset(1, 1)], 1100),
        TouchZone.chest,
      ).intent?.kind,
      TouchKind.hugHold,
    );
    final rub = List.generate(9, (i) => Offset(1 + i % 2 * .12, 1));
    expect(
      TouchClassifier.classify(path(rub, 800), TouchZone.ear).intent?.kind,
      TouchKind.earRub,
    );
    expect(
      TouchClassifier.classify(path(rub, 800), TouchZone.belly).intent?.kind,
      TouchKind.tinyTickle,
    );
    for (final sign in [-1, 1]) {
      final circle = List.generate(
        49,
        (i) => Offset(
          1 + .18 * math.cos(i / 48 * math.pi * 2 * sign),
          1 + .18 * math.sin(i / 48 * math.pi * 2 * sign),
        ),
      );
      expect(
        TouchClassifier.classify(
          path(circle, 1400),
          TouchZone.belly,
        ).intent?.kind,
        TouchKind.bellyRub,
      );
    }
    final heart = List.generate(65, (i) {
      final t = i / 64 * math.pi * 2;
      return Offset(
        1 + 16 * math.pow(math.sin(t), 3).toDouble() / 40,
        1 -
            (13 * math.cos(t) -
                    5 * math.cos(2 * t) -
                    2 * math.cos(3 * t) -
                    math.cos(4 * t)) /
                40,
      );
    });
    expect(
      TouchClassifier.classify(
        path(heart, 2200),
        TouchZone.heart,
        heartMode: true,
      ).intent?.kind,
      TouchKind.heartTrace,
    );
    expect(
      TouchClassifier.classify(path(heart, 2200), TouchZone.heart).intent,
      isNull,
    );
    expect(
      TouchClassifier.classify(path(heart, 2200), TouchZone.belly).intent,
      isNull,
      reason: 'A heart drawn on the belly outside Draw a Heart is ambiguous, not a circular rub',
    );
    final circle = List.generate(
      65,
      (i) => Offset(
        1 + .4 * math.cos(i / 64 * math.pi * 2),
        1 + .4 * math.sin(i / 64 * math.pi * 2),
      ),
    );
    expect(
      TouchClassifier.classify(
        path(circle, 2200),
        TouchZone.heart,
        heartMode: true,
      ).intent,
      isNull,
    );
  });
  testWidgets(
    'double boop yields one result; distant taps remain separate; cancel clears temporary input',
    (tester) async {
      final results = <TouchResult>[];
      final c = TouchInputController(onResult: results.add);
      void tap(int id, Offset at, int t) {
        c.begin(id, TouchZone.nose, at, Duration(milliseconds: t));
        c.end(id, at, Duration(milliseconds: t + 70), inside: true);
      }

      tap(1, const Offset(1, 1), 0);
      await tester.pump(const Duration(milliseconds: 150));
      tap(2, const Offset(1.02, 1), 200);
      await tester.pump(const Duration(milliseconds: 400));
      expect(results.length, 1);
      expect(results.single.intent?.repetitions, 2);
      results.clear();
      tap(3, const Offset(1, 1), 1000);
      tap(4, const Offset(2, 1), 1200);
      await tester.pump(const Duration(milliseconds: 400));
      expect(results.length, 2);
      c.begin(5, TouchZone.paw, const Offset(1, 1), const Duration(seconds: 3));
      c.cancel();
      expect(c.samples, isEmpty);
      expect(c.tracking, false);
      expect(results.last.result, TouchResultKind.canceled);
      c.begin(6, null, const Offset(0, 0), const Duration(seconds: 4));
      expect(c.tracking, false);
      c.begin(
        7,
        TouchZone.head,
        const Offset(1, 1),
        const Duration(seconds: 5),
      );
      c.begin(
        8,
        TouchZone.head,
        const Offset(1, 1),
        const Duration(seconds: 5),
      );
      expect(c.tracking, false);
      c.dispose();
    },
  );
  test('payload validation rejects nonfinite, oversized, unknown and wrong-zone values', () {
    final d = intent(TouchKind.headPet).toJson();
    expect(TouchIntent.fromJson(d).toJson(), d);
    for (final bad in [
      {'intensity': double.nan},
      {'durationMs': 999999},
      {'zone': 'nose'},
      {'animationVersion': 99},
      {'kind': 'talk'},
      {'normalizedTrace': List.filled(10000, 0)},
      {'repetitions': 0},
    ]) {
      expect(() => TouchIntent.fromJson({...d, ...bad}), throwsFormatException);
    }
  });
  test('rig mapping survives letterboxes, transformed heads and DPI', () {
    final p = TouchPlayback.solo()
      ..head = .1
      ..body = .03;
    expect(
      TouchGeometry.hit(p, p.headPoint(const Offset(0, -25))),
      TouchZone.head,
    );
    expect(TouchGeometry.hit(p, p.anchor(BearAnchor.nose)), TouchZone.nose);
    for (final size in [
      const Size(320, 500),
      const Size(1000, 360),
      const Size(800, 680),
    ]) {
      final scale = math.min(size.width / 400, size.height / 340),
          point = p.anchor(BearAnchor.nose);
      final screen =
          point * scale +
          Offset(
            (size.width - 400 * scale) / 2,
            (size.height - 340 * scale) / 2,
          );
      expect(
        (TouchGeometry.scenePoint(screen, size)! - point).distance,
        lessThan(.00001),
      );
    }
    expect(TouchGeometry.hit(p, const Offset(0, 0)), isNull);
  });
  test('actual rendered contact endpoints hold across styles and timestep rates', () {
    for (final kind in TouchKind.values) {
      for (final style in TouchStyle.values) {
        final i = intent(kind, style: style);
        for (final fps in [30, 60]) {
          final secondary = BearSecondaryMotion();
          secondary.right.head.damping = style == TouchStyle.playful ? .85 : 1;
          secondary.right.ear.damping = style == TouchStyle.gentle
              ? .97
              : style == TouchStyle.normal
              ? .85
              : .73;
          var started = false;
          for (var tick = 0; tick <= fps * i.playbackMs / 1000; tick++) {
            final t = tick / (fps * i.playbackMs / 1000);
            if (!started && t >= .34) {
              started = true;
              secondary.right.react(switch (kind) {
                TouchKind.noseBoop => BearReaction.boop,
                TouchKind.tinyTickle => BearReaction.belly,
                TouchKind.backComfort ||
                TouchKind.hugHold => BearReaction.relax,
                _ => BearReaction.pet,
              });
            }
            secondary.advance(
              1 / fps,
              rightHead: TouchPlayback.sample(i, t).right.head,
            );
            final f = TouchPlayback.sample(i, t, secondary: secondary);
            for (final p in [f.left, f.right]) {
              expect(p.head.abs(), lessThan(.4));
              expect(p.squash, inInclusiveRange(.9, 1.1));
              expect(
                (BearVectorRig.paw(p) - p.anchor(BearAnchor.shoulder)).distance,
                lessThanOrEqualTo(64.00001),
              );
            }
            if (t >= .35 && t <= .73) {
              for (final contact in f.contacts.where((c) => c.weight > .99)) {
                expect(
                  contact.error,
                  lessThan(1.2),
                  reason: '${kind.name} ${style.name} t=$t rendered contact',
                );
              }
            }
            if (kind == TouchKind.hugHold) {
              for (var index = 0; index < f.contacts.length; index++) {
                if (f.contacts[index].weight < .99) {
                  continue;
                }
                final actor = index.isEven ? f.left : f.right;
                expect(
                  (BearVectorRig.paw(actor, near: index < 2) -
                          f.contacts[index].to)
                      .distance,
                  lessThan(1.2),
                  reason:
                      'Both front and rear hug paws must reach their rendered targets: ${style.name}, t=$t',
                );
              }
            }
          }
        }
        final end = TouchPlayback.sample(i, 1);
        expect(end.left.root, const Offset(105, 278));
        expect(end.right.root, const Offset(295, 278));
        expect(end.right.head, 0);
        expect(end.right.eyes, 1);
        expect(
          TouchPlayback.sample(i, .55, reduced: true).right.head.abs(),
          lessThan(.15),
        );
      }
    }
  });
}
