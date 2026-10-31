import 'dart:io';
import 'dart:math' as math;

import 'package:bear_with_me/features/affection/domain/affection_type.dart';
import 'package:bear_with_me/features/animation/domain/gesture_definition.dart';
import 'package:bear_with_me/features/animation/presentation/bear_artwork.dart';
import 'package:bear_with_me/features/animation/presentation/bear_choreography.dart';
import 'package:bear_with_me/features/animation/presentation/bear_motion.dart';
import 'package:flutter_test/flutter_test.dart';

void configure(
  BearPlayback p, {
  int taps = 0,
  bool hold = false,
  bool stop = false,
  double walk = 0,
}) => p.configure(
  nextAction: p.action,
  nextVariant: p.variant,
  nextReduced: p.reduced,
  nextHolding: hold,
  nextStopped: stop,
  nextTaps: taps,
  nextWalk: walk,
);

void main() {
  test('blink schedule varies, has double blinks and closes continuously', () {
    final closures = <double>[];
    var before = 1.0;
    var other = 1.0;
    var synchronized = 0;
    for (var i = 0; i < 30000; i++) {
      final seconds = i / 1000;
      final a = BearMotion.blink(seconds, 0);
      final b = BearMotion.blink(seconds, 1.9);
      expect(a, inInclusiveRange(0, 1));
      expect((a - before).abs(), lessThan(.021));
      expect((b - other).abs(), lessThan(.021));
      if (a == 0 && before > 0) closures.add(seconds);
      if (a == 0 && b == 0) synchronized++;
      before = a;
      other = b;
    }
    final intervals = [
      for (var i = 1; i < closures.length; i++) closures[i] - closures[i - 1],
    ];
    expect(intervals.any((i) => i < .4), isTrue);
    expect(intervals.any((i) => i > 4), isTrue);
    expect(synchronized, 0);
  });

  test('feet keep a grounded stance and lift only for the swing', () {
    var planted = 0, lifted = 0;
    for (var i = 0; i < 100; i++) {
      final foot = BearMotion.foot(i / 100 * math.pi * 2, 1, 1);
      if (foot.dy == 0) planted++;
      if (foot.dy < -1) lifted++;
      expect(foot.dx, inInclusiveRange(-5, 5));
      expect(foot.dy, inInclusiveRange(-4, 0));
    }
    expect(planted, greaterThanOrEqualTo(62));
    expect(lifted, greaterThan(20));
    expect(BearMotion.foot(.7, 1, 0).distance, 0);
  });

  test('early return kiss is consumed and cannot become a stale input', () {
    final p = BearPlayback(action: AffectionType.cheekKiss);
    addTearDown(p.dispose);
    p.advance(1);
    configure(p, taps: 1);
    expect(p.taps, 0);
    p.advance(5);
    configure(p, taps: 1);
    expect(p.taps, 0);
    final before = p.frame.left.root;
    configure(p, taps: 2);
    expect(p.taps, 1);
    expect(p.progress, .18);
    expect((p.frame.left.root - before).distance, lessThan(.01));
  });

  test('high five tap window excludes the impact recovery', () {
    final p = BearPlayback(action: AffectionType.highFive);
    addTearDown(p.dispose);
    expect(p.canReact, isFalse);
    p.advance(1.5);
    expect(p.canReact, isTrue);
    configure(p, taps: 1);
    expect(p.progress, greaterThanOrEqualTo(.37));
    p.advance(1.3);
    expect(p.canReact, isFalse);
    final progress = p.progress;
    configure(p, taps: 2);
    expect(p.progress, progress);
  });

  test('contact events follow authored timings for every gesture', () {
    for (final action in AffectionType.values) {
      final events = <BearAnimationEvent>[];
      final p = BearPlayback(action: action, onEvent: events.add);
      final d = BearGestureDefinition.of(action);
      final duration = p.duration.inMicroseconds / 1e6;
      p.advance((d.contactAt - .001) * duration);
      expect(
        events,
        isNot(contains(BearAnimationEvent.contactStarted)),
        reason: action.name,
      );
      p.advance(.002 * duration);
      expect(
        events.where((e) => e == BearAnimationEvent.contactStarted),
        hasLength(1),
      );
      p.advance(duration * 2);
      p.advance(duration);
      expect(events.first, BearAnimationEvent.started);
      expect(events.last, BearAnimationEvent.completed);
      expect(events.toSet().length, events.length);
      p.dispose();
    }
  });

  test('every gesture cancels continuously and completes recovery once', () {
    for (final action in AffectionType.values) {
      final events = <BearAnimationEvent>[];
      var completions = 0;
      final p = BearPlayback(
        action: action,
        onEvent: events.add,
        onComplete: () => completions++,
      );
      p.advance(p.duration.inMicroseconds / 2e6);
      final before = p.frame.left.root;
      configure(p, stop: true);
      expect(p.stage, BearStage.cancelled);
      expect(p.frame.left.root, before);
      p.advance(20);
      configure(p, stop: true, taps: 1);
      p.advance(20);
      expect(
        events.where((e) => e == BearAnimationEvent.cancelled),
        hasLength(1),
      );
      expect(completions, 1);
      expect(p.canReact, isFalse);
      expect(p.settled, isTrue);
      p.dispose();
    }
  });

  test(
    'holding reports contact before hold and releases without restarting',
    () {
      final events = <BearAnimationEvent>[];
      final p = BearPlayback(
        action: AffectionType.warmHug,
        onEvent: events.add,
      );
      addTearDown(p.dispose);
      configure(p, hold: true);
      p.advance(20);
      expect(
        events,
        containsAllInOrder([
          BearAnimationEvent.started,
          BearAnimationEvent.contactStarted,
          BearAnimationEvent.interactiveHoldStarted,
        ]),
      );
      expect(events, isNot(contains(BearAnimationEvent.completed)));
      final before = p.frame.left.root;
      configure(p);
      expect(p.frame.left.root, before);
      p.advance(20);
      expect(
        events,
        containsAllInOrder([
          BearAnimationEvent.interactiveHoldEnded,
          BearAnimationEvent.completed,
        ]),
      );
    },
  );

  test('walking waits for attachment and phase follows actual distance', () {
    final p = BearPlayback(action: AffectionType.holdingHands);
    addTearDown(p.dispose);
    configure(p, walk: 25);
    p.advance(8);
    expect(p.walk, 0);
    configure(p, walk: 25);
    p.advance(.1);
    expect(p.walk, greaterThan(0));
    expect(
      p.stride,
      closeTo(p.walk / BearMotion.strideLength * math.pi * 2, .001),
    );
    expect(p.frame.left.gaitDirection, -p.frame.right.gaitDirection);
  });

  test('sleep closes eyes through the ending; upright spin keeps its roots grounded', () {
    final night = BearChoreography.sample(
      action: AffectionType.goodnightKiss,
      t: 1,
    );
    expect(night.right.eyes, 0);
    for (var i = 0; i <= 200; i++) {
      final f = BearChoreography.sample(
        action: AffectionType.spinningHug,
        t: i / 200,
      );
      expect(f.left.root.dy, inInclusiveRange(270, 285));
      expect(f.right.root.dy, inInclusiveRange(270, 285));
      expect(f.left.body.abs(), lessThan(.09));
      expect(f.right.body.abs(), lessThan(.09));
    }
  });

  test('export both layered SVG masters from runtime vector contours', () {
    final dir = Directory('artifacts/animations/masters')
      ..createSync(recursive: true);
    for (final bear in BearCharacter.values) {
      File('${dir.path}/${bear.name}.svg')
          .writeAsStringSync(BearArtwork.masterSvg(bear));
    }
  });
}
