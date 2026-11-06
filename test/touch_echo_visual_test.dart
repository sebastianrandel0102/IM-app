import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bear_with_me/app/theme/app_theme.dart';
import 'package:bear_with_me/features/affection/domain/affection_type.dart';
import 'package:bear_with_me/features/touch_echo/domain/touch_intent.dart';
import 'package:bear_with_me/features/touch_echo/presentation/touch_stage.dart';
import 'package:bear_with_me/features/touch_echo/presentation/touch_mode_screen.dart';
import 'package:bear_with_me/features/animation/presentation/bear_choreography.dart';
import 'package:bear_with_me/features/touch_echo/presentation/touch_playback.dart';
import 'package:bear_with_me/features/touch_echo/presentation/touch_geometry.dart';

void main() {
  testWidgets(
    'background and multi-pointer interruption cancel a hold; large text remains usable',
    (tester) async {
      final results = <TouchResult>[];
      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox(
            width: 400,
            height: 340,
            child: TouchStage(bear: BearCharacter.brown, onResult: results.add),
          ),
        ),
      );
      final rect = tester.getRect(find.byType(TouchStage));
      final scale = (rect.width / 400).clamp(0.0, rect.height / 340);
      Offset at(Offset p) =>
          rect.topLeft +
          Offset(
            (rect.width - 400 * scale) / 2,
            (rect.height - 340 * scale) / 2,
          ) +
          ((p - const Offset(200, 210)) * TouchGeometry.localZoom +
                  const Offset(200, 210)) *
              scale;
      final hold = await tester.startGesture(
        at(const Offset(227, 239)),
        pointer: 1,
      );
      await tester.pump(const Duration(milliseconds: 900));
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await hold.up(timeStamp: const Duration(milliseconds: 1000));
      await tester.pump();
      expect(results.any((r) => r.intent != null), false);
      expect(results.last.result, TouchResultKind.canceled);
      results.clear();
      final first = await tester.startGesture(
        at(const Offset(200, 135)),
        pointer: 2,
      );
      final second = await tester.startGesture(
        at(const Offset(210, 135)),
        pointer: 3,
      );
      await first.up(timeStamp: const Duration(milliseconds: 1900));
      await second.up(timeStamp: const Duration(milliseconds: 1900));
      await tester.pump();
      expect(results.any((r) => r.intent != null), false);
      await tester.pumpWidget(const SizedBox());
      SharedPreferences.setMockInitialValues({});
      tester.view.physicalSize = const Size(320, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: buildTheme(),
            builder: (c, child) => MediaQuery(
              data: MediaQuery.of(c).copyWith(textScaler: TextScaler.linear(2)),
              child: child!,
            ),
            home: const TouchModeScreen(studio: true),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.text('Touch actions'));
      expect(find.text('Touch actions'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'capture V1 contact checkpoints for every touch and both bear assignments',
    (tester) async {
      final font = FontLoader('Nunito')
        ..addFont(rootBundle.load('assets/fonts/Nunito.ttf'));
      await font.load();
      const times = [0.0, .18, .34, .50, .65, .80, .93, 1.0];
      for (final bear in BearCharacter.values) {
        final recorder = ui.PictureRecorder();
        // A single recorder owns this sheet; all cells use production painting.
        final c = Canvas(recorder)..drawColor(Palette.paper, BlendMode.src);
        for (var row = 0; row < TouchKind.values.length; row++) {
          final kind = TouchKind.values[row];
          final intent = TouchIntent(
            kind: kind,
            style: TouchStyle.gentle,
            intensity: .35,
            durationMs: 1800,
            seed: 123,
          );
          for (var col = 0; col < times.length; col++) {
            c.save();
            c.translate(col * 240.0, row * 230.0 + 24);
            TouchStagePainter(
              bear: bear,
              intent: intent,
              progress: times[col],
            ).paint(c, const Size(240, 204));
            c.restore();
            final label = TextPainter(
              text: TextSpan(
                text: '${kind.title} · ${times[col]}',
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 12,
                  color: Palette.ink,
                ),
              ),
              textDirection: TextDirection.ltr,
            )..layout();
            label.paint(c, Offset(col * 240 + 4, row * 230 + 4));
            label.dispose();
          }
        }
        final picture = recorder.endRecording();
        await tester.runAsync(() async {
          final raster = await picture.toImage(1920, 2300);
          final bytes = await raster.toByteData(format: ui.ImageByteFormat.png);
          final dir = Directory('artifacts/touch_echo')
            ..createSync(recursive: true);
          await File('${dir.path}/contacts-${bear.name}.png')
              .writeAsBytes(bytes!.buffer.asUint8List());
          raster.dispose();
        });
        picture.dispose();
      }
    },
  );
  testWidgets(
    'finger head stroke reacts before release, then offers preview and explicit send',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final icons = FontLoader('MaterialIcons')
        ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
      await icons.load();
      tester.view.resetPhysicalSize();
      tester.view.physicalSize = const Size(440, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final boundary = GlobalKey();
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: buildTheme(),
            home: RepaintBoundary(
              key: boundary,
              child: const TouchModeScreen(studio: true),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
      final box = tester.getRect(find.byType(TouchStage));
      Offset at(Offset p) =>
          box.topLeft +
          Offset((box.width - 400 * box.width / 400) / 2, 0) +
          ((p - const Offset(200, 210)) * TouchGeometry.localZoom +
                  const Offset(200, 210)) *
              (box.width / 400);
      final gesture = await tester.startGesture(at(const Offset(180, 135)));
      for (var i = 1; i <= 20; i++) {
        await gesture.moveTo(
          at(Offset(180 + 2.5 * i, 135 + .2 * i)),
          timeStamp: Duration(milliseconds: i * 50),
        );
        await tester.pump(const Duration(milliseconds: 50));
      }
      final paint = tester
          .widgetList<CustomPaint>(
            find.descendant(
              of: find.byType(TouchStage),
              matching: find.byType(CustomPaint),
            ),
          )
          .map((w) => w.painter)
          .whereType<TouchStagePainter>()
          .single;
      expect(
        paint.solo!.eyes,
        lessThan(.2),
        reason: 'Immediate eyes/head response before finger up',
      );
      expect(paint.solo!.head.abs(), greaterThan(.01));
      await gesture.up(timeStamp: const Duration(milliseconds: 1100));
      await tester.pump();
      expect(find.text('Gentle Head Pet'), findsWidgets);
      expect(find.text('Preview this touch'), findsOneWidget);
      Future<void> capture(String name) async {
        await tester.pump(const Duration(milliseconds: 100));
        final render =
            boundary.currentContext!.findRenderObject()!
                as RenderRepaintBoundary;
        await tester.runAsync(() async {
          final img = await render.toImage(pixelRatio: 1);
          final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
          final dir = Directory('artifacts/touch_echo')
            ..createSync(recursive: true);
          await File('${dir.path}/$name.png')
              .writeAsBytes(bytes!.buffer.asUint8List());
          img.dispose();
        });
      }

      await capture('touch-mode');
      await tester.ensureVisible(find.text('Preview this touch'));
      await tester.tap(find.text('Preview this touch'));
      await tester.pump();
      for (var frame = 0; frame < 36; frame++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      expect(find.text('Send This Touch'), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(
              find.ancestor(
                of: find.text('Send This Touch'),
                matching: find.byType(FilledButton),
              ),
            )
            .onPressed,
        isNull,
        reason: 'Local studio cannot simulate Firebase delivery',
      );
      await capture('preview');
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'small and large stages, reduced motion, interruption and completed replay are stable',
    (tester) async {
      for (final size in [const Size(280, 238), const Size(800, 680)]) {
        for (final reduced in [false, true]) {
          var completions = 0;
          final i = TouchIntent(
            kind: TouchKind.headPet,
            style: TouchStyle.gentle,
            intensity: .3,
            durationMs: 1800,
            seed: 123,
          );
          await tester.pumpWidget(
            MaterialApp(
              home: Center(
                child: SizedBox.fromSize(
                  size: size,
                  child: TouchStage(
                    key: UniqueKey(),
                    bear: BearCharacter.white,
                    intent: i,
                    reducedMotion: reduced,
                    onComplete: () => completions++,
                  ),
                ),
              ),
            ),
          );
          for (var f = 0; f < 70; f++) {
            await tester.pump(const Duration(milliseconds: 80));
          }
          expect(completions, 1);
          expect(tester.takeException(), isNull);
        }
      }
      final pose = TouchPlayback.sample(
        TouchIntent(
          kind: TouchKind.headPet,
          style: TouchStyle.gentle,
          intensity: .3,
          durationMs: 1800,
          seed: 1,
        ),
        1,
      );
      expect(pose.right.anchor(BearAnchor.nose).dy.isFinite, isTrue);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
