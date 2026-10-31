import 'dart:io';
import 'dart:ui' as ui;

import 'package:bear_with_me/features/affection/domain/affection_type.dart';
import 'package:bear_with_me/features/animation/presentation/bear_choreography.dart';
import 'package:bear_with_me/features/animation/presentation/bear_scene.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'export first contact, hold, release, orbit and independent controls',
    (tester) async {
      final font = FontLoader('Nunito')
        ..addFont(rootBundle.load('assets/fonts/Nunito.ttf'));
      await font.load();
      const pass = String.fromEnvironment(
        'ANIMATION_PASS',
        defaultValue: 'contact-rig',
      );
      const dir = 'artifacts/animations/$pass';
      Directory(dir).createSync(recursive: true);
      Future<void> sheet(
        String name,
        List<(AffectionType, double, BearInteractionInput)> poses,
        BearCharacter sender, {
        bool reduced = false,
      }) async {
        const cols = 5, width = 280.0, height = 260.0;
        final rows = (poses.length / cols).ceil();
        final recorder = ui.PictureRecorder();
        // Each sheet records its own scene surfaces; no Firebase or wall clock.
        final c = Canvas(recorder);
        c.drawColor(const Color(0xFFFFFBF5), BlendMode.src);
        for (var i = 0; i < poses.length; i++) {
          final (action, t, interaction) = poses[i];
          final p = BearPlayback(action: action, reduced: reduced)
            ..progress = t
            ..seconds =
                t *
                BearChoreography.duration(action, 'gentle').inMilliseconds /
                1000
            ..interaction = interaction;
          c.save();
          c.translate(i % cols * width, i ~/ cols * height + 22);
          BearScenePainter(
            t: t,
            action: action,
            sender: sender,
            theme: SceneTheme.cozyRoom,
            holding: false,
            taps: 0,
            walk: 0,
            reduced: reduced,
            accessory: 'none',
            variant: 'gentle',
            stopped: false,
            playback: p,
          ).paint(c, const Size(width, 238));
          c.restore();
          final label = TextPainter(
            text: TextSpan(
              text: '${action.title} · $t',
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 13,
                color: Colors.black,
              ),
            ),
            textDirection: TextDirection.ltr,
          )..layout();
          label.paint(c, Offset(i % cols * width + 4, i ~/ cols * height + 3));
          label.dispose();
          p.dispose();
        }
        final picture = recorder.endRecording();
        await tester.runAsync(() async {
          final raster = await picture.toImage(
            (width * cols).toInt(),
            (height * rows).toInt(),
          );
          final bytes = await raster.toByteData(format: ui.ImageByteFormat.png);
          await File('$dir/$name.png')
              .writeAsBytes(bytes!.buffer.asUint8List());
          raster.dispose();
        });
        picture.dispose();
      }

      for (final sender in BearCharacter.values) {
        for (final reduced in [false, true]) {
          await sheet(
            'contact-${sender.name}${reduced ? '-reduced' : ''}',
            [
              for (final action in [
                AffectionType.warmHug,
                AffectionType.comfortHug,
                AffectionType.spinningHug,
                AffectionType.cuddleTime,
                AffectionType.sleepTogether,
                AffectionType.goodnightKiss,
              ])
                for (final t in [.43, .46, .64, .84, .94])
                  (action, t, const BearInteractionInput()),
            ],
            sender,
            reduced: reduced,
          );
        }
        await sheet('orbit-controls-${sender.name}', [
          for (final t in [.55, .59, .64, .69, .73])
            (AffectionType.spinningHug, t, const BearInteractionInput()),
          (
            AffectionType.cuddleTime,
            .64,
            const BearInteractionInput(blanket: 1),
          ),
          (AffectionType.cuddleTime, .64, const BearInteractionInput(lamp: 1)),
          (
            AffectionType.cuddleTime,
            .64,
            const BearInteractionInput(closer: 1),
          ),
          (AffectionType.comfortHug, .64, const BearInteractionInput(pat: 1)),
          (
            AffectionType.sleepTogether,
            .64,
            const BearInteractionInput(closer: 1, hands: 1),
          ),
        ], sender);
      }
    },
  );
}
