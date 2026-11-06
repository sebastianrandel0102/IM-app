import 'dart:math' as math;

import 'package:flutter/animation.dart';
import 'package:flutter/foundation.dart';

import '../../affection/domain/affection_type.dart';
import '../domain/gesture_definition.dart';
import 'bear_motion.dart';
import 'bear_physics.dart';

part 'two_bear_interaction.dart';
part 'bear_pose_library.dart';

enum BearStage {
  idle,
  attention,
  anticipation,
  approach,
  contactPreparation,
  contact,
  reaction,
  hold,
  release,
  recovery,
  complete,
  cancelled,
}

enum BearAnchor {
  headCenter,
  leftCheek,
  rightCheek,
  cheek,
  forehead,
  nose,
  leftPaw,
  rightPaw,
  shoulder,
  rightShoulder,
  torso,
  hug,
  seat,
  back,
  headRest,
  leftFoot,
  rightFoot,
  headTop,
  leftEar,
  rightEar,
  chest,
  belly,
  muzzle,
  armNear,
  armFar,
}

/// The vector rig's coordinates, also used by contact constraints and QA.
/// Head transforms are rigid; squash is confined to the torso. Arms use a
/// two-link solve with a bounded reach instead of stretching the artwork.
class BearPose {
  Offset root = const Offset(132, 278);
  double facing = 1, body = 0, head = 0, headX = 0, headY = 0;
  double squash = 1, sit = 0, lie = 0, step = 0;
  // Replacement silhouettes, independent of whole-character rotation.
  double recline = 0, embrace = 0, backView = 0, armTurn = 1;
  double shoulderDrop = 36;
  double shoulderLift = 0, leftEarBend = 0, rightEarBend = 0;
  double eyes = 1, gaze = 0, smile = 1, blush = .15, surprise = 0;
  double ear = 0, breath = 0, cheek = 0, turn = 0;
  double mouthOpen = 0, pucker = 0, happyEyes = 0;
  double gaitPhase = 0, gaitWeight = 0;
  double gaitDirection = 1;
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
    // Neck pivot at the base of the head, shared with the drawing transform.
    final y = p.dy - 50;
    final local = Offset(
      (p.dx * math.cos(head) - y * math.sin(head)) * facing,
      50 + p.dx * math.sin(head) + y * math.cos(head),
    );
    final a = body + lie;
    return origin +
        Offset(
          local.dx * math.cos(a) - local.dy * math.sin(a),
          local.dx * math.sin(a) + local.dy * math.cos(a),
        );
  }

  Offset anchor(BearAnchor a) => switch (a) {
    BearAnchor.headCenter => headPoint(Offset.zero),
    BearAnchor.leftCheek => headPoint(
      Offset((9 + turn * 43 - 31).clamp(-42, 48), 28),
    ),
    BearAnchor.rightCheek => headPoint(
      Offset((9 + turn * 43 + 31).clamp(-42, 48), 28),
    ),
    BearAnchor.cheek => headPoint(const Offset(60, 24)),
    BearAnchor.forehead => headPoint(const Offset(35, -45)),
    BearAnchor.nose => headPoint(Offset(9 + turn * 43, 25)),
    BearAnchor.leftPaw => nearTarget ?? bodyPoint(nearPaw),
    BearAnchor.rightPaw => farTarget ?? bodyPoint(farPaw),
    BearAnchor.shoulder => bodyPoint(
      Offset(
        23 * armTurn,
        -80 + recline * 38 + embrace * shoulderDrop + shoulderLift,
      ),
    ),
    BearAnchor.rightShoulder => bodyPoint(
      Offset(-23 * armTurn, -80 + recline * 38 + embrace * 12),
    ),
    BearAnchor.torso => bodyPoint(const Offset(0, -54)),
    BearAnchor.hug => bodyPoint(Offset(28 + embrace * 6, -59)),
    BearAnchor.seat => bodyPoint(const Offset(0, -18)),
    BearAnchor.back => bodyPoint(const Offset(-22, -85)),
    BearAnchor.headRest => headPoint(const Offset(63, 24)),
    BearAnchor.leftFoot => bodyPoint(footPoint(-1)),
    BearAnchor.rightFoot => bodyPoint(footPoint(1)),
    BearAnchor.headTop => headPoint(const Offset(0, -57)),
    BearAnchor.leftEar => earPoint(true),
    BearAnchor.rightEar => earPoint(false),
    BearAnchor.chest => bodyPoint(const Offset(0, -65)),
    BearAnchor.belly => bodyPoint(const Offset(0, -40)),
    BearAnchor.muzzle => headPoint(Offset(9 + turn * 43, 31)),
    BearAnchor.armNear => anchor(BearAnchor.shoulder),
    BearAnchor.armFar => anchor(BearAnchor.rightShoulder),
  };

  Offset earPoint(bool left) {
    final angle = (left ? -ear : ear) + (left ? leftEarBend : rightEarBend);
    return headPoint(
      Offset(
        (left ? -36.5 : 42.5) + 29 * math.sin(angle),
        -20 - 29 * math.cos(angle),
      ),
    );
  }

  Offset footPoint(int side) => Offset(
    side * (16 + sit * 7) * (1 - recline) +
        (-57 + side * 13) * recline +
        .5 +
        sit * 5 +
        recline * 4,
    -1 - sit * 7 - recline * 12,
  );

  void shiftHead(Offset sceneDelta) {
    final angle = body + lie;
    headX +=
        (sceneDelta.dx * math.cos(angle) + sceneDelta.dy * math.sin(angle)) *
        squash /
        facing;
    headY +=
        (-sceneDelta.dx * math.sin(angle) + sceneDelta.dy * math.cos(angle)) /
        squash;
  }

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
      ..recline = mix(a.recline, b.recline)
      ..embrace = mix(a.embrace, b.embrace)
      ..backView = mix(a.backView, b.backView)
      ..armTurn = mix(a.armTurn, b.armTurn)
      ..shoulderDrop = mix(a.shoulderDrop, b.shoulderDrop)
      ..shoulderLift = mix(a.shoulderLift, b.shoulderLift)
      ..leftEarBend = mix(a.leftEarBend, b.leftEarBend)
      ..rightEarBend = mix(a.rightEarBend, b.rightEarBend)
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
      ..mouthOpen = mix(a.mouthOpen, b.mouthOpen)
      ..pucker = mix(a.pucker, b.pucker)
      ..happyEyes = mix(a.happyEyes, b.happyEyes)
      ..gaitPhase = mix(a.gaitPhase, b.gaitPhase)
      ..gaitWeight = mix(a.gaitWeight, b.gaitWeight)
      ..gaitDirection = mix(a.gaitDirection, b.gaitDirection)
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
  // Constraints describe actual scene-space contacts, also consumed by debug QA.
  final List<BearContact> contacts = [];
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
  static bool canHold(AffectionType? a) =>
      a != null && BearGestureDefinition.of(a).supportsHold;
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
      : t < .46
      ? BearStage.contactPreparation
      : t < .52
      ? BearStage.contact
      : t < .68
      ? BearStage.reaction
      : t < .78
      ? BearStage.hold
      : t < .90
      ? BearStage.release
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

  static double blink(double seconds, double offset) =>
      BearMotion.blink(seconds, offset);

  static BearFrame sample({
    AffectionType? action,
    required double t,
    double seconds = 0,
    bool reduced = false,
    int taps = 0,
    double walk = 0,
    double locomotion = 0,
    double stride = 0,
    double travelDirection = 1,
    double input = 0,
    bool stopped = false,
    String variant = 'gentle',
    BearInteractionInput interaction = const BearInteractionInput(),
    BearSecondaryMotion? secondary,
    double intensity = 1,
  }) {
    if (action == AffectionType.wipeAwayTears && taps > 0 && t < .65) {
      t = math.max(t, .43 + .22 * ease(input, 0, .7));
    }
    final l = BearPose(),
        r = BearPose()
          ..root = const Offset(268, 278)
          ..facing = -1;
    final frame = BearFrame(l, r);
    final amplitude = reduced ? 0.0 : intensity;
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
      l.breath = math.sin(seconds * 1.65) * .65 * intensity;
      r.breath = math.sin(seconds * 1.49 + .9) * .65 * intensity;
      l.eyes = blink(seconds, 0);
      r.eyes = blink(seconds, 1.9);
      l.ear = math.sin(seconds * 1.65 - .3) * .012 * intensity;
      r.ear = math.sin(seconds * 1.49 + .5) * .012 * intensity;
    }
    if (secondary != null && !reduced && !stopped) {
      for (final (p, dynamics) in [(l, secondary.left), (r, secondary.right)]) {
        p.ear += dynamics.ear.position * intensity;
        if (action == null) {
          p.head += dynamics.head.position * intensity;
          p.body += dynamics.lean.position * intensity;
          p.squash -= dynamics.compression.position * intensity;
          p.root = p.root.translate(
            0,
            -dynamics.lift.position.clamp(0, 10) * intensity,
          );
          p.nearPaw = p.nearPaw.translate(0, dynamics.paw.position * intensity);
        }
      }
    }
    if (secondary != null) {
      for (final (p, dynamics) in [(l, secondary.left), (r, secondary.right)]) {
        final love = dynamics.affection;
        if (love > 0 || dynamics.holdingPaw) {
          p.blush += love * .35;
          p.gaze = dynamics.reaction == BearReaction.curious ? -2 * love : 0;
          if ([
            BearReaction.pet,
            BearReaction.belly,
            BearReaction.relax,
            BearReaction.pawHold,
            BearReaction.sleepy,
          ].contains(dynamics.reaction)) {
            p.eyes *= 1 - love * .9;
            p.happyEyes = .7;
          }
          if (dynamics.reaction == BearReaction.boop) p.surprise = love;
          if (action == null && dynamics.reaction == BearReaction.wave) {
            p.nearPaw = Offset.lerp(p.nearPaw, const Offset(65, -78), love)!;
          }
          if (action == null &&
              dynamics.holdingPaw &&
              dynamics.heldPaw != null) {
            if (dynamics.heldNear) {
              p.nearTarget = dynamics.heldPaw;
            } else {
              p.farTarget = dynamics.heldPaw;
            }
          }
          if (action == null) {
            frame.effect = love * .5;
            frame.prop = p.headPoint(const Offset(0, -75));
          }
        }
      }
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
    l.gaitPhase = ease(t, .22, .43) * math.pi * 4;
    l.gaitWeight =
        window(t, .22, .26, .39, .43) * amplitude * (walksIn ? 1 : 0);
    l.root = l.root.translate(0, -steps.abs() * 1.5);
    l.farPaw = l.farPaw.translate(steps * 2, 0);

    switch (action) {
      case AffectionType.warmHug:
      case AffectionType.comfortHug:
      case AffectionType.cuddleTime:
      case AffectionType.spinningHug:
      case AffectionType.sleepTogether:
      case AffectionType.goodnightKiss:
        TwoBearInteractionController.pose(
          frame,
          action,
          t: t,
          seconds: seconds,
          reduced: reduced,
          variant: variant,
          taps: taps,
          input: input,
          interaction: interaction,
          secondary: reduced ? null : secondary,
          intensity: intensity,
        );
      case AffectionType.cheekKiss:
      case AffectionType.foreheadKiss:
        final forehead = action != AffectionType.cheekKiss;
        final kiss = window(t, .34, .46, .56, .74);
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
        l.pucker = kiss;
        r.eyes *= 1 - (forehead ? kiss : react * release);
        r.surprise = forehead ? 0 : window(t, .46, .49, .52, .59);
        r.cheek = kiss * .07;
        r.nearPaw = Offset(27 + react * 8, -39 - react * 25);
        r.farPaw = Offset(-28, -40 - (forehead ? 8 : 22) * react * release);
        r.happyEyes = forehead ? .3 * react : .7 * react;
        frame.prop = target.translate(0, -28);
        frame.effect = window(t, .47, .52, .63, .78);
      case AffectionType.holdingHands:
      case AffectionType.highFive:
        final high = action == AffectionType.highFive;
        final reach = high
            ? window(t, .22, .46, .57, .83)
            : ease(t, .22, .46, const Cubic(.35, 0, .25, 1));
        final target = Offset(200, high ? 166 : 225);
        final prepare = high ? window(t, .12, .23, .27, .42) : 0.0;
        final arc = high ? math.sin(reach * math.pi) * 9 : 0.0;
        l.nearTarget = Offset.lerp(
          l.bodyPoint(l.nearPaw.translate(-9 * prepare, -12 * prepare)),
          target,
          reach,
        )!.translate(0, -arc);
        r.nearTarget = Offset.lerp(
          r.bodyPoint(r.nearPaw.translate(-9 * prepare, -12 * prepare)),
          target,
          reach,
        )!.translate(0, -arc);
        l.squash = 1 - impact * .025;
        r.squash = 1 - impact * .025;
        if (high) {
          // Keep joined paws visible between the rigid, oversized heads.
          l.headX = r.headX = -18 * reach;
          l.head = -.06 * active;
          r.head = -.08 * active;
          frame.prop = target;
          frame.effect = window(t, .46, .48, .52, .61);
          l.ear -= impact * .025;
          r.ear += impact * .03;
        } else {
          final walking =
              amplitude * math.sin(seconds * 7) * locomotion * reach;
          l.step = walking * 3;
          r.step = -walking * 3;
          l.root = l.root.translate(walk, -walking.abs());
          r.root = r.root.translate(walk, -walking.abs());
          l.nearTarget = l.nearTarget!.translate(walk, -walking.abs());
          r.nearTarget = r.nearTarget!.translate(walk, -walking.abs());
          l.gaitPhase = stride;
          r.gaitPhase = stride;
          l.gaitWeight = locomotion * reach * amplitude;
          r.gaitWeight = l.gaitWeight;
          l.gaitDirection = travelDirection * l.facing;
          r.gaitDirection = travelDirection * r.facing;
          l.farPaw = l.farPaw.translate(-locomotion * walking * 2, 0);
          r.farPaw = r.farPaw.translate(locomotion * walking * 2, 0);
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
        r.mouthOpen = r.surprise * .7;
        r.happyEyes = pat
            ? .9 * active
            : wipe
            ? .2 * react
            : .5 * react;
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
        l.pucker = lift;
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
        r.gaze = ((frame.prop.dx - r.root.dx) / -34).clamp(-2.5, 2.5);
        r.head = -.05 * react;
        r.eyes *=
            1 -
            math.max(
              window(t, .65, .69, .73, .78),
              taps > 0 ? window(input, .1, .2, .5, .7) : 0.0,
            );
        r.nearPaw = Offset(27 + react * 12, -39 - react * 31);
        r.blush += window(t, .65, .72, .84, .95) * .2;
      case AffectionType.goodMorning:
        final wake = math.max(
          ease(t, .43, .68),
          taps > 0 ? ease(input, .05, .65) : 0.0,
        );
        r.sit = .45 * (1 - wake);
        r.recline = 1 - wake;
        r.eyes *= wake;
        r.headY = 27 * (1 - wake);
        r.nearPaw = Offset(27 + 37 * active, -39 - 46 * active);
        r.farPaw = Offset(-28 - 36 * active, -40 - 45 * active);
        r.squash = 1 + .025 * active;
        r.smile = wake;
        r.mouthOpen = window(t, .46, .53, .60, .70) * .75;
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
          p.happyEyes = active;
          p.eyes *= 1 - active * .78;
          p.mouthOpen = active * .45;
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
        l.gaitPhase = stride;
        l.gaitWeight = attached * locomotion * amplitude;
        l.gaitDirection = travelDirection * l.facing;
        r.gaitWeight = 0;
        r.sit = attached * .6;
        r.farTarget = Offset.lerp(
          r.bodyPoint(r.farPaw),
          l.anchor(BearAnchor.back).translate(-18, 10),
          attached,
        );
        r.breath *= .6;
        r.head += settle(t, .52, .025) * amplitude;
        r.ear +=
            math.sin(seconds * 5.2 - .4) *
            locomotion *
            attached *
            .03 *
            amplitude;
      case AffectionType.playfulTickle:
        final wiggle =
            math.sin(t * 67) * math.sin(t * 23 + .3) * active * amplitude;
        l.root = l.root.translate(30 * contact, 0);
        l.headX = -24 * contact;
        l.nearTarget = Offset.lerp(
          l.bodyPoint(l.nearPaw),
          r.anchor(BearAnchor.hug).translate(0, wiggle * 4),
          active,
        );
        r.body = wiggle * .04;
        r.head = -wiggle * .035;
        r.eyes *= 1 - active;
        r.surprise = active * .25;
        r.mouthOpen = active * .85;
        r.happyEyes = active;
        r.nearPaw = Offset(30 + 8 * active, -44 - active * 20);
      case AffectionType.iMissYou:
        r.sit = 1;
        r.smile = -1 + react * 2;
        final notice = ease(t, .32, .46);
        r.gaze = -3 + 5 * notice;
        r.head = -.08 * (1 - react);
        r.headY = 4 * (1 - react);
        r.ear -= .05 * (1 - react);
        r.happyEyes = .35 * react;
        l.head = .035 * approach;
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
        l.farPaw = const Offset(-31, -44);
        r.happyEyes = .25 * react;
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
        r.mouthOpen = r.surprise * .65;
        r.head = -.06 * receive;
        l.blush += shy ? offer * .35 : 0;
        if (shy) {
          l.farPaw = Offset(-28, -40 - window(t, .18, .28, .39, .49) * 23);
          r.gaze = 2 - 3 * window(t, .61, .69, .76, .85);
        }
        if (flower) {
          l.head = -.08 * offer;
          r.happyEyes = .65 * receive;
        }
        if (action == AffectionType.heartDelivery) {
          r.body = -.025 * receive;
          r.farPaw = Offset(-28, -40 - receive * 10);
        }
        frame.reveal = flower || shy ? offer : 1;
        if (gift) {
          final shake =
              math.sin(t * 135) *
              window(t, .43, .48, .54, .58) *
              1.2 *
              amplitude;
          frame.prop = Offset(200 + shake, 252);
          frame.reveal = math.max(
            ease(t, .58, .68),
            taps > 0 ? ease(input, 0, .65) : 0.0,
          );
          r.body = -.035 * window(t, .40, .53, .63, .77);
          r.farPaw = Offset(-28 - r.surprise * 6, -40 - r.surprise * 21);
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
    if (action == AffectionType.sleepTogether && secondary != null) {
      for (final (p, dynamics) in [(l, secondary.left), (r, secondary.right)]) {
        if (dynamics.reaction == BearReaction.sleepy) {
          p.eyes = math.max(p.eyes, dynamics.affection * .3);
          if (!reduced) p.head += dynamics.head.position * intensity;
        }
      }
    }
    // Delayed secondary settling, bounded independently of the head shape.
    l.ear += settle(t, .49, .035) * amplitude;
    r.ear += settle(t, .51, .04) * amplitude;
    l.blush = l.blush.clamp(0, 1);
    r.blush = r.blush.clamp(0, 1);
    // Expression tracks remain independent of blinks and torso deformation.
    // Calm gestures retain tiny mouths; surprise/laughter use local artwork.
    r.mouthOpen = math.max(r.mouthOpen, r.surprise * .55);
    if (stopped) {
      l.step = 0;
      r.step = 0;
    }
    // Returning affection swaps the acting roles while the colored actors stay
    // on their original sides. This is forward choreography, never reverse time.
    if (([
              AffectionType.cheekKiss,
              AffectionType.foreheadKiss,
            ].contains(action) &&
            taps.isOdd) ||
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
    this.onEvent,
  });
  AffectionType? action;
  String variant;
  bool reduced, holding = false, stopped = false, completed = false;
  VoidCallback? onComplete, onContact;
  ValueChanged<BearAnimationEvent>? onEvent;
  double progress = 0, seconds = 0, input = 1, walk = 0, walkTarget = 0;
  double locomotion = 0;
  double stride = 0;
  double travelDirection = 1;
  Set<BearSceneControl> controls = const {};
  BearInteractionInput interaction = const BearInteractionInput();
  final secondary = BearSecondaryMotion();
  double intensity = 1;
  int taps = 0;
  bool _contactSent = false;
  int _seenTaps = 0;
  final Set<BearAnimationEvent> _events = {};
  bool _inHold = false;
  BearFrame? _previous;
  double _blend = 1;
  Duration get duration => BearChoreography.duration(action, variant);
  bool get settled =>
      completed &&
      input >= 1 &&
      _blend >= 1 &&
      (walkTarget - walk).abs() < .01 &&
      interaction.settled(controls) &&
      secondary.settled;
  BearStage get stage => stopped
      ? BearStage.cancelled
      : BearChoreography.stage(progress, holding: holding);
  BearGestureDefinition? get definition =>
      action == null ? null : BearGestureDefinition.of(action!);
  bool get canReact {
    final d = definition;
    if (d == null || holding || stopped || progress < d.inputAt) return false;
    if (action == AffectionType.highFive) {
      return progress <= .57 || progress >= .78;
    }
    return d.touch != BearTouch.hold;
  }

  void _event(BearAnimationEvent event) {
    if (_events.add(event)) onEvent?.call(event);
  }

  void _resetEvents() {
    _events.clear();
    _contactSent = false;
  }

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
      stride: stride,
      travelDirection: travelDirection,
      input: input,
      stopped: stopped,
      variant: variant,
      interaction: interaction,
      secondary: secondary,
      intensity: intensity,
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
    Set<BearSceneControl> nextControls = const {},
    double nextIntensity = 1,
  }) {
    final changed = action != nextAction || variant != nextVariant;
    // Consume rejected edges as well, so an early tap cannot fire later when
    // a parent rebuild happens to occur inside the action window.
    final tapped =
        !changed && nextTaps != _seenTaps && canReact && !nextHolding;
    _seenTaps = nextTaps;
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
    intensity = nextIntensity.clamp(0, 1);
    if (reduced || stopping) secondary.reset();
    holding = nextHolding && BearChoreography.canHold(action);
    stopped = nextStopped;
    // Scene controls become available once the authored contact is established.
    if (!stopped && progress >= (definition?.contactAt ?? 1)) {
      controls = Set.unmodifiable(nextControls);
    }
    if (definition?.touch == BearTouch.walk && canReact) {
      walkTarget = nextWalk.clamp(-25, 25);
    }
    if (changed) {
      progress = 0;
      completed = false;
      taps = 0;
      seconds = 0;
      stride = 0;
      input = 1;
      walk = walkTarget = locomotion = 0;
      _inHold = false;
      controls = const {};
      interaction = const BearInteractionInput();
      secondary.reset();
      _resetEvents();
    }
    if (tapped) {
      input = 0;
      taps++;
      final repeat = definition?.repeatFrom;
      if (repeat != null) {
        progress = action == AffectionType.highFive && progress < .57
            ? math.max(progress, .37)
            : repeat;
        completed = false;
        _resetEvents();
      }
    }
    if (holding && completed) {
      progress = .42;
      completed = false;
      _resetEvents();
    }
    if (stopping) {
      _event(BearAnimationEvent.cancelled);
      holding = false;
      progress = .80;
      completed = false;
    }
    if (_inHold && !holding) {
      _inHold = false;
      // Hold start/end are edges and may occur more than once within a run.
      onEvent?.call(BearAnimationEvent.interactiveHoldEnded);
    }
    notifyListeners();
  }

  void advance(double delta) {
    if (!delta.isFinite || delta <= 0) return;
    seconds += delta;
    interaction = interaction.advance(controls, delta);
    input = (input + delta / .9).clamp(0, 1);
    _blend = (_blend + delta / .28).clamp(0, 1);
    final oldWalk = walk;
    // Walking is accepted after attachment; early drags do not move either
    // bear out from under the approach/contact choreography.
    if (progress >= (definition?.inputAt ?? 0)) {
      walk += (walkTarget - walk) * (1 - math.exp(-delta * 9));
    }
    final distance = walk - oldWalk;
    if (distance.abs() > .0001) travelDirection = distance.sign;
    stride += distance.abs() / BearMotion.strideLength * math.pi * 2;
    locomotion = ((walkTarget - walk).abs() / 5).clamp(0, 1);
    if (action != null && !completed) {
      _event(BearAnimationEvent.started);
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
      if (progress >= .43 && !stopped) {
        _event(BearAnimationEvent.approachComplete);
      }
      if (!_contactSent && progress >= definition!.contactAt && !stopped) {
        _contactSent = true;
        _event(BearAnimationEvent.contactStarted);
        onContact?.call();
        if (!reduced) {
          final strength =
              action?.category == 'Comfort' || action?.category == 'Cozy'
              ? .06
              : .12;
          secondary.left.ear.velocity += strength;
          secondary.right.ear.velocity -= strength * .8;
          secondary.left.compression.velocity += strength;
          secondary.right.compression.velocity += strength * .8;
          secondary.blanket.velocity += strength * 8;
          secondary.prop.velocity += strength * 6;
        }
      }
      if (progress >= definition!.reactionAt && !stopped) {
        _event(BearAnimationEvent.reactionStarted);
      }
      if (holding && progress >= limit && !_inHold) {
        _inHold = true;
        onEvent?.call(BearAnimationEvent.interactiveHoldStarted);
      }
      if (progress >= 1) {
        completed = true;
        _event(BearAnimationEvent.completed);
        onComplete?.call();
      }
    }
    if (!stopped &&
        (!reduced ||
            secondary.left.reaction != null ||
            secondary.right.reaction != null)) {
      final authored = BearChoreography.sample(
        action: action,
        t: progress,
        seconds: seconds,
      );
      secondary.advance(
        delta,
        leftHead: reduced ? 0 : authored.left.head,
        rightHead: reduced ? 0 : authored.right.head,
      );
    }
    notifyListeners();
  }

  void react(bool left, BearReaction reaction) {
    if (stopped) return;
    (left ? secondary.left : secondary.right).react(reaction);
    notifyListeners();
  }

  void releaseTouch() {
    if (secondary.left.holdingPaw || secondary.right.holdingPaw) {
      _previous = frame;
      _blend = 0;
    }
    secondary.left.holdingPaw = secondary.right.holdingPaw = false;
    secondary.left.heldPaw = secondary.right.heldPaw = null;
  }

  void holdPaw(bool left, {bool near = true}) {
    final actor = left ? frame.left : frame.right;
    final point = actor.anchor(near ? BearAnchor.leftPaw : BearAnchor.rightPaw);
    react(left, BearReaction.pawHold);
    final dynamics = left ? secondary.left : secondary.right;
    dynamics.heldPaw = point;
    dynamics.heldNear = near;
  }
}
