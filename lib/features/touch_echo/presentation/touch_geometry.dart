import 'dart:ui';

import '../../animation/presentation/bear_choreography.dart';
import '../../animation/presentation/bear_vector_rig.dart';
import '../domain/touch_intent.dart';

abstract final class TouchGeometry {
  static const localZoom = 1.2;
  static const stage = Size(400, 340);
  static Offset? scenePoint(Offset local, Size size, {double zoom = 1}) {
    if (size.isEmpty) return null;
    final scale = (size.width / 400).clamp(0.0, size.height / 340);
    if (scale <= 0) return null;
    final p =
        (local -
            Offset(
              (size.width - 400 * scale) / 2,
              (size.height - 340 * scale) / 2,
            )) /
        scale;
    return (Offset.zero & stage).contains(p)
        ? (p - const Offset(200, 210)) / zoom + const Offset(200, 210)
        : null;
  }

  static bool ellipse(Offset p, Offset center, double rx, double ry) {
    final d = p - center;
    return d.dx * d.dx / (rx * rx) + d.dy * d.dy / (ry * ry) <= 1;
  }

  static Offset headLocal(BearPose pose, Offset point) {
    final origin = pose.headPoint(Offset.zero),
        x = pose.headPoint(const Offset(1, 0)) - origin,
        y = pose.headPoint(const Offset(0, 1)) - origin,
        d = point - origin;
    return Offset(d.dx * x.dx + d.dy * x.dy, d.dx * y.dx + d.dy * y.dy);
  }

  static TouchZone? hit(BearPose p, Offset point) {
    final h = headLocal(p, point);
    if (ellipse(h, headLocal(p, p.anchor(BearAnchor.leftEar)), 21, 19) ||
        ellipse(h, headLocal(p, p.anchor(BearAnchor.rightEar)), 21, 19)) {
      return TouchZone.ear;
    }
    if (ellipse(point, p.anchor(BearAnchor.nose), 10, 10)) {
      return TouchZone.nose;
    }
    for (final a in [BearAnchor.leftCheek, BearAnchor.rightCheek]) {
      if (ellipse(point, p.anchor(a), 14, 13)) return TouchZone.cheek;
    }
    for (final near in [true, false]) {
      if (ellipse(point, BearVectorRig.paw(p, near: near), 13, 13)) {
        return TouchZone.paw;
      }
    }
    if (ellipse(h, const Offset(0, -10), 61, 48)) return TouchZone.head;
    if (ellipse(point, p.bodyPoint(const Offset(-32, -52)), 12, 21)) {
      return TouchZone.back;
    }
    if (ellipse(point, p.anchor(BearAnchor.chest), 18, 12)) {
      return TouchZone.chest;
    }
    if (ellipse(point, p.anchor(BearAnchor.belly), 24, 17)) {
      return TouchZone.belly;
    }
    return null;
  }

  static bool contains(BearPose pose, Offset point) =>
      ellipse(headLocal(pose, point), const Offset(0, -10), 78, 76) ||
      ellipse(point, pose.bodyPoint(const Offset(0, -40)), 57, 56);
}
