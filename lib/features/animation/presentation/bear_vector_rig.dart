import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../app/theme/app_theme.dart';
import '../../affection/domain/affection_type.dart';
import 'bear_artwork.dart';
import 'bear_choreography.dart';
import 'bear_motion.dart';

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

  static void draw(
    Canvas c,
    BearPose p,
    BearCharacter bear,
    String accessory, {
    bool body = true,
    bool head = true,
    bool arms = true,
  }) {
    final color = fur(bear);
    if (body) {
      c.save();
      bodyTransform(c, p);
      // Planted feet pivot at the hip. Sitting uses a rounded replacement pose.
      for (final side in [-1, 1]) {
        c.save();
        final foot = BearMotion.foot(p.gaitPhase, side, p.gaitWeight);
        c.translate(
          side * (16 + p.sit * 7.0) * (1 - p.recline) +
              (-57 + side * 13.0) * p.recline +
              foot.dx * p.gaitDirection,
          -31 + p.sit * 4 + p.recline + foot.dy,
        );
        c.rotate(side * p.step * .035);
        oval(
          c,
          Rect.fromLTWH(
            -11,
            0,
            23 + p.sit * 10 + p.recline * 8,
            30 - p.sit * 11 - p.recline * 13,
          ),
          color,
          outline: true,
        );
        c.restore();
      }
      shape(
        c,
        BearArtwork.torso(
          sit: p.sit,
          breath: p.breath,
          recline: p.recline,
          embrace: p.embrace,
        ).path,
        color,
      );
      c.restore();
    }
    if (arms) {
      arm(c, p, bear, near: false);
      arm(c, p, bear);
    }

    if (head) {
      c.save();
      bodyTransform(c, p);
      // Undo torso squash before the rigid head transform: no stretched faces.
      c.translate(p.headX, -113 + p.headY - p.breath);
      c.scale(p.squash, 1 / p.squash);
      c.translate(0, 50);
      c.rotate(p.head);
      c.translate(0, -50);
      final inner = bear == BearCharacter.brown
          ? const Color(0xFFECC28B)
          : const Color(0xFFF4B5C4);
      for (final side in [-1, 1]) {
        c.save();
        c.translate(side == -1 ? -36.5 : 42.5, -38);
        c.translate(0, 18);
        c.rotate(side * p.ear + (side == -1 ? p.leftEarBend : p.rightEarBend));
        c.translate(0, -18);
        oval(c, const Rect.fromLTWH(-21.5, -24, 43, 48), color, outline: true);
        c.restore();
      }
      // Authored profile correction brings the nose to the edge of the face.
      // It changes the silhouette locally, rather than stretching the head.
      final profile = p.turn;
      shape(c, BearArtwork.head(profile).path, color, 3.1);
      // This identifying mark sits on the readable front ear, after the head
      // contour. Facing the partner must not blindly mirror the ear marking.
      if (p.backView < .5) {
        c.save();
        final markX = 43 * p.facing;
        c.translate(markX, -39);
        c.rotate(
          p.ear * p.facing + (p.facing == 1 ? p.rightEarBend : p.leftEarBend),
        );
        final mark = BearArtwork.earMark(0, 0).path;
        c.drawPath(mark, fill(inner));
        c.drawPath(
          mark,
          ink(1.7)
            ..color = bear == BearCharacter.white
                ? const Color(0xFFFF8197)
                : const Color(0xFF92602F),
        );
        c.restore();
      }
      // A rear-facing layer is exposed during the shared orbit. The face fades
      // behind the fur without scaling or warping the original head artwork.
      if (p.backView > 0) {
        c.saveLayer(
          const Rect.fromLTWH(-70, -65, 145, 135),
          Paint()..color = Color.fromRGBO(255, 255, 255, 1 - p.backView),
        );
      }
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
            height: 21,
          ),
          Palette.pink.withValues(alpha: blush),
        );
      }
      for (final side in [-1, 1]) {
        // Hide the far eye smoothly in profile without oversized facial features.
        final visibility = side == 1 ? 1 - profile : 1.0;
        final eyeX = (faceX + side * 19 + p.gaze).clamp(-42.0, 45.0);
        final open = p.eyes.clamp(0.0, 1.0);
        final openInk = BearMotion.smooth(open / .38);
        // Continuous closure: both glyphs coexist briefly, without the old
        // artwork switch at 25% openness. Happy/sleepy arcs share the eye center.
        oval(
          c,
          Rect.fromCenter(
            center: Offset(eyeX, 16),
            width: bear == BearCharacter.white ? 7.2 : 6,
            height: .2 + (8.8 + p.surprise * 2) * open,
          ),
          Palette.outline.withValues(alpha: visibility * openInk),
        );
        c.drawPath(
          Path()
            ..moveTo(eyeX - 4, 14 + p.happyEyes * 3)
            ..quadraticBezierTo(
              eyeX,
              18 - p.happyEyes * 7,
              eyeX + 4,
              14 + p.happyEyes * 3,
            ),
          ink(2.4)
            ..color = Palette.outline.withValues(
              alpha: visibility * (1 - openInk),
            ),
        );
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
      final normalMouth = (1 - p.mouthOpen) * (1 - p.pucker);
      c.drawPath(
        (bear == BearCharacter.brown
                ? BearArtwork.brownMouth(faceX, p.smile)
                : BearArtwork.mouth(faceX, p.smile))
            .path,
        ink(1.9)..color = Palette.outline.withValues(alpha: normalMouth),
      );
      oval(
        c,
        Rect.fromCenter(
          center: Offset(faceX, 35),
          width: 6.4,
          height: 2 + p.mouthOpen * 7,
        ),
        Palette.outline.withValues(alpha: p.mouthOpen * (1 - p.pucker)),
      );
      c.drawPath(
        Path()
          ..moveTo(faceX - 2, 31)
          ..quadraticBezierTo(faceX + 7, 32, faceX + 1, 35)
          ..quadraticBezierTo(faceX + 7, 38, faceX - 2, 39),
        ink(1.9)..color = Palette.outline.withValues(alpha: p.pucker),
      );
      if (p.backView > 0) c.restore();
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
    }
    if (body && accessory == 'scarf') {
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
    final shoulder = p.anchor(
      near ? BearAnchor.shoulder : BearAnchor.rightShoulder,
    );
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
    List<BearPose> occluders = const [],
  }) {
    c.save();
    if (foreground) {
      for (final pose in [p, ...occluders]) {
        Offset at(double x, double y) => pose.headPoint(Offset(x, y));
        final profile = pose.turn;
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
    }
    final shoulder = p.anchor(
      near ? BearAnchor.shoulder : BearAnchor.rightShoulder,
    );
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
    final width = 18 + p.embrace * 4;
    c.drawPath(path, ink(width));
    c.drawPath(path, ink(width - 4.6)..color = fur(bear));
    // Distinct rounded paw cap follows the constrained endpoint.
    c.drawCircle(target, (width - 4.6) / 2, fill(fur(bear)));
    c.restore();
  }
}
