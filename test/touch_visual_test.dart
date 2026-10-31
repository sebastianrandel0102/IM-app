import 'dart:io';
import 'dart:ui' as ui;

import 'package:bear_with_me/features/affection/domain/affection_type.dart';
import 'package:bear_with_me/features/animation/presentation/bear_choreography.dart';
import 'package:bear_with_me/features/animation/presentation/bear_physics.dart';
import 'package:bear_with_me/features/animation/presentation/bear_scene.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('export actual spring-driven touch reaction sequences', (
    tester,
  ) async {
    final font = FontLoader('Nunito')
      ..addFont(rootBundle.load('assets/fonts/Nunito.ttf'));
    await font.load();
    const times = [0.0, .12, .3, .6, 1.8];
    const width = 280.0, height = 260.0;
    for (final sender in BearCharacter.values) {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder)
        ..drawColor(const Color(0xFFFFFBF5), BlendMode.src);
      for (var row = 0; row < BearReaction.values.length; row++) {
        final reaction = BearReaction.values[row];
        for (var col = 0; col < times.length; col++) {
          final action = reaction == BearReaction.sleepy
              ? AffectionType.sleepTogether
              : null;
          final p = BearPlayback(action: action);
          if (action != null) p.advance(6);
          p.react(true, reaction);
          for (var frame = 0; frame < (times[col] * 60).round(); frame++) {
            p.advance(1 / 60);
          }
          canvas.save();
          canvas.translate(col * width, row * height + 22);
          BearScenePainter(
            t: 0,
            action: action,
            sender: sender,
            theme: SceneTheme.cozyRoom,
            holding: false,
            taps: 0,
            walk: 0,
            reduced: false,
            accessory: 'none',
            variant: 'gentle',
            stopped: false,
            playback: p,
          ).paint(canvas, const Size(width, 238));
          canvas.restore();
          final label = TextPainter(
            text: TextSpan(
              text: '${reaction.name} · ${times[col]}s',
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 13,
                color: Colors.black,
              ),
            ),
            textDirection: TextDirection.ltr,
          )..layout();
          label.paint(canvas, Offset(col * width + 5, row * height + 3));
          label.dispose();
          p.dispose();
        }
      }
      final picture = recorder.endRecording();
      await tester.runAsync(() async {
        final raster = await picture.toImage(
          (width * times.length).toInt(),
          (height * BearReaction.values.length).toInt(),
        );
        final bytes = await raster.toByteData(format: ui.ImageByteFormat.png);
        final dir = Directory('artifacts/animations/physics')
          ..createSync(recursive: true);
        await File('${dir.path}/touch-${sender.name}.png')
            .writeAsBytes(bytes!.buffer.asUint8List());
        raster.dispose();
      });
      picture.dispose();
    }
  });
}
