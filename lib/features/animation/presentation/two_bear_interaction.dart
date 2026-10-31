part of 'bear_choreography.dart';

enum BearContactKind { embrace, shoulderRest, paw, forehead, backSupport }

enum BearSceneControl { blanket, lamp, closer, headPat, stayBeside, holdHands }

/// Independent control channels avoid a blanket tap also toggling the lamp.
class BearInteractionInput {
  const BearInteractionInput({
    this.blanket = 0,
    this.lamp = 0,
    this.closer = 0,
    this.pat = 0,
    this.stay = 0,
    this.hands = 0,
  });
  final double blanket, lamp, closer, pat, stay, hands;
  BearInteractionInput advance(Set<BearSceneControl> controls, double delta) {
    double move(double value, BearSceneControl control) {
      final target = controls.contains(control) ? 1.0 : 0.0;
      final next = value + (target - value) * (1 - math.exp(-delta * 7));
      return (target - next).abs() < .001 ? target : next;
    }

    return BearInteractionInput(
      blanket: move(blanket, BearSceneControl.blanket),
      lamp: move(lamp, BearSceneControl.lamp),
      closer: move(closer, BearSceneControl.closer),
      pat: move(pat, BearSceneControl.headPat),
      stay: move(stay, BearSceneControl.stayBeside),
      hands: move(hands, BearSceneControl.holdHands),
    );
  }

  bool settled(Set<BearSceneControl> controls) {
    final target = advance(controls, 100);
    return (blanket - target.blanket).abs() +
            (lamp - target.lamp).abs() +
            (closer - target.closer).abs() +
            (pat - target.pat).abs() +
            (stay - target.stay).abs() +
            (hands - target.hands).abs() <
        .001;
  }
}

class BearContact {
  const BearContact(this.kind, this.from, this.to, this.weight);
  final BearContactKind kind;
  final Offset from, to;
  final double weight;
  double get error => (from - to).distance;
}

/// All targets come from the posed actors, never from viewport coordinates.
/// Targets are applied after breathing, leaning and shared orbit transforms.
abstract final class ContactAlignmentController {
  static void joinBodies(BearPose a, BearPose b, double weight) {
    final gap = b.anchor(BearAnchor.hug) - a.anchor(BearAnchor.hug);
    // Keep the feet/seat planted while closing the horizontal chest gap.
    final correction = Offset(gap.dx * weight / 2, 0);
    a.root += correction;
    b.root -= correction;
  }

  static void restHead(BearPose receiver, BearPose support, double weight) {
    receiver.shiftHead(
      (support.anchor(BearAnchor.headRest) -
              receiver.headPoint(const Offset(63, 8))) *
          weight,
    );
  }

  static void wrap(
    BearFrame frame,
    double weight, {
    bool supporting = false,
    bool restingPaw = false,
  }) {
    final a = frame.left, b = frame.right;
    final aNear = b.bodyPoint(Offset(-8 * b.armTurn, supporting ? -36 : -34));
    // A cuddle rests the recipient's paw on the sender's chest. A hug wraps
    // across to the outer flank. These are different contact drawings/targets.
    final bNear = a.bodyPoint(
      Offset((restingPaw ? 22 : -8) * a.armTurn, restingPaw ? -43 : -49),
    );
    final aFar = b.bodyPoint(Offset(36 * b.armTurn, -67));
    final bFar = a.bodyPoint(Offset(36 * a.armTurn, -66));
    a.nearTarget = Offset.lerp(a.bodyPoint(a.nearPaw), aNear, weight);
    b.nearTarget = Offset.lerp(b.bodyPoint(b.nearPaw), bNear, weight);
    a.farTarget = Offset.lerp(a.bodyPoint(a.farPaw), aFar, weight);
    b.farTarget = Offset.lerp(b.bodyPoint(b.farPaw), bFar, weight);
    frame.contacts.addAll([
      BearContact(
        BearContactKind.embrace,
        a.anchor(BearAnchor.leftPaw),
        aNear,
        weight,
      ),
      BearContact(
        BearContactKind.embrace,
        b.anchor(BearAnchor.leftPaw),
        bNear,
        weight,
      ),
      BearContact(
        BearContactKind.backSupport,
        a.anchor(BearAnchor.rightPaw),
        aFar,
        weight,
      ),
      BearContact(
        BearContactKind.backSupport,
        b.anchor(BearAnchor.rightPaw),
        bFar,
        weight,
      ),
    ]);
  }

  static void joinPaws(BearFrame frame, double weight, {double squeeze = 0}) {
    final a = frame.left, b = frame.right;
    final join =
        (a.anchor(BearAnchor.shoulder) + b.anchor(BearAnchor.shoulder)) / 2 +
        Offset(0, 15 + squeeze * 3);
    a.nearTarget = Offset.lerp(a.bodyPoint(a.nearPaw), join, weight);
    b.nearTarget = Offset.lerp(b.bodyPoint(b.nearPaw), join, weight);
    frame.contacts.add(
      BearContact(
        BearContactKind.paw,
        a.anchor(BearAnchor.leftPaw),
        b.anchor(BearAnchor.leftPaw),
        weight,
      ),
    );
  }
}

/// Shared two-actor pose solver used by the existing BearPlayback clock.
/// Warm, reassuring, playful and resting scenes have separate authored tracks.
abstract final class TwoBearInteractionController {
  static void pose(
    BearFrame frame,
    AffectionType action, {
    required double t,
    required double seconds,
    required bool reduced,
    required String variant,
    required int taps,
    required double input,
    required BearInteractionInput interaction,
    BearSecondaryMotion? secondary,
    double intensity = 1,
  }) {
    final a = frame.left, b = frame.right;
    final motion = reduced ? 0.0 : intensity;
    final comfort = action == AffectionType.comfortHug;
    final cuddle = action == AffectionType.cuddleTime;
    final spin = action == AffectionType.spinningHug;
    final seated = comfort || cuddle;
    final approach = BearChoreography.ease(t, comfort ? .18 : .22, .43);
    final release =
        1 - BearChoreography.ease(t, .80, .98) * (1 - interaction.stay);
    // Reach first, then settle the heads into the embrace.
    final reach = BearChoreography.ease(t, .25, .46) * release;
    final settle = BearChoreography.ease(t, .48, comfort ? .64 : .57);
    final welcome = BearChoreography.window(t, .13, .25, .30, .45);
    final rest = BearChoreography.ease(t, .43, .61) * release;

    if (action == AffectionType.sleepTogether) {
      BearPoseLibrary.apply(a, BearInteractionPose.lyingDown);
      BearPoseLibrary.apply(b, BearInteractionPose.sleepingTogether);
      a.eyes *= 1 - BearChoreography.ease(t, .14, .36);
      b.eyes *= 1 - BearChoreography.ease(t, .23, .50);
      // Each head rests on its own pillow, tilted gently toward the other.
      a.head = .10 + .035 * BearChoreography.ease(t, .16, .33);
      b.head = .08 + .035 * BearChoreography.ease(t, .24, .43);
      a.headY = 20;
      b.headY = 24;
      final closer = math.max(
        interaction.closer,
        taps > 0 ? BearChoreography.ease(input, 0, .7) : 0.0,
      );
      a.root = a.root.translate(4 + 4 * closer, 0);
      b.root = b.root.translate(-4 - 4 * closer, 0);
      // An adjustment moves the torso/feet under the resting head, not the pillow.
      final adjust = math.sin(BearChoreography.ease(t, .12, .32) * math.pi);
      a.embrace = adjust * .12;
      a.farPaw = const Offset(-30, -27);
      b.farPaw = const Offset(-32, -26);
      ContactAlignmentController.joinPaws(
        frame,
        BearChoreography.ease(t, .28, .50),
        squeeze: interaction.hands,
      );
      frame.blanket = .72 + .28 * BearChoreography.ease(t, .08, .30);
      frame.dim = .18 * BearChoreography.ease(t, .35, .68);
      frame.dim += interaction.lamp * .12;
      return;
    }

    if (action == AffectionType.goodnightKiss) {
      BearPoseLibrary.apply(b, BearInteractionPose.lyingDown);
      final sleepy = BearChoreography.ease(t, .06, .30);
      b.head = .08 + .04 * sleepy;
      b.headY = 24;
      b.eyes *= 1 - sleepy;
      b.mouthOpen = BearChoreography.window(t, .07, .13, .20, .29) * .6;
      final kiss = BearChoreography.window(t, .34, .46, .56, .74);
      a.turn = kiss;
      a.head = -.13 * kiss;
      a.headY = -10 * kiss;
      final target = b.anchor(BearAnchor.forehead);
      final delta = target - a.anchor(BearAnchor.nose);
      a.root += Offset(delta.dx * kiss, 0);
      a.shiftHead(Offset(0, delta.dy * kiss));
      a.eyes *= 1 - kiss;
      a.pucker = kiss;
      a.sit = BearChoreography.ease(t, .77, .97);
      a.nearTarget = Offset.lerp(
        a.bodyPoint(a.nearPaw),
        b.headPoint(const Offset(63, 3)),
        BearChoreography.window(t, .58, .67, .72, .83),
      );
      frame.contacts.add(
        BearContact(
          BearContactKind.forehead,
          a.anchor(BearAnchor.nose),
          target,
          kiss,
        ),
      );
      frame.blanket = .65 + .35 * BearChoreography.ease(t, .13, .34);
      frame.dim =
          BearChoreography.ease(t, .78, .98) * .32 + (taps.isOdd ? .12 : 0);
      frame.effect = BearChoreography.window(t, .47, .52, .61, .72);
      frame.prop = target.translate(0, -25);
      return;
    }

    if (seated) {
      // A comforting scene starts with the recipient already seated; cuddling
      // starts with both seated. Separate bent legs support each seated torso.
      b.sit = 1;
      a.sit = cuddle ? 1 : BearChoreography.ease(t, .27, .43);
      a.gaitWeight = comfort ? a.gaitWeight * (1 - a.sit) : 0;
      b.gaitWeight = 0;
    }
    final ground = cuddle
        ? 263.0
        : comfort
        ? 271.0
        : 278.0;
    a.root = Offset(a.root.dx - 6 + 40 * approach * release, ground);
    b.root = Offset(b.root.dx + 6 - 40 * approach * release, ground);
    a.embrace = b.embrace = reach;
    // Corrective shoulder drawings place the front wraps below the large
    // heads. Staggered arm heights read as an embrace rather than a neck band.
    a.shoulderDrop = 20;
    b.shoulderDrop = 34;
    a.headX = -24 * approach * release;
    b.headX = -24 * approach * release;
    // Lift the sender's chin to expose the shoulder and stagger the heads.
    // The recipient nestles in after the arms have made contact.
    a.headY = -16 * reach;
    b.headY = 3 * rest;
    a.head = .075 * rest;
    b.head = .12 * rest;
    a.body = .018 * reach;
    b.body = -.018 * reach;
    a.farPaw = Offset(-28 - 18 * welcome, -40 - 15 * welcome);
    b.farPaw = Offset(-28 - 14 * welcome, -40 - 11 * welcome);
    a.nearPaw = Offset(27 + 15 * welcome, -39 - 13 * welcome);
    b.nearPaw = Offset(27 + 13 * welcome, -39 - 11 * welcome);
    // Torso-only compression: the neck transform cancels scale on each head.
    final squeeze = BearChoreography.window(t, .45, .49, .54, .61);
    a.squash = 1 - .018 * squeeze * motion;
    b.squash = 1 - .015 * squeeze * motion;
    a.squash -= (secondary?.left.compression.position ?? 0) * intensity;
    b.squash -= (secondary?.right.compression.position ?? 0) * intensity;
    final sway =
        math.sin(seconds * (comfort ? .85 : 1.25)) * .006 * rest * motion;
    a.body += sway;
    b.body += sway;
    a.eyes *= 1 - settle * release;
    b.eyes *= 1 - BearChoreography.ease(t, .50, .62) * release;
    a.happyEyes = b.happyEyes = comfort ? .18 : .55;
    a.blush = .18 + rest * .35;
    b.blush = .25 + rest * .55;

    if (comfort) {
      b.smile = -1 + 2 * BearChoreography.ease(t, .47, .73);
      b.headY += 7 * (1 - settle);
      b.ear -= .04 * (1 - settle);
      b.gaze = -2 + 4 * BearChoreography.ease(t, .23, .36);
      a.head = .06 * rest;
    }
    if (seated) {
      b.head = .14 * rest;
      // Cuddles remain seated on release; a comforting partner stays beside you.
      frame.blanket = cuddle ? .34 + .66 * interaction.blanket : 0;
      frame.dim = interaction.lamp * .25;
      b.blush += interaction.closer * .08;
    }

    if (cuddle) {
      a.squash = b.squash = 1 - interaction.closer * .008;
      a.head += interaction.closer * .025 * rest;
      b.head += interaction.closer * .025 * rest;
    }
    ContactAlignmentController.joinBodies(a, b, reach);
    if (seated) {
      ContactAlignmentController.restHead(b, a, rest);
      frame.contacts.add(
        BearContact(
          BearContactKind.shoulderRest,
          b.headPoint(const Offset(63, 8)),
          a.anchor(BearAnchor.headRest),
          rest,
        ),
      );
    }
    if (spin) {
      // One parent orbit with ease-out deceleration. Depth controls the draw
      // order and a rear facial layer, rather than rotating flattened faces.
      frame.spin =
          math.pi *
          2 *
          BearChoreography.ease(t, .51, .77, Curves.easeInOutSine) *
          motion;
      final center = (a.root + b.root) / 2;
      final projection = math.cos(frame.spin), depth = math.sin(frame.spin);
      final turnCompression = 1 - .08 * (1 - projection) / 2;
      for (final p in [a, b]) {
        final side = identical(p, a) ? -1.0 : 1.0;
        p.root = Offset(
          center.dx + (p.root.dx - center.dx) * projection * turnCompression,
          278 + side * depth * 4,
        );
        p.headX *= projection;
        p.armTurn = projection;
        p.backView = (side * depth).clamp(0.0, 1.0);
        p.ear += side * depth * .035;
      }
    }
    ContactAlignmentController.wrap(
      frame,
      reach,
      supporting: seated,
      restingPaw: cuddle,
    );
    if (comfort && interaction.pat > 0) {
      final pat = b.headPoint(
        Offset(63, 12 + math.sin(seconds * 2.4) * 1.5 * motion),
      );
      a.nearTarget = Offset.lerp(a.nearTarget, pat, interaction.pat);
    }
    if (variant == 'playful' && !seated && !reduced) {
      a.ear += BearChoreography.settle(t, .49, .045);
      b.ear += BearChoreography.settle(t, .52, .035);
    }
    if (variant == 'shy') {
      b.blush = (b.blush + rest * .15).clamp(0, 1);
      b.gaze -= 2 * welcome;
    }
    frame.effect = BearChoreography.window(t, .88, .93, .96, 1) * .35;
    frame.prop =
        (a.anchor(BearAnchor.headCenter) + b.anchor(BearAnchor.headCenter)) /
            2 -
        const Offset(0, 54);
  }
}
