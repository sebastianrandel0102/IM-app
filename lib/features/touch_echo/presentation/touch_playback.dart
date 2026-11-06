import 'dart:math' as math;
import 'dart:ui';

import '../../animation/presentation/bear_choreography.dart';
import '../../animation/presentation/bear_physics.dart';
import '../../animation/presentation/bear_vector_rig.dart';
import '../domain/touch_intent.dart';

/// V1 authored two-actor poses. Primary acting -> secondary motion -> exact
/// contact correction. The rendered, reach-limited paw is the QA endpoint.
abstract final class TouchPlayback {
  static double smooth(double t) => t <= 0
      ? 0
      : t >= 1
      ? 1
      : t * t * (3 - 2 * t);
  static double ramp(double t, double a, double b) => smooth((t - a) / (b - a));
  static double contactWeight(double t) =>
      ramp(t, .14, .34) * (1 - ramp(t, .74, .91));
  static BearPose solo() => BearPose()..root = const Offset(200, 278);

  static void reaction(
    BearPose p,
    TouchKind kind,
    double weight,
    double phase,
    double amplitude, {
    bool reduced = false,
    double direction = 1,
  }) {
    final w = weight, m = reduced ? .18 : amplitude;
    p.blush = .15 + w * .55;
    p.happyEyes = .65;
    p.gaze = direction * w * 1.5;
    switch (kind) {
      case TouchKind.headPet:
        p.head += direction * .10 * w * m;
        p.eyes = 1 - w * .97;
        p.squash -= w * .018 * m;
        p.nearPaw = Offset(27, -39 - 3 * w * m);
      case TouchKind.noseBoop:
        final recoil = math.sin(phase * math.pi * 2).abs();
        p.head -= .065 * w * recoil * m;
        p.headY -= 2 * w * recoil * m;
        p.eyes = 1 - w * .9;
        p.surprise = w * .4;
      case TouchKind.cheekCaress:
        p.head += .12 * w * m * (direction == 0 ? 1 : direction);
        p.eyes = 1 - w * .94;
        p.blush = .2 + w * .7;
      case TouchKind.pawHold:
        p.head += .035 * w * m;
        p.eyes = 1 - w * .65;
        p.nearPaw = Offset(33, -39 - 9 * w * m);
      case TouchKind.bellyRub:
        p.body += math.sin(phase * math.pi * 4) * .016 * w * m;
        p.squash -= .025 * w * m;
        p.eyes = 1 - w * .9;
        p.nearPaw = Offset(35, -48 - 3 * w * m);
      case TouchKind.earRub:
        p.head += .07 * w * m;
        p.eyes = 1 - w * .97;
        p.rightEarBend = math.sin(phase * math.pi * 4) * .13 * w * m;
      case TouchKind.hugHold:
        p.embrace = w;
        p.eyes = 1 - w * .96;
        p.nearPaw = Offset(43, -56 - 4 * w);
        p.farPaw = Offset(-43, -56 - 4 * w);
        p.squash -= .02 * w * m;
      case TouchKind.backComfort:
        p.body -= .025 * w * m;
        p.head += .065 * w * m;
        p.eyes = 1 - w * .9;
        p.squash -= .01 * w * m;
      case TouchKind.heartTrace:
        p.gaze = math.sin(phase * math.pi * 2) * 2 * w * m;
        p.eyes = 1 - w * .65;
      case TouchKind.tinyTickle:
        p.body += math.sin(phase * math.pi * 10) * .04 * w * m;
        p.squash -= math.sin(phase * math.pi * 10).abs() * .025 * w * m;
        p.eyes = 1 - w * .97;
        p.nearPaw = Offset(37, -50 - 5 * w * m);
    }
  }

  static BearFrame sample(
    TouchIntent intent,
    double t, {
    bool reduced = false,
    BearSecondaryMotion? secondary,
    double motionScale = 1,
  }) {
    t = t.clamp(0, 1);
    final a = BearPose()..root = const Offset(105, 278);
    final b = BearPose()
      ..root = const Offset(295, 278)
      ..facing = -1;
    final f = BearFrame(a, b);
    final approach = ramp(t, .06, .30) * (1 - ramp(t, .86, 1));
    final w = intent.kind == TouchKind.noseBoop
        ? math.max(
            ramp(t, .13, .27) * (1 - ramp(t, .39, .49)),
            intent.repetitions > 1
                ? ramp(t, .49, .57) * (1 - ramp(t, .65, .75))
                : 0.0,
          )
        : contactWeight(t);
    final phase = ((t - .34) / .40).clamp(0.0, 1.0);
    final amp =
        (switch (intent.style) {
          TouchStyle.gentle => .65,
          TouchStyle.normal => .85,
          TouchStyle.playful => 1.0,
        }) *
        (.55 + intent.intensity * .45) *
        motionScale;
    a.root = a.root.translate(48 * approach, 0);
    b.root = b.root.translate(-48 * approach, 0);
    // Small eye anticipation, no mouth/dialogue animation.
    a.gaze = 2 * approach;
    b.gaze = 2 * approach;
    a.head = -.035 * approach * (reduced ? .2 : 1);
    a.headX = -28 * approach;
    reaction(
      b,
      intent.kind,
      w,
      phase,
      amp,
      reduced: reduced,
      direction: intent.direction,
    );
    a.ear = (secondary?.left.ear.position ?? 0) * amp;
    b.ear = (secondary?.right.ear.position ?? 0) * amp;
    if (!reduced) {
      b.head += (secondary?.right.head.position ?? 0) * amp;
      b.squash -= (secondary?.right.compression.position ?? 0) * amp;
    }
    // Each contact has a corrective pose, not an enlarged whole-body texture.
    switch (intent.kind) {
      case TouchKind.headPet:
      case TouchKind.earRub:
        b.sit = .82 * approach;
        b.headY = 13 * approach;
        a.shoulderLift = -18 * approach;
      case TouchKind.cheekCaress:
      case TouchKind.noseBoop:
        a.shoulderLift = -8 * approach;
      case TouchKind.bellyRub:
      case TouchKind.tinyTickle:
        b.nearPaw = const Offset(36, -67);
        b.farPaw = const Offset(-36, -67);
        b.headX = -5 * approach;
      case TouchKind.backComfort:
        b.turn = .45 * approach;
        b.headX = -16 * approach;
      case TouchKind.hugHold:
        a.shoulderDrop = 24;
        b.shoulderDrop = 32;
        a.embrace = b.embrace = w;
        a.headY = -14 * w;
        b.headY = 4 * w;
        a.headX = -22 * approach;
        b.headX = -22 * approach;
        a.eyes = 1 - w * .97;
        b.head = .10 * w;
        a.root = a.root.translate(20 * w, 0);
        b.root = b.root.translate(-20 * w, 0);
        a.squash = 1 - .018 * w * amp;
      case TouchKind.pawHold:
      case TouchKind.heartTrace:
        break;
    }
    Offset target = switch (intent.kind) {
      TouchKind.headPet => b.headPoint(
        Offset(
          24 - 16 * phase * intent.direction,
          -57 - 2 * math.sin(phase * math.pi),
        ),
      ),
      TouchKind.noseBoop => b.anchor(BearAnchor.nose),
      TouchKind.cheekCaress => b.headPoint(
        Offset(44, 28 + 3 * math.sin(phase * math.pi * 2)),
      ),
      TouchKind.pawHold => b.anchor(BearAnchor.leftPaw),
      TouchKind.bellyRub => b.bodyPoint(
        Offset(
          9 + 4 * math.cos(phase * math.pi * 4),
          -43 + 4 * math.sin(phase * math.pi * 4),
        ),
      ),
      TouchKind.earRub =>
        b.anchor(BearAnchor.rightEar) +
            Offset(0, 2 * math.sin(phase * math.pi * 4)),
      TouchKind.hugHold => b.bodyPoint(const Offset(-5, -40)),
      TouchKind.backComfort => b.bodyPoint(
        Offset(30, -51 + 4 * math.sin(phase * math.pi * 2)),
      ),
      TouchKind.heartTrace => b.anchor(BearAnchor.chest),
      TouchKind.tinyTickle => b.bodyPoint(
        Offset(8 + 3 * math.sin(phase * math.pi * 10), -42),
      ),
    };
    if (intent.kind == TouchKind.pawHold) {
      target =
          (a.anchor(BearAnchor.shoulder) + b.anchor(BearAnchor.shoulder)) / 2 +
          const Offset(0, 24);
      b.nearTarget = Offset.lerp(b.bodyPoint(b.nearPaw), target, w);
    }
    if (intent.kind == TouchKind.hugHold) {
      ContactAlignmentController.wrap(f, w);
      return f;
    }
    if (intent.kind == TouchKind.heartTrace) {
      f.effect = w;
      f.prop = Offset.lerp(const Offset(200, 128), target, ramp(t, .50, .73))!;
      return f;
    }
    // Reposition the grounded sender's torso during reach acquisition so the
    // anatomical shoulder-to-paw distance is inside the two-link arm envelope.
    // The receiving head remains independent; contact is re-solved after tilt.
    final shoulder = a.anchor(BearAnchor.shoulder);
    final dy = (target.dy - shoulder.dy).abs();
    final maxX = math.sqrt(math.max(0, 62 * 62 - dy * dy));
    final correction = (target.dx - shoulder.dx - maxX).clamp(-32.0, 32.0);
    a.root = a.root.translate(correction * w, 0);
    a.nearTarget = Offset.lerp(a.bodyPoint(a.nearPaw), target, w);
    f.contacts.add(
      BearContact(BearContactKind.paw, BearVectorRig.paw(a), target, w),
    );
    if (intent.kind == TouchKind.pawHold) {
      f.contacts.add(
        BearContact(BearContactKind.paw, BearVectorRig.paw(b), target, w),
      );
    }
    return f;
  }
}
