import 'dart:math' as math;

import 'package:flutter/animation.dart';
import 'package:flutter/foundation.dart';

import '../../affection/domain/affection_type.dart';

enum BearStage {
  idle,
  attention,
  anticipation,
  approach,
  contact,
  reaction,
  hold,
  recovery,
  complete,
}

enum BearAnchor {
  cheek,
  forehead,
  nose,
  leftPaw,
  rightPaw,
  shoulder,
  torso,
  hug,
  seat,
  back,
}

/// The vector rig's coordinates, also used by contact constraints and QA.
/// Head transforms are rigid; squash is confined to the torso. Arms use a
/// two-link solve with a bounded reach instead of stretching the artwork.
class BearPose {
  Offset root = const Offset(132, 278);
  double facing = 1, body = 0, head = 0, headX = 0, headY = 0;
  double squash = 1, sit = 0, lie = 0, step = 0;
  double eyes = 1, gaze = 0, smile = 1, blush = .15, surprise = 0;
  double ear = 0, breath = 0, cheek = 0, turn = 0;
  Offset nearPaw = const Offset(27, -39), farPaw = const Offset(-28, -40);
  Offset? nearTarget, farTarget;

  Offset bodyPoint(Offset p) {
    final scaled = Offset(p.dx * facing / squash, p.dy * squash + sit * 18);
    final a = body + lie;
    return root +
        Offset(
          scaled.dx * math.cos(a) - scaled.dy * math.sin(a),
          scaled.dx * math.sin(a) + scaled.dy * math.cos(a),
        );
  }

  Offset headPoint(Offset p) {
    final origin = bodyPoint(Offset(headX, -113 + headY - breath));
    final local = Offset(
      (p.dx * math.cos(head) - p.dy * math.sin(head)) * facing,
      p.dx * math.sin(head) + p.dy * math.cos(head),
    );
    final a = body + lie;
    return origin +
        Offset(
          local.dx * math.cos(a) - local.dy * math.sin(a),
          local.dx * math.sin(a) + local.dy * math.cos(a),
        );
  }

  Offset anchor(BearAnchor a) => switch (a) {
    BearAnchor.cheek => headPoint(const Offset(60, 24)),
    BearAnchor.forehead => headPoint(const Offset(35, -45)),
    BearAnchor.nose => headPoint(Offset(9 + turn * 43, 25)),
    BearAnchor.leftPaw => nearTarget ?? bodyPoint(nearPaw),
    BearAnchor.rightPaw => farTarget ?? bodyPoint(farPaw),
    BearAnchor.shoulder => bodyPoint(const Offset(23, -80)),
    BearAnchor.torso => bodyPoint(const Offset(0, -54)),
    BearAnchor.hug => bodyPoint(const Offset(28, -59)),
    BearAnchor.seat => bodyPoint(const Offset(0, -18)),
    BearAnchor.back => bodyPoint(const Offset(-22, -85)),
  };

  BearPose mirrored() {
    final result = blend(this, this, 0);
    result.root = Offset(400 - root.dx, root.dy);
    result.facing = -facing;
    result.body = -body;
    result.lie = -lie;
    result.nearTarget = nearTarget == null
        ? null
        : Offset(400 - nearTarget!.dx, nearTarget!.dy);
    result.farTarget = farTarget == null
        ? null
        : Offset(400 - farTarget!.dx, farTarget!.dy);
    return result;
  }

  static BearPose blend(BearPose a, BearPose b, double t) {
    double mix(double x, double y) => x + (y - x) * t;
    return BearPose()
      ..root = Offset.lerp(a.root, b.root, t)!
      ..facing = b.facing
      ..body = mix(a.body, b.body)
      ..head = mix(a.head, b.head)
      ..headX = mix(a.headX, b.headX)
      ..headY = mix(a.headY, b.headY)
      ..squash = mix(a.squash, b.squash)
      ..sit = mix(a.sit, b.sit)
      ..lie = mix(a.lie, b.lie)
      ..step = mix(a.step, b.step)
      ..eyes = mix(a.eyes, b.eyes)
      ..gaze = mix(a.gaze, b.gaze)
      ..smile = mix(a.smile, b.smile)
      ..blush = mix(a.blush, b.blush)
      ..surprise = mix(a.surprise, b.surprise)
      ..ear = mix(a.ear, b.ear)
      ..breath = mix(a.breath, b.breath)
      ..cheek = mix(a.cheek, b.cheek)
      ..turn = mix(a.turn, b.turn)
      ..nearPaw = Offset.lerp(a.nearPaw, b.nearPaw, t)!
      ..farPaw = Offset.lerp(a.farPaw, b.farPaw, t)!
      ..nearTarget = Offset.lerp(
        a.anchor(BearAnchor.leftPaw),
        b.anchor(BearAnchor.leftPaw),
        t,
      )
      ..farTarget = Offset.lerp(
        a.anchor(BearAnchor.rightPaw),
        b.anchor(BearAnchor.rightPaw),
        t,
      );
  }
}

class BearFrame {
  BearFrame(this.left, this.right);
  final BearPose left, right;
  Offset prop = const Offset(200, 220);
  double reveal = 0,
      effect = 0,
      blanket = 0,
      spin = 0,
      tear = 0,
      dim = 0,
      bloom = 0;
  static BearFrame blend(BearFrame a, BearFrame b, double t) =>
      BearFrame(
          BearPose.blend(a.left, b.left, t),
          BearPose.blend(a.right, b.right, t),
        )
        ..prop = Offset.lerp(a.prop, b.prop, t)!
        ..reveal = a.reveal + (b.reveal - a.reveal) * t
        ..effect = a.effect + (b.effect - a.effect) * t
        ..blanket = a.blanket + (b.blanket - a.blanket) * t
        ..spin =
            a.spin +
            math.atan2(math.sin(b.spin - a.spin), math.cos(b.spin - a.spin)) * t
        ..tear = a.tear + (b.tear - a.tear) * t
        ..dim = a.dim + (b.dim - a.dim) * t
        ..bloom = a.bloom + (b.bloom - a.bloom) * t;
}

class BearChoreography {
  static const contactTime = .46, holdTime = .64, recoveryTime = .78;
  static bool canHold(AffectionType? a) => [
    AffectionType.warmHug,
    AffectionType.comfortHug,
    AffectionType.cuddleTime,
  ].contains(a);
  static Duration duration(AffectionType? a, String variant) {
    final seconds = switch (a) {
      AffectionType.noseBoop => 4.4,
      AffectionType.highFive => 4.8,
      AffectionType.headPat => 5.8,
      AffectionType.happyDance => 6.4,
      AffectionType.comfortHug => 9.6,
      AffectionType.sleepTogether => 10.0,
      AffectionType.goodnightKiss => 9.2,
      AffectionType.shyConfession => 9.0,
      AffectionType.iMissYou => 9.4,
      AffectionType.cuddleTime => 8.8,
      _ => 7.2,
    };
    return Duration(
      milliseconds:
          (seconds *
                  1000 *
                  (variant == 'shy'
                      ? 1.15
                      : variant == 'playful'
                      ? .88
                      : 1))
              .round(),
    );
  }

  static BearStage stage(double t, {bool holding = false}) => t >= 1
      ? BearStage.complete
      : holding && t >= holdTime
      ? BearStage.hold
      : t < .08
      ? BearStage.idle
      : t < .16
      ? BearStage.attention
      : t < .25
      ? BearStage.anticipation
      : t < .43
      ? BearStage.approach
      : t < .52
      ? BearStage.contact
      : t < .68
      ? BearStage.reaction
      : t < .78
      ? BearStage.hold
      : BearStage.recovery;

  static double ease(
    double t,
    double start,
    double end, [
    Curve curve = const Cubic(.42, 0, .18, 1),
  ]) => curve.transform(((t - start) / (end - start)).clamp(0.0, 1.0));
  static double window(double t, double a, double b, double c, double d) =>
      ease(t, a, b) * (1 - ease(t, c, d));
  static double settle(double t, double at, double strength) {
    final x = t - at;
    return x < 0 ? 0 : math.sin(x * 65) * math.exp(-x * 19) * strength;
  }

  static double blink(double seconds, double offset) {
    final p = (seconds + offset) % 4.7;
    return 1 - window(p, 3.72, 3.78, 3.83, 3.92);
  }

  static BearFrame sample({
    AffectionType? action,
    required double t,
    double seconds = 0,
    bool reduced = false,
    int taps = 0,
    double walk = 0,
    double locomotion = 0,
    double input = 0,
    bool stopped = false,
    String variant = 'gentle',
  }) {
    if (action == AffectionType.wipeAwayTears && taps > 0 && t < .65) {
      t = math.max(t, .43 + .22 * ease(input, 0, .7));
    }
    final l = BearPose(),
        r = BearPose()
          ..root = const Offset(268, 278)
          ..facing = -1;
    final frame = BearFrame(l, r);
    final amplitude = reduced ? 0.0 : 1.0;
    final mood = variant == 'playful'
        ? 1.15
        : variant == 'shy'
        ? .65
        : 1.0;
    final attention = ease(t, .06, .16);
    final soft = action?.category == 'Comfort' || action?.category == 'Cozy';
    final approach = ease(
      t,
      .22,
      .43,
      soft ? const Cubic(.45, 0, .30, 1) : const Cubic(.42, 0, .18, 1),
    );
    final release = 1 - ease(t, .78, .98);
    final contact = approach * release;
    final react = ease(t, .46, .60);
    final active = window(t, .34, .46, .72, .92);
    final impact = reduced ? 0.0 : settle(t, .46, 1);
    final pulse = reduced
        ? 0.0
        : math.sin(input * math.pi) * (input < 1 ? 1 : 0);
    l.gaze = attention * 2;
    r.gaze = attention * 2;
    l.head = -.035 * attention;
    r.head = -.025 * attention;
    l.blush += react * .42;
    r.blush += react * .6;
    if (!reduced && !stopped) {
      l.breath = math.sin(seconds * 1.65) * .65;
      r.breath = math.sin(seconds * 1.49 + .9) * .65;
      l.eyes = blink(seconds, 0);
      r.eyes = blink(seconds, 1.9);
      l.ear = math.sin(seconds * 1.65 - .3) * .012;
      r.ear = math.sin(seconds * 1.49 + .5) * .012;
    }
    if (action == null) return frame;
    // A short, grounded walking breakdown during approach; no endless root bob.
    final walksIn = ![
      AffectionType.sleepTogether,
      AffectionType.happyDance,
      AffectionType.holdingHands,
      AffectionType.highFive,
    ].contains(action);
    final steps =
        math.sin(ease(t, .22, .43) * math.pi * 4) *
        window(t, .22, .26, .39, .43) *
        amplitude *
        (walksIn ? 1 : 0);
    l.step = steps * 3;
    l.root = l.root.translate(0, -steps.abs() * 1.5);
    l.farPaw = l.farPaw.translate(steps * 2, 0);

    switch (action) {
      case AffectionType.warmHug:
      case AffectionType.comfortHug:
      case AffectionType.cuddleTime:
      case AffectionType.spinningHug:
        final comfort = action == AffectionType.comfortHug;
        final cozy = action == AffectionType.cuddleTime;
        final welcome = window(t, .12, .23, .30, .44);
        l.farPaw = Offset(-28 - 23 * welcome, -40 - 6 * welcome);
        r.farPaw = Offset(-28 - 12 * welcome, -40 - 4 * welcome);
        final squeeze = contact + impact * .025;
        l.root = l.root.translate(28 * contact, 0);
        r.root = r.root.translate(-28 * contact, 0);
        // Outward neck corrections protect the original large head silhouettes.
        l.headX = -28 * contact;
        r.headX = -28 * contact;
        l.body = .025 * contact;
        r.body = -.025 * contact;
        l.nearPaw = Offset(28 + 21 * contact, -39 - 23 * contact);
        r.nearPaw = Offset(28 + 21 * contact, -39 - 20 * contact);
        l.squash = 1 - .025 * squeeze;
        r.squash = 1 - .022 * squeeze;
        l.eyes *= 1 - active;
        r.eyes *= 1 - active;
        l.head = .045 * contact;
        r.head = .055 * contact;
        final sway =
            math.sin(seconds * (comfort ? 1.1 : 1.6)) *
            .012 *
            active *
            amplitude;
        l.body += sway;
        r.body += sway;
        if (comfort) {
          r.smile = -1 + react * 2;
          r.headY = 8 * (1 - react);
          r.ear -= .045 * (1 - react);
        }
        if (cozy) {
          l.sit = approach;
          r.sit = ease(t, .17, .40);
          frame.blanket = taps > 0 ? ease(input, 0, .5) : 0;
        }
        if (action == AffectionType.spinningHug) {
          frame.spin =
              math.pi * 2 * ease(t, .50, .80, Curves.easeInOutSine) * amplitude;
          l.step += math.sin(t * 28) * active * 2 * amplitude;
          r.step = -l.step;
        }
        l.nearTarget = Offset.lerp(
          l.bodyPoint(Offset(27 + 20 * welcome, -39 - 5 * welcome)),
          r.bodyPoint(const Offset(26, -45)),
          contact,
        );
        r.nearTarget = Offset.lerp(
          r.bodyPoint(const Offset(27, -39)),
          l.bodyPoint(const Offset(26, -49)),
          contact,
        );
      case AffectionType.cheekKiss:
      case AffectionType.foreheadKiss:
      case AffectionType.goodnightKiss:
        final forehead = action != AffectionType.cheekKiss;
        final kiss = window(t, .34, .46, .56, .74);
        if (action == AffectionType.goodnightKiss) r.sit = .65;
        l.root = l.root.translate(8 * contact, 0);
        l.head = -.13 * kiss;
        l.headY = (forehead ? -32 : -4) * kiss;
        r.headY = forehead ? 27 * kiss : 0;
        r.head = forehead ? .12 * kiss : -.045 * react;
        l.turn = kiss;
        // The nose and target are solved in rig space; only translation is
        // corrected, never face scaling or head elongation.
        final target = r.anchor(
          forehead ? BearAnchor.forehead : BearAnchor.cheek,
        );
        final nose = l.anchor(BearAnchor.nose);
        l.root = l.root.translate((target.dx - nose.dx) * kiss, 0);
        l.headY += (target.dy - nose.dy) * kiss;
        l.eyes *= 1 - kiss;
        r.eyes *= 1 - (forehead ? kiss : react * release);
        r.surprise = forehead ? 0 : window(t, .46, .49, .52, .59);
        r.cheek = kiss * .07;
        r.nearPaw = Offset(27 + react * 8, -39 - react * 25);
        frame.prop = target.translate(0, -28);
        frame.effect = window(t, .47, .52, .63, .78);
        if (action == AffectionType.goodnightKiss) {
          r.sit = .65;
          frame.blanket = ease(t, .15, .37);
          frame.dim = ease(t, .7, .96) * .3 + (taps.isOdd ? .18 : 0);
        }
      case AffectionType.holdingHands:
      case AffectionType.highFive:
        final high = action == AffectionType.highFive;
        final reach = high
            ? window(t, .22, .46, .57, .83)
            : ease(t, .22, .46, const Cubic(.35, 0, .25, 1));
        final target = Offset(200, high ? 166 : 225);
        l.nearTarget = Offset.lerp(l.bodyPoint(l.nearPaw), target, reach);
        r.nearTarget = Offset.lerp(r.bodyPoint(r.nearPaw), target, reach);
        l.squash = 1 - impact * .025;
        r.squash = 1 - impact * .025;
        if (high) {
          l.head = -.06 * active;
          r.head = -.08 * active;
          frame.prop = target;
          frame.effect = window(t, .46, .48, .52, .61);
        } else {
          final walking =
              amplitude * math.sin(seconds * 7) * locomotion * reach;
          l.step = walking * 3;
          r.step = -walking * 3;
          l.root = l.root.translate(walk, -walking.abs());
          r.root = r.root.translate(walk, -walking.abs());
          l.nearTarget = l.nearTarget!.translate(walk, -walking.abs());
          r.nearTarget = l.nearTarget;
        }
      case AffectionType.headPat:
      case AffectionType.noseBoop:
      case AffectionType.wipeAwayTears:
        final pat = action == AffectionType.headPat;
        final wipe = action == AffectionType.wipeAwayTears;
        final reach = window(t, .20, .43, .66, .90);
        r.head = (pat ? .03 : -.04) * active;
        // Bring the shoulders up with the torso, so a short paw can reach the
        // recipient's face. This is a crouching recipient, not a longer arm.
        r.headY = (pat ? 37 : 16) * reach;
        r.turn = !pat && !wipe ? reach : 0;
        r.sit = .45 * reach;
        l.headX = -10 * reach;
        l.headY = -8 * reach;
        l.root = l.root.translate(24 * reach, 0);
        final tapWave = pat
            ? math.sin((t - .43) * 45) *
                  3 *
                  window(t, .40, .44, .62, .67) *
                  amplitude
            : 0.0;
        final target = r.anchor(
          pat
              ? BearAnchor.forehead
              : wipe
              ? BearAnchor.cheek
              : BearAnchor.nose,
        );
        final wipeArc = wipe
            ? Offset(
                -6 * ease(t, .46, .62),
                8 * math.sin(ease(t, .46, .62) * math.pi),
              )
            : Offset(0, -tapWave.abs());
        l.nearTarget = Offset.lerp(
          l.bodyPoint(l.nearPaw),
          target + wipeArc,
          reach,
        );
        r.eyes *= 1 - active;
        r.ear += (pat ? settle(t, .46, .09) : impact * .04) * amplitude;
        r.surprise = pat || wipe ? 0 : window(t, .45, .48, .51, .58);
        r.smile = wipe ? -1 + react * 2 : 1;
        frame.tear = wipe ? 1 - ease(t, .50, .65) : 0;
        frame.prop = r
            .anchor(BearAnchor.cheek)
            .translate(0, 5 + 10 * ease(t, .1, .5));
      case AffectionType.blowingKisses:
        final lift = window(t, .15, .30, .38, .54);
        l.head = -.08 * lift;
        l.nearTarget = Offset.lerp(
          l.bodyPoint(l.nearPaw),
          l.anchor(BearAnchor.nose).translate(0, 5),
          lift,
        );
        l.eyes *= 1 - lift;
        final flight = math.max(
          ease(t, .36, .66, Curves.easeInOutSine),
          taps > 0 ? ease(input, 0, .45) : 0.0,
        );
        final from = l.anchor(BearAnchor.nose).translate(10, 0),
            to = r.anchor(BearAnchor.cheek);
        frame.prop = Offset.lerp(
          from,
          to,
          flight,
        )!.translate(0, -math.sin(flight * math.pi) * 40);
        frame.reveal = math.max(
          window(t, .33, .39, .72, .82),
          taps > 0 ? window(input, 0, .08, .65, .9) : 0.0,
        );
        r.head = -.05 * react;
        r.eyes *=
            1 -
            math.max(
              window(t, .65, .69, .73, .78),
              taps > 0 ? window(input, .1, .2, .5, .7) : 0.0,
            );
        r.nearPaw = Offset(27 + react * 12, -39 - react * 31);
      case AffectionType.goodMorning:
        final wake = math.max(
          ease(t, .43, .68),
          taps > 0 ? ease(input, .05, .65) : 0.0,
        );
        r.sit = .45 * (1 - wake);
        r.eyes *= wake;
        r.headY = 9 * (1 - wake);
        r.nearPaw = Offset(27 + 43 * active, -39 - 53 * active);
        r.farPaw = Offset(-28 - 42 * active, -40 - 52 * active);
        r.squash = 1 + .025 * active;
        r.smile = wake;
        l.root = l.root.translate(30 * approach, 0);
        l.headX = -30 * approach;
        l.nearTarget = Offset.lerp(
          l.bodyPoint(l.nearPaw),
          r.anchor(BearAnchor.hug),
          active,
        );
        frame.reveal = wake;
        frame.prop = const Offset(308, 66);
      case AffectionType.happyDance:
        final beat = (t - .26) * math.pi * (taps.isEven ? 10 : 14);
        for (final (p, lag) in [(l, 0.0), (r, .55)]) {
          final rhythm = math.sin(beat - lag) * active * amplitude * mood;
          p.root = p.root.translate(rhythm * 7, -rhythm.abs() * 5);
          p.body = rhythm * .07;
          p.head = -rhythm * .045;
          p.step = rhythm * 6;
          p.squash = 1 + math.sin(beat * 2 - lag) * active * .025 * amplitude;
          p.nearPaw = Offset(31 + rhythm * 7, -59 - rhythm * 14);
          p.farPaw = Offset(-31 - rhythm * 7, -59 + rhythm * 14);
          p.ear += math.sin(beat - lag - .4) * active * .04 * amplitude;
        }
      case AffectionType.piggybackRide:
        final attached = ease(t, .28, .50);
        l.sit = window(t, .14, .29, .50, .66) * .8;
        l.body = .06 * attached;
        l.squash = 1 - .035 * attached;
        l.root = l.root.translate(34 * attached + walk * .7, 0);
        final ride = l.anchor(BearAnchor.back).translate(-8, 22);
        r.root = Offset.lerp(r.root, ride, attached)!;
        r.body = -.25 * attached;
        r.headX = 8 * attached;
        r.headY = -12 * attached;
        r.head = -.04 * attached;
        r.nearTarget = Offset.lerp(
          r.bodyPoint(r.nearPaw),
          l.anchor(BearAnchor.back).translate(-5, -2),
          attached,
        );
        l.farPaw = Offset(-38, -50 - attached * 14);
        l.step =
            math.sin(seconds * 5.2) * attached * locomotion * 4 * amplitude;
        r.step = l.step * .6;
        r.ear +=
            math.sin(seconds * 5.2 - .4) *
            locomotion *
            attached *
            .03 *
            amplitude;
      case AffectionType.playfulTickle:
        final wiggle =
            math.sin(t * 67) * math.sin(t * 23 + .3) * active * amplitude;
        l.nearTarget = Offset.lerp(
          l.bodyPoint(l.nearPaw),
          r.anchor(BearAnchor.hug).translate(0, wiggle * 4),
          active * .95,
        );
        l.root = l.root.translate(14 * contact, 0);
        r.body = wiggle * .04;
        r.head = -wiggle * .035;
        r.eyes *= 1 - active;
        r.surprise = active * .25;
        r.nearPaw = Offset(30 + 8 * active, -44 - active * 20);
      case AffectionType.sleepTogether:
        final resting = ease(t, .12, .43);
        final closer = taps > 0 ? 4 * ease(input, 0, .7) : 0.0;
        l.sit = resting;
        r.sit = resting;
        l.lie = -.55 * resting;
        r.lie = .55 * resting;
        l.root = l.root.translate(26 * resting + closer, 8 * resting);
        r.root = r.root.translate(-26 * resting - closer, 8 * resting);
        l.headX = -12 * resting;
        r.headX = -12 * resting;
        l.eyes *= 1 - resting;
        r.eyes *= 1 - ease(t, .22, .50);
        frame.blanket = resting;
        frame.dim = resting * .2;
        final join = Offset(200, 245);
        l.nearTarget = Offset.lerp(l.bodyPoint(l.nearPaw), join, resting);
        r.nearTarget = Offset.lerp(r.bodyPoint(r.nearPaw), join, resting);
      case AffectionType.iMissYou:
        r.sit = 1;
        r.smile = -1 + react * 2;
        r.gaze = -3 * (1 - react);
        r.head = -.08 * (1 - react);
        r.ear -= .05 * (1 - react);
        l.sit = approach;
        l.root = l.root.translate(10 * approach, 0);
        final join = const Offset(202, 240);
        l.nearTarget = Offset.lerp(l.bodyPoint(l.nearPaw), join, approach);
        r.nearTarget = Offset.lerp(
          r.bodyPoint(r.nearPaw),
          join,
          ease(t, .46, .63),
        );
      case AffectionType.underOneUmbrella:
        final closer = taps > 0 ? 6 * ease(input, 0, .7) : 0.0;
        l.root = l.root.translate(10 * approach + closer, 0);
        r.root = r.root.translate(-8 * approach - closer, 0);
        l.headX = -10 * approach - closer;
        r.headX = -8 * approach - closer;
        frame.prop = Offset(132 + approach * 68, 100 - approach * 5);
        l.nearTarget = Offset.lerp(
          l.bodyPoint(l.nearPaw),
          frame.prop.translate(0, 118),
          approach,
        );
        r.nearTarget = Offset.lerp(
          r.bodyPoint(r.nearPaw),
          frame.prop.translate(0, 123),
          ease(t, .50, .70),
        );
        frame.reveal = approach;
        frame.spin = math.sin(seconds * 1.3 - .25) * .018 * amplitude;
      case AffectionType.flowerSurprise:
      case AffectionType.heartDelivery:
      case AffectionType.shyConfession:
      case AffectionType.surpriseBox:
        final flower = action == AffectionType.flowerSurprise;
        final shy = action == AffectionType.shyConfession;
        final gift = action == AffectionType.surpriseBox;
        final offer = ease(t, shy ? .45 : .33, shy ? .63 : .53);
        final receive = ease(t, .59, .74);
        l.head =
            -.055 * attention + (shy ? .09 * window(t, .16, .25, .38, .48) : 0);
        l.gaze = shy ? 2 - 5 * window(t, .15, .23, .37, .46) : 2;
        l.root = l.root.translate(8 * approach, 0);
        final stumble = action == AffectionType.heartDelivery
            ? settle(t, .31, .10) * amplitude
            : 0.0;
        l.body = stumble;
        l.head = l.head - stumble * .5;
        l.squash = 1 - stumble.abs() * .2;
        frame.prop = Offset.lerp(
          Offset(flower || shy ? 91 : 165, 224),
          Offset(gift ? 200 : 208 + receive * 30, flower ? 208 : 225),
          offer,
        )!;
        frame.prop = frame.prop.translate(
          0,
          -math.sin(offer * math.pi) * 13 + stumble * 20,
        );
        l.nearTarget = Offset.lerp(
          l.bodyPoint(l.nearPaw),
          frame.prop.translate(-12, 10),
          offer * (1 - receive),
        );
        r.nearTarget = Offset.lerp(
          r.bodyPoint(r.nearPaw),
          frame.prop.translate(9, 10),
          receive,
        );
        r.surprise = window(t, .50, .54, .62, .72);
        r.head = -.06 * receive;
        l.blush += shy ? offer * .35 : 0;
        frame.reveal = flower || shy ? offer : 1;
        if (gift) {
          frame.prop = const Offset(200, 252);
          frame.reveal = math.max(
            ease(t, .58, .68),
            taps > 0 ? ease(input, 0, .65) : 0.0,
          );
          r.body = -.035 * window(t, .40, .53, .63, .77);
          r.root = r.root.translate(
            0,
            -4 * window(t, .66, .69, .73, .79) * amplitude,
          );
          frame.effect = window(t, .65, .69, .74, .84);
        }
        if (flower && taps > 0) {
          frame.effect = pulse;
          frame.bloom = ease(input, 0, .65);
        }
    }
    // Delayed secondary settling, bounded independently of the head shape.
    l.ear += settle(t, .49, .035) * amplitude;
    r.ear += settle(t, .51, .04) * amplitude;
    l.blush = l.blush.clamp(0, 1);
    r.blush = r.blush.clamp(0, 1);
    if (stopped) {
      l.step = 0;
      r.step = 0;
    }
    // Returning affection swaps the acting roles while the colored actors stay
    // on their original sides. This is forward choreography, never reverse time.
    if ((action == AffectionType.cheekKiss && taps.isOdd) ||
        (action == AffectionType.noseBoop && (taps ~/ 3).isOdd)) {
      final reverse = BearFrame(r.mirrored(), l.mirrored())
        ..prop = Offset(400 - frame.prop.dx, frame.prop.dy)
        ..effect = frame.effect
        ..tear = frame.tear;
      return reverse;
    }
    return frame;
  }
}

/// A single source of playback time. Background suspension does not advance
/// the action, holds stop at a contact pose, and completion fires once per run.
class BearPlayback extends ChangeNotifier {
  BearPlayback({
    this.action,
    this.variant = 'gentle',
    this.reduced = false,
    this.onComplete,
    this.onContact,
  });
  AffectionType? action;
  String variant;
  bool reduced, holding = false, stopped = false, completed = false;
  VoidCallback? onComplete, onContact;
  double progress = 0, seconds = 0, input = 1, walk = 0, walkTarget = 0;
  double locomotion = 0;
  int taps = 0;
  bool _contactSent = false;
  BearFrame? _previous;
  double _blend = 1;
  Duration get duration => BearChoreography.duration(action, variant);
  bool get settled =>
      completed && input >= 1 && _blend >= 1 && (walkTarget - walk).abs() < .01;
  BearStage get stage => BearChoreography.stage(progress, holding: holding);
  void showPreview() {
    progress = .54;
    _previous = null;
    _blend = 1;
    input = 1;
    notifyListeners();
  }

  BearFrame get frame {
    final sampled = BearChoreography.sample(
      action: stopped ? null : action,
      t: progress,
      seconds: seconds,
      reduced: reduced,
      taps: taps,
      walk: walk,
      locomotion: locomotion,
      input: input,
      stopped: stopped,
      variant: variant,
    );
    return _previous != null && _blend < 1
        ? BearFrame.blend(
            _previous!,
            sampled,
            Curves.easeInOut.transform(_blend),
          )
        : sampled;
  }

  void configure({
    required AffectionType? nextAction,
    required String nextVariant,
    required bool nextReduced,
    required bool nextHolding,
    required bool nextStopped,
    required int nextTaps,
    required double nextWalk,
  }) {
    final changed = action != nextAction || variant != nextVariant;
    final tapped = nextTaps != taps && !holding && !nextHolding;
    final stopping = nextStopped && !stopped;
    if (changed ||
        tapped ||
        stopping ||
        nextReduced != reduced ||
        nextHolding != holding) {
      _previous = frame;
      _blend = 0;
    }
    action = nextAction;
    variant = nextVariant;
    reduced = nextReduced;
    holding = nextHolding && BearChoreography.canHold(action);
    stopped = nextStopped;
    walkTarget = nextWalk.clamp(-25, 25);
    if (changed) {
      progress = 0;
      completed = false;
      _contactSent = false;
    }
    if (tapped) {
      input = 0;
      if ([
        AffectionType.cheekKiss,
        AffectionType.foreheadKiss,
        AffectionType.noseBoop,
        AffectionType.headPat,
        AffectionType.highFive,
        AffectionType.spinningHug,
        AffectionType.comfortHug,
        AffectionType.happyDance,
        AffectionType.playfulTickle,
      ].contains(action)) {
        progress = .18;
        completed = false;
        _contactSent = false;
      }
    }
    if (holding && completed) {
      progress = .42;
      completed = false;
      _contactSent = false;
    }
    if (stopping) {
      holding = false;
      progress = .80;
      completed = false;
    }
    taps = nextTaps;
    notifyListeners();
  }

  void advance(double delta) {
    if (delta <= 0) return;
    seconds += delta;
    input = (input + delta / .9).clamp(0, 1);
    _blend = (_blend + delta / .28).clamp(0, 1);
    walk += (walkTarget - walk) * (1 - math.exp(-delta * 9));
    locomotion = ((walkTarget - walk).abs() / 5).clamp(0, 1);
    if (action != null && !completed) {
      final limit = holding ? BearChoreography.holdTime : 1.0;
      // Re-enabling hold during recovery blends back to contact without a jump.
      if (holding && progress > limit) {
        _previous = frame;
        _blend = 0;
        progress = limit;
      }
      progress = math.min(
        limit,
        progress + delta / (duration.inMicroseconds / 1e6),
      );
      if (!_contactSent &&
          progress >= BearChoreography.contactTime &&
          !stopped) {
        _contactSent = true;
        onContact?.call();
      }
      if (progress >= 1) {
        completed = true;
        onComplete?.call();
      }
    }
    notifyListeners();
  }
}
