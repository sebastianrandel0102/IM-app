import 'dart:io';
import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bear_with_me/core/widgets/brand_mark.dart';

void main() {
  test('render original vector brand mark into platform icons', () async {
    Future<void> export(String path, int size) async {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      BrandMarkPainter().paint(canvas, Size.square(size.toDouble()));
      final picture = recorder.endRecording();
      final image = await picture.toImage(size, size);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await File(path).writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
      picture.dispose();
    }

    for (final spec in [
      ('mdpi', 48),
      ('hdpi', 72),
      ('xhdpi', 96),
      ('xxhdpi', 144),
      ('xxxhdpi', 192),
    ]) {
      await export(
        'android/app/src/main/res/mipmap-${spec.$1}/ic_launcher.png',
        spec.$2,
      );
    }
    for (final size in [192, 512]) {
      await export('web/icons/Icon-$size.png', size);
      await export('web/icons/Icon-maskable-$size.png', size);
    }
    await export('web/favicon.png', 32);
    final directory = 'ios/Runner/Assets.xcassets/AppIcon.appiconset';
    final contents = jsonDecode(
      await File('$directory/Contents.json').readAsString(),
    ) as Map<String, dynamic>;
    for (final spec in contents['images'] as List) {
      if (spec['filename'] == null) continue;
      final points = double.parse((spec['size'] as String).split('x').first);
      final scale = double.parse((spec['scale'] as String).replaceAll('x', ''));
      await export('$directory/${spec['filename']}', (points * scale).round());
    }
  });
}
