import 'dart:io';
import 'dart:ui' as ui;

import 'package:bear_with_me/features/affection/domain/affection_type.dart';
import 'package:bear_with_me/features/animation/presentation/bear_scene.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

// Real Flutter raster output, grouped so every gesture and both color roles can
// be inspected at anticipation, approach, contact, reaction and recovery.
void main() {
  testWidgets('export all gesture timelines for visual inspection', (
    tester,
  ) async {
    final font = FontLoader('Nunito')
      ..addFont(rootBundle.load('assets/fonts/Nunito.ttf'));
    await font.load();
    const pass = String.fromEnvironment(
      'ANIMATION_PASS',
      defaultValue: 'refined',
    );
    const times = [.04, .22, .40, .54, .72, .96];
    for (final category in [
      'Everyday',
      'Playful',
      'Cozy',
      'Comfort',
      'Surprises',
    ]) {
      final gestures = AffectionType.values
          .where((g) => g.category == category)
          .toList();
      for (final sender in BearCharacter.values) {
        final recorder = ui.PictureRecorder();
        final canvas = Canvas(recorder);
        canvas.drawColor(const Color(0xFFFFFBF5), BlendMode.src);
        for (var row = 0; row < gestures.length; row++) {
          for (var col = 0; col < times.length; col++) {
            canvas.save();
            canvas.translate(col * 200.0, row * 192.0 + 22);
            BearScenePainter(
              t: times[col],
              action: gestures[row],
              sender: sender,
              theme: SceneTheme.cozyRoom,
              holding: false,
              taps: 0,
              walk: 0,
              reduced: false,
              accessory: 'none',
              variant: 'gentle',
              stopped: false,
            ).paint(canvas, const Size(200, 170));
            canvas.restore();
            final label = TextPainter(
              text: TextSpan(
                text: '${gestures[row].title}  ${times[col]}',
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 12,
                  color: Colors.black,
                ),
              ),
              textDirection: TextDirection.ltr,
            )..layout(maxWidth: 198);
            label.paint(canvas, Offset(col * 200.0 + 4, row * 192.0 + 3));
            label.dispose();
          }
        }
        final picture = recorder.endRecording();
        await tester.runAsync(() async {
          final raster = await picture.toImage(1200, gestures.length * 192);
          final bytes = await raster.toByteData(format: ui.ImageByteFormat.png);
          final dir = Directory('artifacts/animations/$pass');
          await dir.create(recursive: true);
          await File('${dir.path}/${category.toLowerCase()}-${sender.name}.png')
              .writeAsBytes(bytes!.buffer.asUint8List());
          raster.dispose();
        });
        picture.dispose();
      }
    }
  });
}
