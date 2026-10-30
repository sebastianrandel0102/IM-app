import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../app/theme/app_theme.dart';
import '../../affection/domain/affection_type.dart';
import 'bear_choreography.dart';

/// Layered, editable Flutter vector rig. Geometry and palette retain the
/// original renderer. Transform scopes isolate torso, head, ears and paws.
class BearVectorRig {
  static Paint fill(Color c) => Paint()..color = c;
  static Paint ink([double width = 2.6]) => Paint()
    ..color = Palette.outline
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;
  static void shape(Canvas c, Path p, Color color, [double width = 2.6]) {
    c.drawPath(p, fill(color));
    c.drawPath(p, ink(width));
  }

  static void oval(Canvas c, Rect r, Color color, {bool outline = false}) {
    c.drawOval(r, fill(color));
    if (outline) c.drawOval(r, ink());
  }

  static Color fur(BearCharacter bear) =>
      bear == BearCharacter.brown ? Palette.caramel : const Color(0xFFFFFDFC);

  static void bodyTransform(Canvas c, BearPose p) {
    c.translate(p.root.dx, p.root.dy);
    c.rotate(p.body + p.lie);
    c.scale(p.facing / p.squash, p.squash);
    c.translate(0, p.sit * 18 / p.squash);
  }

  static void draw(Canvas c, BearPose p, BearCharacter bear, String accessory) {
    final color = fur(bear);
    c.save();
    bodyTransform(c, p);
    // Planted feet pivot at the hip. Sitting uses a rounded replacement pose.
    for (final side in [-1, 1]) {
      c.save();
      c.translate(side * 16.0, -31 + p.sit * 4);
      c.rotate(side * p.step * .035);
      oval(
        c,
        Rect.fromLTWH(-11, 0, 23 + p.sit * 7, 30 - p.sit * 10),
        color,
        outline: true,
      );
      c.restore();
    }
    shape(
      c,
      Path()
        ..moveTo(-22, -91)
        ..quadraticBezierTo(-37, -64 - p.breath, -29, -26)
        ..quadraticBezierTo(0, -13 + p.sit * 5, 30, -27)
        ..quadraticBezierTo(37, -64 - p.breath, 19, -92)
        ..close(),
      color,
    );
    c.restore();
    arm(c, p, bear, near: false);
    arm(c, p, bear);

    c.save();
    bodyTransform(c, p);
    // Undo torso squash before the rigid head transform: no stretched faces.
    c.translate(p.headX, -113 + p.headY - p.breath);
    c.scale(p.squash, 1 / p.squash);
    c.rotate(p.head);
    final inner = bear == BearCharacter.brown
        ? const Color(0xFFECC28B)
        : const Color(0xFFF4B5C4);
    for (final side in [-1, 1]) {
      c.save();
      c.translate(side == -1 ? -36.5 : 42.5, -38);
      c.rotate(side * p.ear);
      oval(c, const Rect.fromLTWH(-21.5, -24, 43, 48), color, outline: true);
      oval(c, const Rect.fromLTWH(-11.5, -14, 23, 28), inner);
      c.restore();
    }
    // Authored profile correction brings the nose to the edge of the face.
    // It changes the silhouette locally, rather than stretching the head.
    final profile = p.turn;
    shape(
      c,
      Path()
        ..moveTo(-54, -28)
        ..cubicTo(-41, -65, 37, -67, 56 - profile * 9, -27)
        ..cubicTo(73 - profile * 20, 0, 67 - profile * 12, 43, 39, 51)
        ..quadraticBezierTo(0, 66, -37, 49)
        ..cubicTo(-66, 45, -68, 1, -54, -28)
        ..close(),
      color,
      3.1,
    );
    final faceX = 9 + profile * 43;
    final blush = bear == BearCharacter.white
        ? .5 + p.blush * .3
        : p.blush * .5;
    for (final side in [-1, 1]) {
      final cheekX = (faceX + side * 31).clamp(-42.0, 48.0);
      oval(
        c,
        Rect.fromCenter(
          center: Offset(cheekX, 28),
          width: 21 * (1 - p.cheek),
          height: 18,
        ),
        Palette.pink.withValues(alpha: blush),
      );
    }
    for (final side in [-1, 1]) {
      // Hide the far eye smoothly in profile without oversized facial features.
      final visibility = side == 1 ? 1 - profile : 1.0;
      final eyeX = (faceX + side * 19 + p.gaze).clamp(-42.0, 45.0);
      if (p.eyes < .25) {
        c.drawPath(
          Path()
            ..moveTo(eyeX - 4, 14)
            ..quadraticBezierTo(eyeX, 18, eyeX + 4, 14),
          ink(2.4)..color = Palette.outline.withValues(alpha: visibility),
        );
      } else {
        oval(
          c,
          Rect.fromCenter(
            center: Offset(eyeX, 16),
            width: 6 * visibility,
            height: (9 + p.surprise * 2) * p.eyes,
          ),
          Palette.outline,
        );
      }
    }
    if (bear == BearCharacter.brown) {
      oval(
        c,
        Rect.fromCenter(
          center: Offset(faceX, 28),
          width: 21 - profile * 4,
          height: 27,
        ),
        const Color(0xFFF2D49C),
      );
    }
    c.drawPath(
      Path()
        ..moveTo(faceX - 4, 23)
        ..quadraticBezierTo(faceX, 21, faceX + 4, 23)
        ..lineTo(faceX, 27)
        ..close(),
      fill(Palette.outline),
    );
    c.drawLine(Offset(faceX, 26), Offset(faceX, 31), ink(2));
    c.drawPath(
      Path()
        ..moveTo(faceX - 7, 34 - p.smile * 2)
        ..quadraticBezierTo(faceX - 4, 34 + p.smile * 5, faceX, 32)
        ..quadraticBezierTo(
          faceX + 4,
          34 + p.smile * 5,
          faceX + 8,
          34 - p.smile * 2,
        ),
      ink(1.9),
    );
    if (accessory == 'bow') {
      c.save();
      c.translate(34, -40);
      c.rotate(p.ear * 1.4);
      for (final s in [-1, 1]) {
        shape(
          c,
          Path()
            ..moveTo(0, 0)
            ..lineTo(s * 13.0, -9)
            ..lineTo(s * 14.0, 7)
            ..close(),
          Palette.pink,
          1.4,
        );
      }
      c.drawCircle(Offset.zero, 4, fill(Palette.rose));
      c.restore();
    }
    if (accessory == 'flower') {
      for (var i = 0; i < 5; i++) {
        final a = i * math.pi * 2 / 5;
        c.drawCircle(
          Offset(35 + math.cos(a) * 4, -28 + math.sin(a) * 4),
          3,
          fill(Palette.pink),
        );
      }
      c.drawCircle(const Offset(35, -28), 2, fill(const Color(0xFFF6D798)));
    }
    c.restore();
    if (accessory == 'scarf') {
      c.save();
      bodyTransform(c, p);
      c.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(-26, -80, 53, 10),
          const Radius.circular(5),
        ),
        fill(Palette.sage),
      );
      c.save();
      c.translate(12, -76);
      c.rotate(-p.body * .7 + p.ear);
      c.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(0, 0, 10, 27),
          const Radius.circular(3),
        ),
        fill(Palette.sage),
      );
      c.restore();
      c.restore();
    }
  }

  /// Equal-length bones, bent outward, capped to 64 logical px total reach.
  /// Exposed for contact tests so a requested target cannot hide overextension.
  static Offset paw(BearPose p, {bool near = true}) {
    final shoulder = p.bodyPoint(Offset(near ? 23 : -23, -80));
    final target = near
        ? p.anchor(BearAnchor.leftPaw)
        : p.anchor(BearAnchor.rightPaw);
    final delta = target - shoulder;
    return shoulder +
        (delta.distance > 64 ? delta / delta.distance * 64 : delta);
  }

  static void arm(
    Canvas c,
    BearPose p,
    BearCharacter bear, {
    bool near = true,
    bool foreground = false,
  }) {
    c.save();
    if (foreground) {
      Offset at(double x, double y) => p.headPoint(Offset(x, y));
      final profile = p.turn;
      final head = Path()..moveTo(at(-54, -28).dx, at(-54, -28).dy);
      void cubic(
        double x1,
        double y1,
        double x2,
        double y2,
        double x3,
        double y3,
      ) {
        final a = at(x1, y1), b = at(x2, y2), d = at(x3, y3);
        head.cubicTo(a.dx, a.dy, b.dx, b.dy, d.dx, d.dy);
      }

      cubic(-41, -65, 37, -67, 56 - profile * 9, -27);
      cubic(73 - profile * 20, 0, 67 - profile * 12, 43, 39, 51);
      final q = at(0, 66), end = at(-37, 49);
      head.quadraticBezierTo(q.dx, q.dy, end.dx, end.dy);
      cubic(-66, 45, -68, 1, -54, -28);
      head.close();
      c.clipPath(
        Path()
          ..fillType = PathFillType.evenOdd
          ..addRect(const Rect.fromLTWH(-1000, -1000, 2000, 2000))
          ..addPath(head, Offset.zero),
      );
    }
    final shoulder = p.bodyPoint(Offset(near ? 23 : -23, -80));
    final target = paw(p, near: near), delta = target - shoulder;
    final distance = delta.distance.clamp(.01, 63.99);
    final perpendicular =
        Offset(-delta.dy, delta.dx) / math.max(delta.distance, .01);
    final elbow =
        (shoulder + target) / 2 +
        perpendicular *
            math.sqrt(32 * 32 - distance * distance / 4) *
            (near ? -.55 : .55) *
            p.facing;
    final path = Path()
      ..moveTo(shoulder.dx, shoulder.dy)
      ..quadraticBezierTo(elbow.dx, elbow.dy, target.dx, target.dy);
    c.drawPath(path, ink(18));
    c.drawPath(path, ink(13.4)..color = fur(bear));
    c.restore();
  }
}
