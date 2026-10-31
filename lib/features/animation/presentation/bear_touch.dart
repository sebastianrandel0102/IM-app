import 'dart:ui';

import 'bear_choreography.dart';
import 'bear_physics.dart';
import 'bear_vector_rig.dart';

enum BearTouchZone { nose, cheek, paw, belly, head, back }

class BearTouchHit {
  const BearTouchHit(this.left, this.zone, {this.near = true});
  final bool left;
  final BearTouchZone zone;
  final bool near;
}

/// Uses the same posed coordinates as the renderer. No viewport rectangles or
/// invisible full-screen tap zones. The foreground actor wins overlaps.
abstract final class BearTouchGeometry {
  static Offset? scenePoint(Offset local, Size size) {
    if (size.isEmpty) return null;
    final scale = (size.width / 400).clamp(0.0, size.height / 340);
    if (scale <= 0) return null;
    final point =
        (local -
            Offset(
              (size.width - 400 * scale) / 2,
              (size.height - 340 * scale) / 2,
            )) /
        scale;
    return const Rect.fromLTWH(0, 0, 400, 340).contains(point) ? point : null;
  }

  static bool _ellipse(Offset point, Offset center, double x, double y) {
    final d = point - center;
    return d.dx * d.dx / (x * x) + d.dy * d.dy / (y * y) <= 1;
  }

  static BearTouchHit? hit(BearFrame frame, Offset point) {
    for (final (p, left) in [(frame.right, false), (frame.left, true)]) {
      if (p.backView < .5) {
        if (_ellipse(point, p.anchor(BearAnchor.nose), 9, 8)) {
          return BearTouchHit(left, BearTouchZone.nose);
        }
        for (final a in [BearAnchor.leftCheek, BearAnchor.rightCheek]) {
          if (_ellipse(point, p.anchor(a), 13, 12)) {
            return BearTouchHit(left, BearTouchZone.cheek);
          }
        }
      }
      for (final near in [true, false]) {
        if (_ellipse(point, BearVectorRig.paw(p, near: near), 11, 11)) {
          return BearTouchHit(left, BearTouchZone.paw, near: near);
        }
      }
      if (_ellipse(point, p.anchor(BearAnchor.torso), 24, 23)) {
        return BearTouchHit(left, BearTouchZone.belly);
      }
      // Evaluate in head-local space, including head tilt and facing.
      final origin = p.headPoint(Offset.zero);
      final xAxis = p.headPoint(const Offset(1, 0)) - origin;
      final yAxis = p.headPoint(const Offset(0, 1)) - origin;
      final d = point - origin;
      final local = Offset(
        d.dx * xAxis.dx + d.dy * xAxis.dy,
        d.dx * yAxis.dx + d.dy * yAxis.dy,
      );
      if (_ellipse(local, Offset.zero, 61, 54)) {
        return BearTouchHit(left, BearTouchZone.head);
      }
      if (_ellipse(point, p.bodyPoint(const Offset(-34, -47)), 10, 20)) {
        return BearTouchHit(left, BearTouchZone.back);
      }
    }
    return null;
  }
}

/// A stroke must stay on the same actor and cover a meaningful distance.
/// Flutter's gesture arena separates taps, double taps, holds and drags.
class BearStroke {
  BearStroke(this.hit, this.last);
  final BearTouchHit hit;
  Offset last;
  double distance = 0;
  bool fired = false;
  BearReaction? move(BearTouchHit? next, Offset point) {
    if (fired) return null;
    if (next == null ||
        next.left != hit.left ||
        next.zone != hit.zone ||
        (point - last).distance > 45) {
      fired = true;
      return null;
    }
    distance += (point - last).distance;
    last = point;
    if (distance < 14) return null;
    fired = true;
    return switch (hit.zone) {
      BearTouchZone.head => BearReaction.pet,
      BearTouchZone.belly => BearReaction.belly,
      BearTouchZone.back => BearReaction.relax,
      _ => null,
    };
  }
}
