import 'dart:math' as math;
import 'dart:ui';

import 'touch_intent.dart';

class TouchSample {
  const TouchSample(this.point, this.time);
  final Offset point; // Stage coordinates / 100, independent of DPI and layout.
  final Duration time;
}

class TouchPathSummary {
  TouchPathSummary(List<TouchSample> samples) {
    durationMs = (samples.last.time - samples.first.time).inMilliseconds;
    displacement = samples.last.point - samples.first.point;
    var previous = Offset.zero;
    for (var i = 1; i < samples.length; i++) {
      final d = samples[i].point - samples[i - 1].point;
      length += d.distance;
      if (d.distance < .015) continue; // Tremor is not a direction reversal.
      if (previous.distance > .015) {
        final dot = d.dx * previous.dx + d.dy * previous.dy;
        if (dot / (d.distance * previous.distance) < -.45) reversals++;
        curvature += math.atan2(previous.dx * d.dy - previous.dy * d.dx, dot);
      }
      previous = d;
    }
    coherence = length == 0 ? 0 : displacement.distance / length;
    speed = length / math.max(.001, durationMs / 1000);
  }
  late final int durationMs;
  late final Offset displacement;
  late final double coherence, speed;
  double length = 0, curvature = 0;
  int reversals = 0;
}

abstract final class TouchClassifier {
  static TouchResult classify(
    List<TouchSample> samples,
    TouchZone zone, {
    bool heartMode = false,
    double sensitivity = 1,
    int repetitions = 1,
  }) {
    if (samples.length < 2 ||
        samples.length > 2048 ||
        samples.any((s) => !s.point.dx.isFinite || !s.point.dy.isFinite)) {
      return const TouchResult(TouchResultKind.invalid);
    }
    for (var i = 1; i < samples.length; i++) {
      if (samples[i].time < samples[i - 1].time ||
          (samples[i].point - samples[i - 1].point).distance > .65) {
        return const TouchResult(TouchResultKind.invalid);
      }
    }
    final m = TouchPathSummary(samples);
    if (m.durationMs < 30 ||
        m.durationMs > 10000 ||
        m.speed > 3.8 ||
        m.length > 12) {
      return const TouchResult(
        TouchResultKind.invalid,
        message: 'Try a slower, smaller touch.',
      );
    }
    final threshold = .20 / sensitivity.clamp(.7, 1.4);
    final stroke =
        m.length >= threshold && m.coherence > .55 && m.durationMs >= 250;
    final still = m.length < .14;
    TouchKind? kind;
    if (heartMode) {
      if (_heart(samples) && m.durationMs >= 500) kind = TouchKind.heartTrace;
    } else {
      kind = switch (zone) {
        TouchZone.head when stroke && m.speed < 1.8 => TouchKind.headPet,
        TouchZone.nose when still && m.durationMs <= 350 => TouchKind.noseBoop,
        TouchZone.cheek when stroke && m.speed < 1.8 => TouchKind.cheekCaress,
        TouchZone.paw when still && m.durationMs >= 650 => TouchKind.pawHold,
        TouchZone.chest when still && m.durationMs >= 800 => TouchKind.hugHold,
        TouchZone.back when stroke && m.durationMs >= 450 && m.speed < 1.2 =>
          TouchKind.backComfort,
        TouchZone.ear
            when m.length > .17 &&
                m.length < 2 &&
                m.durationMs >= 300 &&
                m.reversals >= 1 =>
          TouchKind.earRub,
        TouchZone.belly when _circle(samples, m) => TouchKind.bellyRub,
        TouchZone.belly
            when m.reversals >= 3 &&
                m.length > .35 &&
                m.durationMs >= 250 &&
                m.durationMs <= 2200 =>
          TouchKind.tinyTickle,
        _ => null,
      };
    }
    if (kind == null) {
      return const TouchResult(
        TouchResultKind.ambiguous,
        message:
            'A little unclear. Try the touch once more, or use Touch actions.',
      );
    }
    final intensity = (.22 + m.speed * .16 + m.reversals * .025).clamp(
      .15,
      .85,
    );
    final style = intensity < .4
        ? TouchStyle.gentle
        : intensity < .65
        ? TouchStyle.normal
        : TouchStyle.playful;
    return TouchResult(
      TouchResultKind.recognized,
      intent: TouchIntent(
        kind: kind,
        style: style,
        intensity: intensity,
        durationMs: m.durationMs.clamp(350, 6000),
        seed: samples.fold<int>(
          17,
          (s, p) =>
              (s * 31 +
                  (p.point.dx * 100).round() +
                  (p.point.dy * 100).round()) &
              0x7fffffff,
        ),
        direction: m.displacement.dx.abs() > m.displacement.dy.abs()
            ? m.displacement.dx.sign
            : m.displacement.dy.sign,
        repetitions: repetitions,
      ),
    );
  }

  static bool _circle(List<TouchSample> s, TouchPathSummary m) {
    if (m.length < .6 ||
        m.durationMs < 350 ||
        m.curvature.abs() < 4.4 ||
        (s.last.point - s.first.point).distance > .2) {
      return false;
    }
    final xs = s.map((e) => e.point.dx), ys = s.map((e) => e.point.dy);
    final w = xs.reduce(math.max) - xs.reduce(math.min),
        h = ys.reduce(math.max) - ys.reduce(math.min);
    final center = Offset(
      (xs.reduce(math.max) + xs.reduce(math.min)) / 2,
      (ys.reduce(math.max) + ys.reduce(math.min)) / 2,
    );
    final radii = s.map((e) => (e.point - center).distanceSquared);
    // A closed heart or inward scribble also winds once. Its notch approaches
    // the center, unlike a circle; preserve ambiguity outside explicit heart mode.
    final round = radii.reduce(math.min) > .23 * radii.reduce(math.max);
    return w > .13 && h > .13 && w / h > .4 && w / h < 2.5 && round;
  }

  /// Explicit drawing mode only; compares both directions against an authored
  /// heart contour after normalizing the drawing's bounds, never handwriting.
  static bool _heart(List<TouchSample> s) {
    if (s.length < 16 || (s.last.point - s.first.point).distance > .25) {
      return false;
    }
    final xs = s.map((e) => e.point.dx), ys = s.map((e) => e.point.dy);
    final minX = xs.reduce(math.min), minY = ys.reduce(math.min);
    final w = xs.reduce(math.max) - minX, h = ys.reduce(math.max) - minY;
    if (w < .4 || h < .4 || w / h < .6 || w / h > 1.7) return false;
    final points = s
        .map((e) => Offset((e.point.dx - minX) / w, (e.point.dy - minY) / h))
        .toList();
    final raw = List.generate(48, (i) {
      final t = i / 47 * 2 * math.pi;
      return Offset(
        16 * math.pow(math.sin(t), 3).toDouble(),
        -(13 * math.cos(t) -
            5 * math.cos(2 * t) -
            2 * math.cos(3 * t) -
            math.cos(4 * t)),
      );
    });
    final y0 = raw.map((e) => e.dy).reduce(math.min),
        y1 = raw.map((e) => e.dy).reduce(math.max);
    final template = raw
        .map((e) => Offset((e.dx + 16) / 32, (e.dy - y0) / (y1 - y0)))
        .toList();
    double error(List<Offset> a, List<Offset> b) =>
        a
            .map((p) => b.map((q) => (p - q).distance).reduce(math.min))
            .reduce((a, b) => a + b) /
        a.length;
    return error(points, template) < .085 &&
        error(template, points) < .10 &&
        TouchPathSummary(s).length / math.max(w, h) < 4.8;
  }
}
