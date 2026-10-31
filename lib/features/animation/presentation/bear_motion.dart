import 'dart:math' as math;
import 'dart:ui';

/// Deterministic foundation motion: no timers, random allocations or network.
/// A varied repeating schedule makes scrubbing and visual QA reproducible.
abstract final class BearMotion {
  static const blinkIntervals = [3.73, 4.91, 3.12, 5.47, 4.18, 3.38];
  static const _blinkCycle = 24.79;
  // 10 units of stance travel occupy 62% of one cycle.
  static const strideLength = 10 / .62;

  static double smooth(double t) {
    final x = t.clamp(0.0, 1.0);
    return x * x * (3 - 2 * x);
  }

  static double _blinkAt(double elapsed) {
    if (elapsed < 0 || elapsed > .23) return 1;
    if (elapsed < .075) return 1 - smooth(elapsed / .075);
    if (elapsed < .105) return 0;
    return smooth((elapsed - .105) / .125);
  }

  static double blink(double seconds, double offset) {
    final clock = (seconds + offset) % _blinkCycle;
    var at = 0.0;
    var openness = 1.0;
    for (var i = 0; i < blinkIntervals.length; i++) {
      at += blinkIntervals[i];
      // Start the blink before the boundary so the schedule wraps continuously.
      openness = math.min(openness, _blinkAt(clock - (at - .23)));
      if (i == 1 || i == 4) {
        openness = math.min(openness, _blinkAt(clock - (at - .57)));
      }
    }
    return openness;
  }

  /// A stance moves back along the ground; a swing lifts along a short arc.
  /// The body/hip remains connected while the ankle moves independently.
  static Offset foot(double phase, int side, double weight) {
    final cycle = ((phase / (2 * math.pi) + (side < 0 ? .5 : 0)) % 1);
    final stance = cycle < .62;
    final t = stance ? cycle / .62 : (cycle - .62) / .38;
    final x = stance ? 5 - 10 * t : -5 + 10 * smooth(t);
    final y = stance ? 0.0 : -4 * math.sin(t * math.pi);
    return Offset(x, y) * weight;
  }
}
