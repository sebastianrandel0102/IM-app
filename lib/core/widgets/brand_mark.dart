import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';

class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 48});
  final double size;
  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Bear With Me',
    image: true,
    child: CustomPaint(size: Size.square(size), painter: BrandMarkPainter()),
  );
}

class BrandMarkPainter extends CustomPainter {
  @override
  void paint(Canvas c, Size size) {
    c.save();
    c.scale(size.width / 100, size.height / 100);
    c.drawRect(
      const Rect.fromLTWH(0, 0, 100, 100),
      Paint()..color = Palette.cream,
    );
    c.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(0, 0, 100, 100),
        const Radius.circular(23),
      ),
      Paint()..color = Palette.cream,
    );
    void bear(double x, double y, Color fur, bool white) {
      c.save();
      c.translate(x, y);
      final line = Paint()
        ..color = Palette.outline
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round;
      for (final dx in [-15.0, 15.0]) {
        c.drawCircle(Offset(dx, -13), 7, Paint()..color = fur);
        c.drawCircle(Offset(dx, -13), 7, line);
        c.drawCircle(
          Offset(dx, -13),
          3.6,
          Paint()..color = white ? Palette.blush : const Color(0xFFF0C98F),
        );
      }
      final head = RRect.fromRectAndRadius(
        const Rect.fromLTWH(-23, -18, 46, 42),
        const Radius.circular(20),
      );
      c.drawRRect(head, Paint()..color = fur);
      c.drawRRect(head, line);
      for (final dx in [-8.0, 8.0]) {
        c.drawOval(
          Rect.fromCenter(center: Offset(dx, 7), width: 2.8, height: 4),
          Paint()..color = Palette.outline,
        );
      }
      if (!white) {
        c.drawOval(
          const Rect.fromLTWH(-5, 8, 10, 13),
          Paint()..color = const Color(0xFFF2D49C),
        );
      }
      c.drawOval(
        const Rect.fromLTWH(-2, 10, 4, 2.6),
        Paint()..color = Palette.outline,
      );
      c.drawPath(
        Path()
          ..moveTo(0, 12)
          ..lineTo(0, 15)
          ..moveTo(-4, 15)
          ..quadraticBezierTo(-2, 19, 0, 15)
          ..quadraticBezierTo(2, 19, 4, 15),
        line..strokeWidth = 1.1,
      );
      if (white) {
        for (final dx in [-15.0, 15.0]) {
          c.drawOval(
            Rect.fromCenter(center: Offset(dx, 14), width: 7, height: 6),
            Paint()..color = Palette.blush,
          );
        }
      }
      c.restore();
    }

    bear(33, 49, Palette.caramel, false);
    bear(67, 58, Palette.paper, true);
    final heart = Path()
      ..moveTo(62, 29)
      ..cubicTo(49, 21, 56, 12, 62, 19)
      ..cubicTo(68, 12, 75, 21, 62, 29);
    c.drawPath(heart, Paint()..color = Palette.pink);
    c.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
