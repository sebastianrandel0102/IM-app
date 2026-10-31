import 'dart:math' as math;
import 'dart:ui';

enum BearReaction {
  curious,
  pet,
  boop,
  shy,
  belly,
  wave,
  pawHold,
  relax,
  jump,
  sleepy,
}

/// Semi-implicit Euler, always integrated at 60 Hz by BearSecondaryMotion.
/// Frequency is angular frequency (radians/second), not cycles/second.
class BearSpring {
  BearSpring({this.frequency = 13, this.damping = .85, this.limit = 1});
  final double frequency, damping, limit;
  double position = 0, velocity = 0, target = 0;

  void step(double dt) {
    final acceleration =
        frequency * frequency * (target - position) -
        2 * damping * frequency * velocity;
    velocity += acceleration * dt;
    position = (position + velocity * dt).clamp(-limit, limit);
    if ((position - target).abs() < .00001 && velocity.abs() < .0001) {
      position = target;
      velocity = 0;
    }
  }

  void reset() => position = velocity = target = 0;
}

class BearSecondaryActor {
  final head = BearSpring(frequency: 12, damping: .88, limit: .12);
  final ear = BearSpring(frequency: 16, damping: .73, limit: .12);
  final paw = BearSpring(frequency: 13, damping: .82, limit: 12);
  final compression = BearSpring(frequency: 15, damping: .9, limit: .04);
  final lean = BearSpring(frequency: 11, damping: .92, limit: .05);
  final lift = BearSpring(frequency: 14, damping: .84, limit: 10);
  BearReaction? reaction;
  double age = 10;
  bool holdingPaw = false;
  Offset? heldPaw;
  bool heldNear = true;
  double get affection =>
      reaction == null ? 0 : math.sin((age / 1.8).clamp(0, 1) * math.pi);
  bool get settled =>
      !holdingPaw &&
      age >= 1.8 &&
      [head, ear, paw, compression, lean, lift].every(
        (s) => (s.position - s.target).abs() < .0001 && s.velocity.abs() < .001,
      );

  void react(BearReaction next) {
    reaction = next;
    age = 0;
    switch (next) {
      case BearReaction.curious:
      case BearReaction.pet:
      case BearReaction.sleepy:
        head.velocity += next == BearReaction.pet ? .65 : -.4;
        ear.velocity += .65;
      case BearReaction.boop:
        head.velocity -= .6;
        compression.velocity += .22;
        ear.velocity += .9;
      case BearReaction.shy:
        head.velocity += .45;
      case BearReaction.belly:
        compression.velocity += .3;
        lean.velocity += .4;
        paw.velocity -= 35;
      case BearReaction.wave:
        paw.velocity -= 60;
        ear.velocity += .5;
      case BearReaction.pawHold:
        holdingPaw = true;
      case BearReaction.relax:
        lean.velocity -= .25;
        head.velocity += .35;
      case BearReaction.jump:
        lift.velocity += 90;
        compression.velocity -= .3;
        ear.velocity -= 1.2;
    }
  }

  void step(double dt, double authoredHead) {
    age += dt;
    head.target = holdingPaw ? .025 : 0;
    paw.target = 0;
    // The ears trail authored head movement; no perpetual oscillating force.
    ear.target = -authoredHead * .12;
    for (final s in [head, ear, paw, compression, lean, lift]) {
      s.step(dt);
    }
  }

  void reset() {
    for (final s in [head, ear, paw, compression, lean, lift]) {
      s.reset();
    }
    reaction = null;
    age = 10;
    holdingPaw = false;
    heldPaw = null;
  }
}

/// Bounded catch-up: long frames cannot create an unstable simulation spiral.
/// Lifecycle suspension clears the accumulator; elapsed background time is lost.
class BearSecondaryMotion {
  static const timestep = 1 / 60;
  static const maxSteps = 8;
  final left = BearSecondaryActor(), right = BearSecondaryActor();
  final blanket = BearSpring(frequency: 10, damping: 1, limit: 2);
  final prop = BearSpring(frequency: 12, damping: .86, limit: 4);
  double _accumulator = 0;
  int lastStepCount = 0;
  bool get settled =>
      left.settled &&
      right.settled &&
      blanket.velocity.abs() < .001 &&
      prop.velocity.abs() < .001;

  void advance(double delta, {double leftHead = 0, double rightHead = 0}) {
    lastStepCount = 0;
    if (!delta.isFinite || delta <= 0) return;
    _accumulator = math.min(_accumulator + delta, timestep * maxSteps);
    while (_accumulator + 1e-10 >= timestep && lastStepCount < maxSteps) {
      left.step(timestep, leftHead);
      right.step(timestep, rightHead);
      blanket.step(timestep);
      prop.step(timestep);
      _accumulator -= timestep;
      lastStepCount++;
    }
  }

  void suspend() {
    _accumulator = 0;
    left.holdingPaw = right.holdingPaw = false;
    left.heldPaw = right.heldPaw = null;
  }

  void reset() {
    suspend();
    left.reset();
    right.reset();
    blanket.reset();
    prop.reset();
  }
}
